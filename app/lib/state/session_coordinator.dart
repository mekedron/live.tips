import 'dart:async';

import '../data/repository/account_data_repository.dart';
import '../data/stripe/stripe_client.dart';
import '../data/tip_channel.dart';
import '../data/tip_source.dart';
import '../domain/live_session.dart';
import '../domain/tip.dart';

/// How a session comes to exist on this device.
enum SessionStartMode {
  /// "Go live" — a brand-new session created here.
  fresh,

  /// Recovering the crash snapshot after an app restart.
  resume,

  /// Joining a session another device is already running (cloud accounts).
  join,
}

/// The account already runs a live session somewhere — thrown by a cloud
/// start so the UI can point at the Join banner instead of silently forking
/// the night into two sessions.
class SessionAlreadyActiveException implements Exception {
  const SessionAlreadyActiveException(this.bandId);

  /// The band the running session belongs to.
  final String bandId;

  @override
  String toString() => 'SessionAlreadyActiveException($bandId)';
}

/// A resumed snapshot's session is no longer the account's active one —
/// another device stopped (or replaced) it while this device was away. The
/// coordinator has already archived what the snapshot held; there is nothing
/// left to resume.
class SessionSupersededException implements Exception {
  const SessionSupersededException();
}

/// A [SessionCoordinator.stop] that was asked to COMMIT the archive could not
/// get it to land (offline, a revoked handle, a network that never answered).
///
/// Only a durable stop throws it, and only the two callers that are about to
/// destroy the write queue ask for one — for them "the write is queued" is not
/// an answer, because the queue is what they are about to delete. The set is
/// over regardless: the caller logs this and finishes its teardown, and what
/// survives of the night is the tips already in `sessions/{id}/tips`, which the
/// history reads back (see [FirestoreRepository.readSessionHistory]).
class ArchiveNotCommittedException implements Exception {
  const ArchiveNotCommittedException(this.sessionId, this.cause);

  final String sessionId;

  /// What the write actually failed with — a timeout, permission-denied on a
  /// revoked device, a dead handle.
  final Object cause;

  @override
  String toString() => 'ArchiveNotCommittedException($sessionId): $cause';
}

/// The controller-side surface a coordinator drives. Everything lands back
/// in [LiveSessionController]: tips go through the one ingest path
/// (attribution, confetti, dedupe by id), health through the one error
/// mapper — so the stage behaves identically whatever the transport.
class SessionEvents {
  const SessionEvents({
    required this.onTips,
    required this.onPollOk,
    required this.onPollError,
    required this.onRelayHealth,
    required this.onRemoteGoal,
    required this.onRemoteRequests,
    required this.onTipsUpdated,
    required this.onRemoteEnded,
    required this.onLeadershipTaken,
  });

  /// Freshly arrived tips, chronological. NOT exactly-once — the consumer
  /// dedupes by tip id.
  final void Function(List<Tip> fresh) onTips;

  /// The tip feed is healthy (a poll succeeded / the listener delivered).
  final void Function() onPollOk;

  /// The tip feed failed; the raw error — wording is the controller's job.
  final void Function(Object error) onPollError;

  /// A relay (push feed) health transition.
  final void Function(RelayHealth health) onRelayHealth;

  /// The goal changed on ANOTHER device (cloud sessions only).
  final void Function(int goalMinor) onRemoteGoal;

  /// Song-request state (the open flag + played/skipped statuses) from the
  /// coordination doc (cloud sessions only). Echoes of this device's own
  /// edits arrive here too — the controller drops equal values, exactly
  /// like [onRemoteGoal].
  final void Function(bool open, Map<String, String> statuses)
      onRemoteRequests;

  /// Tips ALREADY in the session whose docs were rewritten (cloud sessions
  /// only) — a "Mark verified" on another device, typically. Not new money:
  /// the controller replaces in place, no confetti, no newTips batch.
  final void Function(List<Tip> updated) onTipsUpdated;

  /// The session was stopped on ANOTHER device (cloud sessions only) — the
  /// controller tears down without a summary; the stopping device owns it.
  final void Function() onRemoteEnded;

  /// THIS device just took a dead leader's session over (cloud sessions
  /// only; the lease lapsed). The transports are already up — the controller
  /// republishes the jar request state, because the fan page listens to the
  /// leader alone and the old one may have died with its last publish
  /// unsent. Never fires on a leading START: [SessionCoordinator.start]
  /// returns with leadership settled and the controller publishes there.
  final void Function() onLeadershipTaken;
}

/// The account's coordination doc (`users/{uid}/live/current`), decoded.
/// One doc per ACCOUNT — that is what makes "one active session per
/// account" structural rather than best-effort.
class ActiveSessionInfo {
  const ActiveSessionInfo({
    required this.active,
    required this.bandId,
    required this.sessionId,
    required this.startedAtMs,
    required this.currency,
    required this.goalMinor,
    required this.goalUpdatedAtMs,
    required this.leaderDeviceId,
    required this.leaderLeaseUntilMs,
    this.endedAtMs,
  });

