import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/repository/account_data_repository.dart';
import '../data/stripe/stripe_client.dart';
import '../data/tip_channel.dart';
import '../data/tip_source.dart';
import '../domain/live_session.dart';
import '../domain/tip.dart';
import 'session_coordinator.dart';

/// A signed-in account's session, coordinated across devices through
/// Firestore.
///
/// The shape:
///
/// * `users/{uid}/live/current` — the coordination doc. Fixed path, so one
///   active session per ACCOUNT is structural: two "Go live" taps contend on
///   the same doc and the transaction lets exactly one through. It carries
///   the session's identity, the goal, and the leader lease.
/// * `users/{uid}/bands/{bandId}/sessions/{sessionId}/tips/{tipId}` — the
///   live tips, doc id = tip id (Stripe/relay ids are stable), so any number
///   of writers stay idempotent.
/// * `…/sessions/{sessionId}` — written as a skeleton at start and finalized
///   with the full [LiveSession.toJson] on stop. The finalized doc IS the
///   archive entry the history mirror reads — stop must NOT also append via
///   the repository, or the night would be archived twice.
///
/// One device — the leader — runs the Stripe poll and the relay channel and
/// writes every fresh tip to the tips subcollection. EVERY device (the
/// leader included) ingests from the subcollection listener only: one code
/// path, identical ordering everywhere. The leader's own tips come back
/// through Firestore's latency-compensated local echo, so nothing is
/// delayed, and dedupe by tip id makes the echo safe.
///
/// The lease: the leader stamps `leaderLeaseUntilMs = now + 45s` on every
/// poll tick. A follower that watches the lease go stale by more than two
/// minutes may take leadership over (transaction again) — but only when it
/// has the band's Stripe key to poll with. A zombie leader returning from a
/// long sleep keeps polling harmlessly: its tip writes are idempotent and
/// its stop still flips the same doc.
class CloudSessionCoordinator implements SessionCoordinator {
  CloudSessionCoordinator({
    required FirebaseFirestore db,
    required String uid,
    required String bandId,
    required String deviceId,
    required AccountDataRepository repository,
    required TipSource source,
    required TipChannel? relay,
    required bool canLead,
    required int pollIntervalSec,
    required SessionEvents events,
  })  : _db = db,
        _uid = uid,
        _bandId = bandId,
        _deviceId = deviceId,
        _repo = repository,
        _source = source,
        _relay = relay,
        _canLead = canLead,
        _pollIntervalSec = pollIntervalSec,
        _events = events;

  /// How long a leader's claim stays presumed-alive past its last heartbeat.
  static const leaseMs = 45 * 1000;

  /// How long past the lease a leader must stay silent before a follower may
  /// conclude it is gone — generous, because a suspended app that wakes up
  /// mid-set should find its leadership where it left it.
  static const staleMs = 2 * 60 * 1000;

  final FirebaseFirestore _db;
  final String _uid;
  final String _bandId;
  final String _deviceId;
  final AccountDataRepository _repo;
  final TipSource _source;
  final TipChannel? _relay;
  final bool _canLead;
  final int _pollIntervalSec;
  final SessionEvents _events;

  String _sessionId = '';
  bool _isLeader = false;
  bool _disposed = false;
  bool _stopping = false;
  bool _takingOver = false;
  bool _polling = false;
  int _skipTicks = 0;
  int _lastLeaseUntilMs = 0;
  LiveSession? _session;

  Timer? _timer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tipsSub;
  StreamSubscription<Tip>? _relayTipsSub;
  StreamSubscription<RelayHealth>? _relayStatusSub;

  static int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  DocumentReference<Map<String, dynamic>> get _liveDoc =>
      _db.doc('users/$_uid/live/current');
  DocumentReference<Map<String, dynamic>> get _sessionDoc =>
      _db.doc('users/$_uid/bands/$_bandId/sessions/$_sessionId');
  CollectionReference<Map<String, dynamic>> get _tipsCol =>
      _sessionDoc.collection('tips');

  // The relay pill appears once leadership is settled (see [_startLeading]);
  // a follower runs no relay channel and shows no second pill.
  @override
  RelayHealth? get relayHealthSeed => null;

