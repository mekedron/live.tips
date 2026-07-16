import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/relay/jar_claimer.dart';
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
///   of writers stay idempotent. They are also the night's SAFETY NET: a set
///   whose finalize never landed is rebuilt from them by the history mirror
///   ([FirestoreRepository.readSessionHistory]), so the money survives a stop
///   that could not write.
/// * `…/sessions/{sessionId}` — written as a skeleton at start and finalized
///   with the full [LiveSession.toJson] on stop. The finalized doc IS the
///   archive entry the history mirror reads — stop must NOT also append via
///   the repository, or the night would be archived twice.
///
/// One device — the leader — runs the Stripe poll and writes its fresh tips
/// to the tips subcollection. Fan-page (relay) tips do NOT pass through the
/// leader at all (#71): the SERVER writes them straight into the same
/// subcollection, so no client runs a relay channel and no queue needs a
/// reader — a dead leader can no longer strand fan money. EVERY device (the
/// leader included) ingests from the subcollection listener only: one code
/// path, identical ordering everywhere. The leader's own tips come back
/// through Firestore's latency-compensated local echo, so nothing is
/// delayed, and dedupe by tip id makes the echo safe.
///
/// The one relay call left is the CLAIM ([JarClaimer]): it installs the
/// jar's route (`ownerUid` + `bandId`) — what makes the server write direct
/// in the first place — and keeps this uid in the jar's `readerUids`. Every
/// device claims at attach; the call is idempotent and shared-uid, so the
/// duplication costs a round trip, not correctness.
///
/// The lease: the leader stamps `leaderLeaseUntilMs = now + 45s` on every
/// poll tick. ANY follower that watches the lease go stale by more than two
/// minutes may take leadership over (transaction again) — leading is serving
/// the session (the Stripe poll, the request-queue publish, the finalize,
/// the lease itself), and the Stripe key gates only the poller: a key-less
/// usurper polls [NullTipSource], exactly like the key-less device that
/// STARTS a session does. A zombie leader returning from a long sleep keeps
/// polling harmlessly: its tip writes are idempotent and its stop still
/// flips the same doc.
class CloudSessionCoordinator implements SessionCoordinator {
  CloudSessionCoordinator({
    required FirebaseFirestore db,
    required String uid,
    required String bandId,
    required String deviceId,
    required AccountDataRepository repository,
    required TipSource source,
    required JarClaimer? claimer,
    required int pollIntervalSec,
    required SessionEvents events,
  })  : _db = db,
        _uid = uid,
        _bandId = bandId,
        _deviceId = deviceId,
        _repo = repository,
        _source = source,
        _claimer = claimer,
        _pollIntervalSec = pollIntervalSec,
        _events = events;

  /// How long a leader's claim stays presumed-alive past its last heartbeat.
  static const leaseMs = 45 * 1000;

  /// How long past the lease a leader must stay silent before a follower may
  /// conclude it is gone — generous, because a suspended app that wakes up
  /// mid-set should find its leadership where it left it.
  static const staleMs = 2 * 60 * 1000;