  final bool active;
  final String bandId;
  final String sessionId;
  final int startedAtMs;
  final String currency;
  final int goalMinor;
  final int goalUpdatedAtMs;

  /// Which device runs the Stripe poll + relay feed right now, and until
  /// when its claim is presumed alive (heartbeaten on every poll tick).
  final String leaderDeviceId;
  final int leaderLeaseUntilMs;
  final int? endedAtMs;

  /// Null for a missing or malformed doc — a broken doc must never take
  /// the banner (or a join) down with it.
  static ActiveSessionInfo? fromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    final bandId = data['bandId'];
    final sessionId = data['sessionId'];
    if (bandId is! String || sessionId is! String) return null;
    return ActiveSessionInfo(
      active: data['active'] == true,
      bandId: bandId,
      sessionId: sessionId,
      startedAtMs: (data['startedAtMs'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'usd',
      goalMinor: (data['goalMinor'] as num?)?.toInt() ?? 0,
      goalUpdatedAtMs: (data['goalUpdatedAtMs'] as num?)?.toInt() ?? 0,
      leaderDeviceId: data['leaderDeviceId'] as String? ?? '',
      leaderLeaseUntilMs: (data['leaderLeaseUntilMs'] as num?)?.toInt() ?? 0,
      endedAtMs: (data['endedAtMs'] as num?)?.toInt(),
    );
  }
}

/// The transport half of a live session: where tips come from, where the
/// crash snapshot and the finished set are persisted, and — for cloud
/// accounts — how this device coordinates with the account's other devices.
/// One coordinator per session: the controller creates it at start/resume/
/// join and it dies with the session. The controller keeps everything the
/// stage watches (LiveState, attribution, confetti, lock, error wording);
/// the coordinator keeps everything that touches a backing store or another
/// device.
abstract interface class SessionCoordinator {
  /// What [LiveState.relay] should start out as, read before [start]: null
  /// when the session runs without a push feed (the stage shows no second
  /// pill then).
  RelayHealth? get relayHealthSeed;

  /// Whether this session's tip feed is a DURABLE collection that redelivers
  /// every tip of the session on each attach — the cloud tips subcollection.
  /// The controller then derives celebration from the device-local presented
  /// watermark (#71): an at-least-once replay must not re-celebrate money
  /// this device already showed, and a mid-set joiner's backfill must render
  /// without a confetti storm. Local feeds are consume-once (pendingTips
  /// delivery is deletion; the Stripe poll cursors forward), so every
  /// arrival is genuinely new there and the watermark stays out of the way.
  bool get replaysTips;

  /// Brings the transports up for [session]: persists the recovery snapshot,
  /// primes/attaches the tip feeds, and starts delivering [SessionEvents].
  /// Transport failures are reported through the events (the session still
  /// starts, unhealthy) — only COORDINATION refusals throw:
  /// [SessionAlreadyActiveException] and [SessionSupersededException].
  Future<void> start(
    LiveSession session, {
    String? resumeCursor,
    SessionStartMode mode = SessionStartMode.fresh,
  });

  /// The controller ingested [fresh] into [session] — the cue to persist the
  /// crash snapshot (and, on cloud, publish the tips to the other devices).
  void onTipsIngested(LiveSession session, List<Tip> fresh);

  /// The goal changed on THIS device — persist it (and, on cloud, tell the
  /// other devices).
  void onGoalEdited(LiveSession session);

  /// The request state (open flag / song statuses) changed on THIS device —
  /// persist it (and, on cloud, tell the other devices). The [onGoalEdited]
  /// mold, reading both values off [session].
  void onRequestsEdited(LiveSession session);

  /// The artist verified [tip] here ([session] already holds the replaced
  /// copy) — persist the snapshot and, on cloud, rewrite the tip's doc so
  /// every device's listener sees the flip.
  void onTipVerified(LiveSession session, Tip tip);

  /// Whether THIS device is the one that publishes jar request state (the
  /// open window + live queue) to the relay. Local sessions always do;
  /// cloud sessions publish from the LEADER only — a follower's flips ride
  /// `live/current` and the leader republishes, so the fan page has exactly
  /// one voice per session.
  bool get publishesRequests;

  /// Whether the SERVER computes the fan-page queue totals for this session
  /// (#71 Phase 3). On a cloud session the jar is routed — the claim installs
  /// ownerUid+bandId on every attach — and each accepted request tip bumps
  /// requestsLive.songs inside the tip POST's own transaction; the publisher
  /// must then send verdicts only, because a wholesale queue push could
  /// clobber a bump that raced it. Local sessions keep publishing the whole
  /// queue: their tips flow through pendingTips, which the server never
  /// aggregates — the leader's mirror IS the fan page's only source.
  bool get serverComputesRequestTotals;