  @override
  Future<void> start(
    LiveSession session, {
    String? resumeCursor,
    SessionStartMode mode = SessionStartMode.fresh,
  }) async {
    _session = session;
    _sessionId = session.id;

    if (mode == SessionStartMode.join) {
      // A follower by definition — the doc already names a leader.
      _isLeader = false;
    } else {
      await _claim(session, mode);
    }

    // The crash snapshot works exactly like the local profile's: this
    // device's in-flight copy of the set, safe across a crash or restart.
    await _repo.saveActiveSession(_bandId, session, resumeCursor);

    // Every device ingests from the tips listener — the leader's own polls
    // come back through it too (latency-compensated, so not delayed).
    _tipsSub = _tipsCol
        .orderBy('createdAt')
        .snapshots()
        .listen(_onTipsSnapshot, onError: _ignore);
    _docSub = _liveDoc.snapshots().listen(_onLiveDoc, onError: _ignore);

    if (_isLeader) {
      await _startLeading(session,
          resumeCursor: resumeCursor,
          backfill: mode == SessionStartMode.resume);
    } else {
      // Followers keep an eye on the lease even when the doc goes quiet —
      // a dead leader stops writing, so staleness needs its own clock.
      final seconds = _pollIntervalSec.clamp(2, 60);
      _timer = Timer.periodic(
          Duration(seconds: seconds), (_) => _maybeTakeOver());
    }
  }