  /// Is a session with this lease still presumed alive?
  ///
  /// THE one definition of liveness, because `active: true` alone is a lie a
  /// crashed tab leaves behind: only a clean stop clears the flag, so a closed
  /// laptop keeps the account "live" forever. The lease is what actually
  /// decays. [_claim] takes a stale-leased session over; every guard that
  /// refuses an action because "a session is running" MUST agree with it, or a
  /// dead session locks the account out of adding and removing profiles.
  static bool leaseAlive(int leaderLeaseUntilMs, {int? nowMs}) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return leaderLeaseUntilMs > now - staleMs;
  }

  final FirebaseFirestore _db;
  final String _uid;
  final String _bandId;
  final String _deviceId;
  final AccountDataRepository _repo;
  final TipSource _source;
  final JarClaimer? _claimer;
  final int _pollIntervalSec;
  final SessionEvents _events;

  String _sessionId = '';
  bool _isLeader = false;

  /// Whether the doc listener has yet seen the session THIS device is running.
  /// Until it has, a doc naming another session is the pre-transaction doc
  /// echoing back, not news that our night ended — see [_onLiveDoc].
  bool _sawOwnSession = false;
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

  static int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  DocumentReference<Map<String, dynamic>> get _liveDoc =>
      _db.doc('users/$_uid/live/current');
  DocumentReference<Map<String, dynamic>> get _sessionDoc =>
      _db.doc('users/$_uid/bands/$_bandId/sessions/$_sessionId');
  CollectionReference<Map<String, dynamic>> get _tipsCol =>
      _sessionDoc.collection('tips');

  // Retired for cloud sessions (#71): no device runs a relay channel, so
  // there is no client-side fan feed for a second pill to be honest about.
  // Feed health lives in the MAIN pill — the leader's Stripe poll, and the
  // tips-subcollection listener's flow on followers (see [_onTipsSnapshot]).
  @override
  RelayHealth? get relayHealthSeed => null;

  // The tips subcollection is durable and redelivers the whole session on
  // every attach — the controller must gate celebration on the device-local
  // presented watermark, not on arrival.
  @override
  bool get replaysTips => true;

  @override
  Future<void> start(
    LiveSession session, {
    String? resumeCursor,
    SessionStartMode mode = SessionStartMode.fresh,
  }) async {
    _session = session;
    _sessionId = session.id;
    _sawOwnSession = false;

    if (mode == SessionStartMode.join) {
      // A follower by definition — the doc already names a leader.
      _isLeader = false;
    } else {
      await _claim(session, mode);
    }

    // The crash snapshot works exactly like the local profile's: this
    // device's in-flight copy of the set, safe across a crash or restart.
    await _repo.saveActiveSession(_bandId, session, resumeCursor);

    // Claim the jar (route install + readerUids) — every device, every
    // mode, fire-and-forget: the session must not wait on the relay, and a
    // claim that never lands only delays an OLD jar's route backfill (its
    // tips keep flowing into pendingTips with today's semantics until a
    // later claim converts it). Already-routed jars flow server-direct
    // regardless of what this call does.
    _claimer?.start();

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
      final leaseFresh = leaseAlive(leaseUntil, nowMs: now);

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
        'requests': _requestsField(session, now),
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

  /// Brings the leader transports up: the Stripe poll and the heartbeat
  /// that rides on it. Fan-page tips are the server's to deliver (#71) —
  /// no relay channel comes up here, for the leader or anyone else.
  Future<void> _startLeading(
    LiveSession session, {
    String? resumeCursor,
    required bool backfill,
  }) async {
    _timer?.cancel();
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
    final updated = <Tip>[];
    for (final change in snap.docChanges) {
      final tip = _decodeTip(change.doc.data());
      if (tip == null) continue;
      switch (change.type) {
        case DocumentChangeType.added:
          fresh.add(tip);
        case DocumentChangeType.modified:
          // A rewritten doc (onTipVerified here or elsewhere) — the same
          // money the session already holds, so it must NOT re-enter the
          // ingest path: replace-in-place, no confetti, no archive write.
          updated.add(tip);
        case DocumentChangeType.removed:
          break; // tips are never deleted mid-session; ignore defensively
      }
    }
    // The listener flowing IS the follower's feed health; the leader's
    // health belongs to its Stripe poll.
    if (!_isLeader) _events.onPollOk();
    if (fresh.isNotEmpty) _events.onTips(fresh);
    if (updated.isNotEmpty) _events.onTipsUpdated(updated);
  }

  void _onLiveDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (_disposed || _stopping) return;
    final data = snap.data();
    if (data == null) return;

    final isOurs = data['sessionId'] == _sessionId;
    if (isOurs && data['active'] == true) _sawOwnSession = true;

    if (data['active'] != true || !isOurs) {
      // INVARIANT: a device that just won the claim must not be told by a
      // PRE-TRANSACTION echo that its own session is over.
      //
      // The doc already has a permanent listener on it (activeSessionProvider
      // feeds the Join banner). When we attach a second one right after the
      // claim, the SDK hands us that target's current data at once — the doc
      // as it was BEFORE our transaction, because the write has not come back
      // down the watch stream yet. It arrives server-synced, so `isFromCache`
      // does not catch it (an earlier fix believed it would, and shipped a
      // still-broken Go live: the session died seconds after starting and the
      // doc this device led came back as a foreign session to "Join").
      //
      // The honest test is not where the snapshot came from but whether it can
      // possibly be about us: until this listener has seen its OWN sessionId
      // once, a doc naming a different session is the old one echoing.
      //
      // Except when it is not: a device that superseded a stale lease writes a
      // session STRICTLY NEWER than ours. That one really does end us, seen or
      // not — otherwise this guard would trade a dead session for a phantom
      // one, where we believe we lead a night that belongs to another device.
      if (!_sawOwnSession && !isOurs) {
        final docStartedAtMs = (data['startedAtMs'] as num?)?.toInt() ?? 0;
        final ourStartedAtMs = _session?.startedAt.millisecondsSinceEpoch ?? 0;
        if (docStartedAtMs <= ourStartedAtMs) return;
      }
      // Stopped on another device (or replaced after a stale takeover) —
      // this device's copy of the set is over. The stopping device owns the
      // archive; here only the snapshot goes.
      _teardown();
      unawaited(_repo.clearActiveSession(_bandId));
      _events.onRemoteEnded();
      return;
    }
    _lastLeaseUntilMs = (data['leaderLeaseUntilMs'] as num?)?.toInt() ?? 0;

    // Goal edits are last-write-wins through the doc; the controller
    // ignores echoes of its own value. Rollovers recompute locally — they
    // are deterministic from tips + goal.
    final goal = (data['goalMinor'] as num?)?.toInt() ?? 0;
    if (goal > 0) _events.onRemoteGoal(goal);

    // Request state rides the doc the same way — LWW, echo-dropped by the
    // controller. A doc without the field (an old build's session) stays
    // silent rather than resetting anything.
    final requests = data['requests'];
    if (requests is Map) {
      _events.onRemoteRequests(
          requests['open'] == true, _decodeStatuses(requests['statuses']));
    }

    // Event-driven staleness check on top of the follower timer: a doc
    // update that reveals a long-dead lease shouldn't wait for the tick.
    _maybeTakeOver();
  }

  /// Follower-side: claims leadership when the lease has been stale for
  /// [staleMs]. ANY follower may bid — the leader is still the fan page's
  /// one VOICE (the request-queue publish) and the account's Stripe poller,
  /// so a takeover refused leaves the queue aggregate frozen and card tips
  /// unpolled for the rest of the set (#70). Money no longer rides on it:
  /// fan-page tips are server-written into the subcollection whoever leads,
  /// or nobody does (#71). This used to demand a Stripe key ("someone's
  /// tablet on the merch table stays a follower forever"), which conflated
  /// *can poll Stripe* with *can serve the session*: a key-less usurper
  /// leads exactly like a key-less starter already does — [NullTipSource]
  /// for the poll, lease heartbeaten.
  void _maybeTakeOver() {
    if (_disposed || _isLeader || _takingOver) return;
    if (_lastLeaseUntilMs <= 0) return; // doc not seen yet
    if (leaseAlive(_lastLeaseUntilMs, nowMs: _nowMs)) return; // leader alive
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
          if (leaseAlive(leaseUntil, nowMs: _nowMs)) return false; // it's back
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
          // The fan page's voice moved with the lease: the old leader may
          // also have died with request state unsent, so the controller
          // re-arms/republishes — the same publish a leading start makes.
          if (!_disposed) _events.onLeadershipTaken();
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

  /// The `requests` field on `live/current`, whole: written at claim and on
  /// every edit — always the FULL state, LWW like the goal.
  ///
  /// Statuses go on the wire as a LIST of `songId:status` strings, not a
  /// map, deliberately: Firestore deep-merges map fields under merge writes
  /// (and the test fake does so even under update()), which would
  /// RESURRECT a status this device just cleared (played → back to queued)
  /// from the doc's old map. A list value is replaced atomically under
  /// every write mode, real and fake alike, so a clear really clears.
  static Map<String, dynamic> _requestsField(LiveSession session, int now) => {
        'open': session.requestsOpen,
        'statuses': [
          for (final e in session.songStatuses.entries) '${e.key}:${e.value}',
        ],
        'updatedAtMs': now,
      };

  /// Decodes [_requestsField]'s statuses list; garbage entries cost only
  /// themselves ([LiveSession.replaceSongStatuses] re-checks the values).
  static Map<String, String> _decodeStatuses(Object? raw) => {
        if (raw is List)
          for (final s in raw)
            if (s is String && s.contains(':'))
              s.substring(0, s.indexOf(':')): s.substring(s.indexOf(':') + 1),
      };

  @override
  void onRequestsEdited(LiveSession session) {
    unawaited(_repo.saveActiveSession(
        _bandId, session, _isLeader ? _source.cursor : null));
    // update(), not set+merge — and the doc exists for as long as the
    // session does (the claim wrote it). A failure is absorbed like every
    // other coordination write: the next edit repeats the full state.
    unawaited(_liveDoc
        .update({'requests': _requestsField(session, _nowMs)})
        .catchError(_ignore));
  }

  @override
  void onTipVerified(LiveSession session, Tip tip) {
    unawaited(_repo.saveActiveSession(
        _bandId, session, _isLeader ? _source.cursor : null));
    // A PLAIN set, deliberately NOT merge: Tip.toJson omits `verified` when
    // true (old history must stay byte-identical), so a merge would leave
    // the doc's stale `verified: false` in place — and every device reading
    // the "verified" tip back would see it unverified forever. Overwriting
    // the whole doc with the fresh toJson is the only honest write.
    unawaited(_tipsCol
        .doc(tip.id)
        .set({...tip.toJson(), 'updatedAtMs': _nowMs})
        .catchError(_ignore));
  }

  @override
  bool get publishesRequests => _isLeader;

  /// Cloud sessions run on a ROUTED jar (the claim installs the route on
  /// every attach, [JarClaimer]) — the server bumps the fan-page totals at
  /// tip-accept time (#71 Phase 3), and this device's publisher must speak
  /// verdicts only.
  @override
  bool get serverComputesRequestTotals => true;

  @override
  Future<void> stop(LiveSession session, {bool durable = false}) async {
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
    // history entry — no repository append, or the night doubles.
    final archive =
        _sessionDoc.set({...session.toJson(), 'updatedAtMs': _nowMs});
    if (!durable) {
      // The ordinary stop: fire-and-forget, because the stage must not wait
      // on the network to end a set, and this device HAS a durable queue —
      // the mutation is on disk and replays at the next launch even if the
      // app dies here.
      unawaited(archive.catchError(_ignore));
      await _repo.clearActiveSession(_bandId);
      return;
    }
    // The caller is about to destroy that queue (a venue teardown, a
    // revocation: both delete the account's FirebaseApp, and venue devices
    // run with no on-disk queue in the first place). "Queued" is worth
    // nothing to them — wait for the write to LAND, exactly as CloudMigrator
    // does at its own commit point.
    await _commitArchive(archive);
    await _repo.clearActiveSession(_bandId);
  }

  /// How long a durable stop waits for the archive before it gives up and
  /// says so. Generous enough for a bad bar Wi-Fi round trip, short enough
  /// that a tablet on a dead network still ends its stint — the artist is
  /// leaving the venue either way, and the wipe must not be held hostage.
  static const commitTimeout = Duration(seconds: 8);

  /// The commit point. The [DocumentReference.set] future resolves on the
  /// server's ack, so awaiting it IS the proof the archive landed — and
  /// draining the queue after it covers the tips of this set, which were
  /// published fire-and-forget and may still be in flight.
  ///
  /// A failure is not swallowed: the crash snapshot stays put (an uncommitted
  /// set is not a finished one), and the caller — the only one that knows what
  /// it is about to tear down — decides what to do about it.
  Future<void> _commitArchive(Future<void> archive) async {
    try {
      await archive.timeout(commitTimeout);
      await _awaitPendingWrites().timeout(commitTimeout);
    } catch (e) {
      debugPrint('cloud session: archive commit failed: $e');
      throw ArchiveNotCommittedException(_sessionId, e);
    }
  }

  Future<void> _awaitPendingWrites() async {
    try {
      await _db.waitForPendingWrites();
    } on UnimplementedError {
      // A platform stub without it has no offline queue to drain.
    } on NoSuchMethodError {
      // fake_cloud_firestore: writes commit synchronously, nothing pends.
    }
  }

  // The one push feed is the Firestore listener, which redials itself; the
  // foreground courtesy goes to a claim still stuck in backoff instead.
  @override
  void reconnectNow() => _claimer?.reconnectNow();

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
    _source.dispose();
    _claimer?.dispose();
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