  /// Ends the session: tears the transports down, archives [session]
  /// (endedAt already set), and clears the crash snapshot. The coordinator
  /// is spent afterwards; [dispose] becomes a no-op.
  ///
  /// [durable] is for the two callers that destroy the account's write queue
  /// the moment this returns — the venue end-of-stint and the revocation
  /// guard both sign out and DELETE the account's `FirebaseApp` (and a venue
  /// device runs with persistence off, so it has no on-disk queue to replay
  /// from at all). They need the archive to have LANDED, not merely to have
  /// been issued: a durable stop waits for it, and throws
  /// [ArchiveNotCommittedException] when it cannot get it there. It also does
  /// NOT clear the crash snapshot then — an uncommitted set is not a finished
  /// one.
  ///
  /// A normal stop leaves it false: the stage must not wait on the network to
  /// end a set, and on a device with persistence the queued mutation really
  /// is durable — it replays at the next launch.
  Future<void> stop(LiveSession session, {bool durable = false});

  /// Redials push feeds immediately (the app returned to the foreground).
  void reconnectNow();

  /// Tears the transports down without archiving — the abandon path
  /// (controller teardown, remote-ended). Idempotent.
  Future<void> dispose();
}

/// Exactly today's single-device behavior: the Stripe poll timer, the relay
/// TipChannel, the crash snapshot on every ingest, and the local history
/// archive on stop. No other device exists as far as this coordinator is
/// concerned, so [SessionEvents.onRemoteGoal]/[onRemoteEnded] never fire.
class LocalSessionCoordinator implements SessionCoordinator {
  LocalSessionCoordinator({
    required String accountId,
    required AccountDataRepository repository,
    required TipSource source,
    required TipChannel? relay,
    required int pollIntervalSec,
    required SessionEvents events,
  })  : _accountId = accountId,
        _repo = repository,
        _source = source,
        _relay = relay,
        _pollIntervalSec = pollIntervalSec,
        _events = events;

  final String _accountId;
  final AccountDataRepository _repo;
  final TipSource _source;
  final TipChannel? _relay;
  final int _pollIntervalSec;
  final SessionEvents _events;

  Timer? _timer;
  StreamSubscription<Tip>? _relayTipsSub;
  StreamSubscription<RelayHealth>? _relayStatusSub;
  bool _polling = false;
  int _skipTicks = 0;
  bool _disposed = false;

  @override
  RelayHealth? get relayHealthSeed =>
      _relay == null ? null : RelayHealth.connecting;

  // Consume-once feeds: the relay queue deletes on delivery, the poll only
  // moves forward — nothing here replays a tip this device already showed.
  @override
  bool get replaysTips => false;

  @override
  Future<void> start(
    LiveSession session, {
    String? resumeCursor,
    SessionStartMode mode = SessionStartMode.fresh,
  }) async {
    await _repo.saveActiveSession(_accountId, session, resumeCursor);

    // Subscribe BEFORE start(): broadcast streams don't replay, and the
    // first status transition arrives as soon as the socket opens.
    final relay = _relay;
    if (relay != null) {
      _relayTipsSub = relay.tips.listen((tip) => _events.onTips([tip]));
      _relayStatusSub = relay.status.listen(_events.onRelayHealth);
      relay.start();
    }

    try {
      await _source.prime(session.startedAt,
          resumeCursor: resumeCursor,
          backfill: mode == SessionStartMode.resume);
      _events.onPollOk();
    } catch (e) {
      _events.onPollError(e);
    }

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
    try {
      final fresh = await _source.pollNew();
      if (_disposed) return;
      _events.onPollOk();
      _events.onTips(fresh);
    } catch (e) {
      if (e is StripeApiException && e.isRateLimited) _skipTicks = 3;
      if (!_disposed) _events.onPollError(e);
    } finally {
      _polling = false;
    }
  }

  @override
  void onTipsIngested(LiveSession session, List<Tip> fresh) {
    unawaited(_repo.saveActiveSession(_accountId, session, _source.cursor));
  }

  @override
  void onGoalEdited(LiveSession session) {
    unawaited(_repo.saveActiveSession(_accountId, session, _source.cursor));
  }

  // Request state and verified flips live inside the session object itself;
  // with no other device to tell, persisting the crash snapshot is the whole
  // job here.
  @override
  void onRequestsEdited(LiveSession session) {
    unawaited(_repo.saveActiveSession(_accountId, session, _source.cursor));
  }

  @override
  void onTipVerified(LiveSession session, Tip tip) {
    unawaited(_repo.saveActiveSession(_accountId, session, _source.cursor));
  }

  @override
  bool get publishesRequests => true;

  @override
  bool get serverComputesRequestTotals => false;

  // [durable] is a no-op here: prefs are the store, the write is awaited, and
  // there is no queue between this device and it.
  @override
  Future<void> stop(LiveSession session, {bool durable = false}) async {
    _teardown();
    await _repo.appendSessionToHistory(_accountId, session);
    await _repo.clearActiveSession(_accountId);
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
}