  /// The start/resume transaction on `live/current`: exactly one device gets
  /// to install (or reclaim) a session; everyone else learns why not.
  Future<void> _claim(LiveSession session, SessionStartMode mode) async {
    final superseded = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(_liveDoc);
      final data = snap.data();
      final now = _nowMs;
      final active = data?['active'] == true;
      final docSessionId = data?['sessionId'] as String?;
      final leaseUntil = (data?['leaderLeaseUntilMs'] as num?)?.toInt() ?? 0;
      final leaseFresh = leaseUntil > now - staleMs;

      if (active && docSessionId == session.id) {
        // Resuming the account's still-running session. Reclaim leadership
        // when the lease is ours or stale; otherwise re-attach as follower
        // under whoever leads now.
        if (data?['leaderDeviceId'] == _deviceId || !leaseFresh) {
          tx.update(_liveDoc, {
            'leaderDeviceId': _deviceId,
            'leaderLeaseUntilMs': now + leaseMs,
          });
          _isLeader = true;
        } else {
          _isLeader = false;
        }
        return false;
      }

      if (active && leaseFresh) {
        // Someone else's session, alive and led — the UI shows the Join
        // banner instead.
        throw SessionAlreadyActiveException(
            data?['bandId'] as String? ?? _bandId);
      }

      if (mode == SessionStartMode.resume) {
        // Our snapshot's session is no longer the account's active one —
        // stopped (and archived) elsewhere while this device was away.
        return true;
      }

      // Fresh start — or a takeover of a doc whose lease went stale long
      // ago (an abandoned session; its device reconciles at its next
      // resume and finds itself superseded).
      tx.set(_liveDoc, {
        'active': true,
        'bandId': _bandId,
        'sessionId': session.id,
        'startedAtMs': session.startedAt.millisecondsSinceEpoch,
        'currency': session.currency,
        'goalMinor': session.goalMinor,
        'goalUpdatedAtMs': now,
        'leaderDeviceId': _deviceId,
        'leaderLeaseUntilMs': now + leaseMs,
      });
      _isLeader = true;
      return false;
    });

    if (superseded) {
      // Salvage before surrendering: if nobody finalized this session's
      // archive doc (a stale-lease takeover buried it without a stop — the
      // skeleton has no endedAt), the snapshot is the only copy of the set,
      // so finalize with it. A stopping device's finalized doc must stay
      // untouched: it assembled the full set there.
      try {
        final doc = await _sessionDoc.get();
        if (doc.data()?['endedAt'] == null) {
          session.endedAt ??= DateTime.now();
          await _sessionDoc
              .set({...session.toJson(), 'updatedAtMs': _nowMs});
        }
      } catch (e) {
        debugPrint('cloud session: superseded-archive failed: $e');
      }
      await _repo.clearActiveSession(_bandId);
      throw const SessionSupersededException();
    }

    if (mode == SessionStartMode.fresh) {
      // The session's own doc, as a skeleton — finalized with the full set
      // on stop. Fire-and-forget: Firestore queues it durably.
      unawaited(_sessionDoc
          .set({...session.toJson(), 'updatedAtMs': _nowMs})
          .catchError(_ignore));
    }
  }

  /// Brings the leader transports up: the relay channel, the Stripe poll,
  /// and the heartbeat that rides on it.
  Future<void> _startLeading(
    LiveSession session, {
    String? resumeCursor,
    required bool backfill,
  }) async {
    _timer?.cancel();
    final relay = _relay;
    if (relay != null) {
      // Subscribe BEFORE start(): broadcast streams don't replay. Relay
      // tips are published, not ingested — the listener echoes them back.
      _events.onRelayHealth(RelayHealth.connecting);
      _relayTipsSub = relay.tips.listen((tip) => _publish([tip]));
      _relayStatusSub = relay.status.listen(_events.onRelayHealth);
      relay.start();
    }
    try {
      await _source.prime(session.startedAt,
          resumeCursor: resumeCursor, backfill: backfill);
      _events.onPollOk();
    } catch (e) {
      if (!_disposed) _events.onPollError(e);
    }
    if (_disposed) return;
    final seconds = _pollIntervalSec.clamp(2, 60);
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => _tick());
    unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_polling || _disposed) return;
    if (_skipTicks > 0) {
      _skipTicks--;
      return;
    }
    _polling = true;
    // Heartbeat first — a failing Stripe poll must still keep the lease, or
    // an outage would hand leadership around for no one's benefit.
    unawaited(_liveDoc
        .set({'leaderLeaseUntilMs': _nowMs + leaseMs}, SetOptions(merge: true))
        .catchError(_ignore));
    try {
      final fresh = await _source.pollNew();
      if (_disposed) return;
      _events.onPollOk();
      _publish(fresh);
    } catch (e) {
      if (e is StripeApiException && e.isRateLimited) _skipTicks = 3;
      if (!_disposed) _events.onPollError(e);
    } finally {
      _polling = false;
    }
  }

  /// Writes fresh tips to the tips subcollection — doc id = tip id, so
  /// redeliveries and racing writers overwrite instead of duplicating.
  /// Fire-and-forget: Firestore queues durably, and the local echo delivers
  /// to our own listener immediately.
  void _publish(List<Tip> fresh) {
    if (fresh.isEmpty || _disposed) return;
    final now = _nowMs;
    final batch = _db.batch();
    for (final tip in fresh) {
      batch.set(_tipsCol.doc(tip.id), {...tip.toJson(), 'updatedAtMs': now});
    }
    unawaited(batch.commit().catchError(_ignore));
  }

  void _onTipsSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    if (_disposed) return;
    final fresh = <Tip>[];
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final tip = _decodeTip(change.doc.data());
      if (tip != null) fresh.add(tip);
    }
    // The listener flowing IS the follower's feed health; the leader's
    // health belongs to its Stripe poll.
    if (!_isLeader) _events.onPollOk();
    if (fresh.isNotEmpty) _events.onTips(fresh);
  }

  void _onLiveDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (_disposed || _stopping) return;
    final data = snap.data();
    if (data == null) return;
    _lastLeaseUntilMs = (data['leaderLeaseUntilMs'] as num?)?.toInt() ?? 0;

    if (data['active'] != true || data['sessionId'] != _sessionId) {
      // Stopped on another device (or replaced after a stale takeover) —
      // this device's copy of the set is over. The stopping device owns the
      // archive; here only the snapshot goes.
      _teardown();
      unawaited(_repo.clearActiveSession(_bandId));
      _events.onRemoteEnded();
      return;
    }

    // Goal edits are last-write-wins through the doc; the controller
    // ignores echoes of its own value. Rollovers recompute locally — they
    // are deterministic from tips + goal.
    final goal = (data['goalMinor'] as num?)?.toInt() ?? 0;
    if (goal > 0) _events.onRemoteGoal(goal);

    // Event-driven staleness check on top of the follower timer: a doc
    // update that reveals a long-dead lease shouldn't wait for the tick.
    _maybeTakeOver();
  }

  /// Follower-side: claims leadership when the lease has been stale for
  /// [staleMs] — but only with a Stripe key to poll with; a key-less device
  /// (someone's tablet on the merch table) stays a follower forever.
  void _maybeTakeOver() {
    if (_disposed || _isLeader || _takingOver || !_canLead) return;
    if (_lastLeaseUntilMs <= 0) return; // doc not seen yet
    if (_lastLeaseUntilMs > _nowMs - staleMs) return; // leader alive enough
    _takingOver = true;
    unawaited(() async {
      try {
        final won = await _db.runTransaction<bool>((tx) async {
          final snap = await tx.get(_liveDoc);
          final data = snap.data();
          if (data == null ||
              data['active'] != true ||
              data['sessionId'] != _sessionId) {
            return false;
          }
          final leaseUntil =
              (data['leaderLeaseUntilMs'] as num?)?.toInt() ?? 0;
          if (leaseUntil > _nowMs - staleMs) return false; // it came back
          tx.update(_liveDoc, {
            'leaderDeviceId': _deviceId,
            'leaderLeaseUntilMs': _nowMs + leaseMs,
          });
          return true;
        });
        final session = _session;
        if (won && !_disposed && session != null) {
          _isLeader = true;
          // Backfill the whole session window: the old leader may have died
          // with unpublished tips. Duplicates are deduped by id everywhere.
          await _startLeading(session, backfill: true);
        }
      } catch (_) {
        // Offline or contended — the next tick reconsiders.
      } finally {
        _takingOver = false;
      }
    }());
  }

  @override
  void onTipsIngested(LiveSession session, List<Tip> fresh) {
    unawaited(_repo.saveActiveSession(
        _bandId, session, _isLeader ? _source.cursor : null));
  }

  @override
  void onGoalEdited(LiveSession session) {
    unawaited(_repo.saveActiveSession(
        _bandId, session, _isLeader ? _source.cursor : null));
    unawaited(_liveDoc
        .set({
          'goalMinor': session.goalMinor,
          'goalUpdatedAtMs': _nowMs,
        }, SetOptions(merge: true))
        .catchError(_ignore));
  }

  @override
  Future<void> stop(LiveSession session) async {
    _stopping = true;
    _teardown();
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_liveDoc);
        // Flip only OUR session's doc: a stale-lease successor may already
        // have installed a new session, and its night is not ours to end.
        if (snap.data()?['sessionId'] != session.id) return;
        tx.update(_liveDoc, {
          'active': false,
          'endedAtMs': session.endedAt?.millisecondsSinceEpoch ?? _nowMs,
        });
      });
    } catch (e) {
      // Offline — the doc stays active until the lease goes stale, which
      // the start transaction treats as free for takeover anyway.
      debugPrint('cloud session: stop transaction failed: $e');
    }
    // Finalize the archive doc with the full assembled set. This IS the
    // history entry — no repository append, or the night doubles. Fire-and-
    // forget: awaiting would hang an offline stop, and Firestore queues
    // the write durably either way.
    unawaited(_sessionDoc
        .set({...session.toJson(), 'updatedAtMs': _nowMs})
        .catchError(_ignore));
    await _repo.clearActiveSession(_bandId);
  }

  @override
  void reconnectNow() => _relay?.reconnectNow();

  @override
  Future<void> dispose() async => _teardown();

  void _teardown() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _docSub?.cancel();
    _docSub = null;
    _tipsSub?.cancel();
    _tipsSub = null;
    _relayTipsSub?.cancel();
    _relayTipsSub = null;
    _relayStatusSub?.cancel();
    _relayStatusSub = null;
    _source.dispose();
    final relay = _relay;
    if (relay != null) unawaited(relay.dispose());
    _polling = false;
    _skipTicks = 0;
  }

  /// Lenient like the repository's decoders: a malformed tip doc costs
  /// itself, never the feed.
  static Tip? _decodeTip(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      return Tip.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // A listener/write error (network teardown, revoked rules) must never take
  // the session down; health surfaces through the poll events instead.
  static void _ignore(Object _) {}
}
