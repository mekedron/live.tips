import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tip_channel.dart';
import '../data/stripe/stripe_client.dart';
import '../domain/tip.dart';
import '../domain/fx_rates.dart';
import '../domain/live_session.dart';
import '../domain/rollover_math.dart';
import 'jar_requests_publisher.dart';
import 'providers.dart';
import 'session_coordinator.dart';

enum PollHealth { connecting, ok, error }

class LiveState {
  const LiveState({
    required this.session,
    this.health = PollHealth.connecting,
    this.lastError,
    this.locked = false,
    this.lastTip,
    this.confettiTick = 0,
    this.newTips = const [],
    this.relay,
  });

  final LiveSession session;
  final PollHealth health;
  final String? lastError;

  /// Health of the relay tip feed (MobilePay/Revolut fan page), or null
  /// when this session runs without a relay channel — the stage shows no
  /// second pill then. Never returns to null within a session. Cloud
  /// sessions are ALWAYS null here (#71): no device runs a relay channel —
  /// the server writes fan tips into the account, and the tips-listener's
  /// flow reports through [health] instead.
  final RelayHealth? relay;

  /// Stage lock: input is blocked until the artist authenticates.
  final bool locked;
  final Tip? lastTip;

  /// Increases once per newly arrived tip — UI listens and fires 🎉.
  /// Doubles as the serial for [newTips]: consumers act on the batch only
  /// when this advanced (the batch is CARRIED by later copyWith calls, so
  /// non-emptiness alone means nothing).
  final int confettiTick;

  /// Every tip added in the latest poll tick, with its jar attribution
  /// (fill delta, rollovers) — the stage renderers pour exactly this.
  final List<JarTipAttribution> newTips;

  LiveState copyWith({
    LiveSession? session,
    PollHealth? health,
    String? lastError,
    bool clearError = false,
    bool? locked,
    Tip? lastTip,
    int? confettiTick,
    List<JarTipAttribution>? newTips,
    RelayHealth? relay,
  }) =>
      LiveState(
        session: session ?? this.session,
        health: health ?? this.health,
        lastError: clearError ? null : (lastError ?? this.lastError),
        locked: locked ?? this.locked,
        lastTip: lastTip ?? this.lastTip,
        confettiTick: confettiTick ?? this.confettiTick,
        newTips: newTips ?? this.newTips,
        relay: relay ?? this.relay,
      );
}

/// Owns the active session's STATE: incoming-tip attribution, the goal,
/// stage lock, celebration serial, and error wording. Everything transport
/// — where tips come from, crash snapshots, the archive, other devices —
/// lives behind [SessionCoordinator], created per session through
/// [sessionCoordinatorFactoryProvider].
class LiveSessionController extends Notifier<LiveState?> {
  SessionCoordinator? _coordinator;

  /// Keeps the fan page's request state truthful (open window + queue).
  /// Created per session alongside the coordinator; dies with it.
  JarRequestsPublisher? _publisher;
  ProviderSubscription<FxRates?>? _fxSub;

  /// WHERE this session persists, snapshotted at [_begin] alongside its key
  /// and jars — every persistence write goes to these slots, so a session can
  /// never leak data into another band's history. [AppState.storageId], not
  /// the band id: a demo set belongs to demo's namespace, and writing it
  /// under the active band put a night that never happened into the artist's
  /// own History (#52).
  String _accountId = '';

  /// The device-local presented watermark (#71), loaded at [_begin] for
  /// sessions whose feed replays ([SessionCoordinator.replaysTips]): the
  /// `createdAt` ms of the newest tip THIS device has celebrated, plus the
  /// ids sitting at that exact millisecond (Stripe timestamps are
  /// second-resolution — see [LocalStore.readTipsPresented]). Null for
  /// consume-once feeds (local profiles, demo) — every arrival is genuinely
  /// new there and celebrates exactly as it always has.
  ({int ms, Set<String> ids})? _presented;

  @override
  LiveState? build() {
    ref.onDispose(_teardown);
    return null;
  }

  /// Starts a brand-new session. Throws [SessionAlreadyActiveException]
  /// when the account already runs one on another device (cloud profiles) —
  /// the caller points the artist at the Join banner.
  /// [requestsOpen] is the Go-live toggle's word on taking song requests
  /// tonight; null falls back to the band's master switch — a band that
  /// enabled the feature starts open, everyone else starts (and stays) shut.
  Future<void> start({required int goalMinor, bool? requestsOpen}) async {
    final app = ref.read(appStateProvider);
    // Demo, Stripe, or a relay jar — any of them can host a session; only a
    // fully unconfigured app has nothing to run one against. A band switch
    // in flight means the state is about to be someone else's — refuse.
    if (!app.connected || app.switching) return;
    final now = DateTime.now();
    final session = LiveSession(
      id: 'ses_${now.millisecondsSinceEpoch.toRadixString(36)}',
      startedAt: now,
      currency: app.currency,
      goalMinor: goalMinor,
      requestsOpen: requestsOpen ?? app.band.songRequests.enabled,
    );
    unawaited(ref
        .read(appStateProvider.notifier)
        .updateBand(app.band.copyWith(lastGoalMinor: goalMinor)));
    await _begin(session, mode: SessionStartMode.fresh);
  }

  /// Restores the session persisted before a crash/app restart. The stored
  /// event cursor means tips made while the app was dead still count. On a
  /// cloud profile the coordinator reconciles with `live/current` first —
  /// a session stopped elsewhere meanwhile resumes as nothing.
  Future<bool> resumeStored() async {
    final app = ref.read(appStateProvider);
    if (app.switching) return false;
    final repo = ref.read(accountDataRepositoryProvider);
    final stored = repo.readActiveSession(app.storageId);
    if (stored == null) return false;
    return _begin(stored,
        resumeCursor: repo.readActiveCursor(app.storageId),
        mode: SessionStartMode.resume);
  }

  /// Attaches to the session another device is running (cloud profiles) —
  /// a follower: no poll, no relay channel, tips arrive over the listener.
  Future<bool> join(ActiveSessionInfo info) async {
    final app = ref.read(appStateProvider);
    if (app.switching) return false;
    final session = LiveSession(
      id: info.sessionId,
      startedAt: DateTime.fromMillisecondsSinceEpoch(info.startedAtMs),
      currency: info.currency,
      goalMinor: info.goalMinor,
    );
    return _begin(session, mode: SessionStartMode.join);
  }

  Future<void> discardStored() async {
    await ref
        .read(accountDataRepositoryProvider)
        .clearActiveSession(ref.read(appStateProvider).storageId);
    ref.read(storedSessionProvider.notifier).refresh();
  }

  Future<bool> _begin(LiveSession session,
      {String? resumeCursor, required SessionStartMode mode}) async {
    _teardown();
    final app = ref.read(appStateProvider);
    _accountId = app.storageId;
    // Rates for the goal bar when a set mixes currencies (a £5 Monzo tip in a
    // EUR session). Whatever is cached right now — the stage never waits on the
    // network — and the listener below swaps in a fresher table if one lands
    // mid-set, which re-totals the existing tips rather than leaving them out.
    session.fx = ref.read(fxRatesProvider);
    _fxSub?.close();
    _fxSub = ref.listen<FxRates?>(fxRatesProvider, (_, rates) {
      final current = state;
      if (current == null) return;
      current.session.fx = rates;
      current.session.applyRollovers();
      state = current.copyWith();
    });
    // A restored session may owe rollovers (goal edits, older builds).
    session.applyRollovers();

    final coordinator = ref.read(sessionCoordinatorFactoryProvider)(
      SessionEvents(
        onTips: _ingest,
        onPollOk: _markPollOk,
        onPollError: _reportError,
        onRelayHealth: (health) => state = state?.copyWith(relay: health),
        onRemoteGoal: _applyRemoteGoal,
        onRemoteRequests: _applyRemoteRequests,
        onTipsUpdated: _applyUpdatedTips,
        onRemoteEnded: _onRemoteEnded,
        onLeadershipTaken: _onLeadershipTaken,
      ),
    );
    _coordinator = coordinator;
    _publisher = ref.read(jarRequestsPublisherFactoryProvider)(
        serverComputesTotals: coordinator.serverComputesRequestTotals);

    // Load the presented watermark BEFORE the coordinator starts: a cloud
    // start attaches the tips listener inside start(), so the whole backlog
    // can flow through _ingest before _begin returns. First run on this
    // band (a fresh install, a brand-new device) seeds to NOW — the honest
    // choice between two evils: a reinstalled device joining a running set
    // must not throw a confetti storm over money it merely re-downloaded,
    // and the price is that a tip landing within the device's clock skew of
    // the seed renders quietly once. Seeding is a deliberate begin-time act,
    // never a reaction to a snapshot — a snapshot (least of all a from-cache
    // one) proves presence, not absence, and must not move the mark.
    if (coordinator.replaysTips) {
      final store = ref.read(localStoreProvider);
      final stored = store.readTipsPresented(_accountId);
      if (stored == null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        unawaited(store.writeTipsPresented(_accountId, now, const []));
        _presented = (ms: now, ids: <String>{});
      } else {
        _presented = (ms: stored.ms, ids: stored.ids.toSet());
      }
    } else {
      _presented = null;
    }

    state = LiveState(session: session, relay: coordinator.relayHealthSeed);
    try {
      await coordinator.start(session,
          resumeCursor: resumeCursor, mode: mode);
    } on SessionAlreadyActiveException {
      _teardown();
      state = null;
      rethrow; // the caller shows "already running in <band>"
    } on SessionSupersededException {
      // The stored session was stopped on another device while we were
      // away; the coordinator already archived what the snapshot held.
      _teardown();
      state = null;
      ref.read(storedSessionProvider.notifier).refresh();
      return false;
    }
    ref.read(storedSessionProvider.notifier).refresh();
    // Tell the fan page where tonight's requests stand — arm (or re-arm)
    // the open window after a fresh start or a resume, and close a leftover
    // one when the artist went live with requests off. Only the publishing
    // device speaks (local: this one; cloud: the leader — a joining
    // follower stays quiet). Bands that never enabled the feature skip the
    // relay round-trip entirely: their fan page shows no request UI anyway.
    // A FRESH start (never resume or join — their sets already have
    // standings the server owns, #71 Phase 3) also wholesale-clears the
    // previous night's leftover map on a routed jar.
    if ((session.requestsOpen || app.band.songRequests.enabled) &&
        coordinator.publishesRequests) {
      _publisher?.onOpenChanged(session,
          resetQueue: mode == SessionStartMode.fresh);
    }
    return true;
  }

  /// Applies freshly arrived tips — from the Stripe poll, the relay
  /// channel, or the cloud tips listener — to the session: attribution
  /// (fill deltas, rollovers), the newTips batch + confettiTick celebration
  /// serial, and the crash-recovery snapshot (via the coordinator).
  /// Duplicates (same tip id) are dropped by the session, so at-least-once
  /// feeds are safe to replay through here.
  void _ingest(List<Tip> fresh) {
    final current = state;
    if (current == null || fresh.isEmpty) return;
    final tips = <JarTipAttribution>[];
    for (final incoming in fresh) {
      final attributed = current.session.addTipAttributed(incoming);
      if (attributed != null) tips.add(attributed);
    }
    if (tips.isEmpty) return; // every one a duplicate — nothing changed
    // The celebration gate (#71): on a replaying feed, only tips this
    // device has not presented yet — newer than the watermark, or at its
    // exact millisecond without being among its ids — are NEW TO THIS
    // DEVICE. A mid-set joiner's backfill (or a re-attach replaying the
    // night) renders as money without a confetti storm. The mark advances
    // exactly here, on actual presentation, to the newest createdAt just
    // celebrated — never on snapshot arrival, so a from-cache snapshot can
    // prove tips into the session but can never push the mark past money
    // not yet shown.
    final mark = _presented;
    final unseen = mark == null
        ? tips
        : [
            for (final t in tips)
              if (t.tip.createdAt.millisecondsSinceEpoch > mark.ms ||
                  (t.tip.createdAt.millisecondsSinceEpoch == mark.ms &&
                      !mark.ids.contains(t.tip.id)))
                t,
          ];
    debugPrint('live ingest: +${tips.length} tip(s) '
        '(${unseen.length} unseen), total ${current.session.totalMinor}');
    if (unseen.isEmpty) {
      // Replayed money only: totals and the queue moved, the stage stays
      // quiet — the same restraint _applyUpdatedTips shows a rewrite.
      state = current.copyWith(session: current.session);
    } else {
      if (mark != null) _advancePresented(mark, unseen);
      state = current.copyWith(
        lastTip: unseen.last.tip,
        confettiTick: current.confettiTick + unseen.length,
        newTips: unseen,
      );
    }
    _coordinator?.onTipsIngested(
        current.session, [for (final t in tips) t.tip]);
    // Tip-page (relay) tips exist nowhere but this device — archive them so
    // History still has them after the session ends. Real money only: demo
    // relay tips (livemode:false) must never enter the archive. Replays
    // (relay redelivery, resume/backfill) are deduped by id in the store,
    // same as the session dedupes above, so double-writes are harmless.
    final relayTips = [
      for (final tip in tips)
        if (!tip.tip.verified && tip.tip.livemode) tip.tip,
    ];
    if (relayTips.isNotEmpty) {
      // Fire-and-forget like the snapshot above. setString updates the
      // SharedPreferences in-memory cache synchronously, so the refresh
      // below already sees the new tips — only the disk write is deferred.
      unawaited(ref
          .read(accountDataRepositoryProvider)
          .appendRelayHistory(_accountId, relayTips));
      ref.read(relayHistoryProvider.notifier).refresh();
    }
    // A request tip moved the queue — the fan page should follow (throttled;
    // a publishing storm never outruns the relay's quota).
    if (tips.any((t) => t.tip.songId != null)) _publishQueue();
  }

  /// Advances the presented watermark past [unseen] (all just celebrated):
  /// the newest createdAt wins, and the ids at that exact millisecond ride
  /// along — merged with the previous boundary when the millisecond stands
  /// still (two same-second Stripe tips across two batches).
  void _advancePresented(
      ({int ms, Set<String> ids}) mark, List<JarTipAttribution> unseen) {
    var newest = mark.ms;
    for (final t in unseen) {
      final ms = t.tip.createdAt.millisecondsSinceEpoch;
      if (ms > newest) newest = ms;
    }
    final ids = <String>{
      if (newest == mark.ms) ...mark.ids,
      for (final t in unseen)
        if (t.tip.createdAt.millisecondsSinceEpoch == newest) t.tip.id,
    };
    _presented = (ms: newest, ids: ids);
    unawaited(ref
        .read(localStoreProvider)
        .writeTipsPresented(_accountId, newest, ids.toList()));
  }

  /// Publishes the current queue if this device is the session's voice on
  /// the relay (see [SessionCoordinator.publishesRequests]).
  void _publishQueue() {
    final current = state;
    if (current == null || !(_coordinator?.publishesRequests ?? false)) return;
    _publisher?.onQueueChanged(current.session);
  }

  /// Same, for open-flag flips — immediate, no throttle.
  void _publishOpen() {
    final current = state;
    if (current == null || !(_coordinator?.publishesRequests ?? false)) return;
    _publisher?.onOpenChanged(current.session);
  }

  /// This device took a dead leader's session over (cloud only): it is the
  /// fan page's one voice now, so re-arm the request window and republish
  /// the queue exactly the way a leading start does in [_begin] — the old
  /// leader may have died with its last publish unsent. Same gate as there:
  /// bands that never enabled the feature skip the relay round-trip, and
  /// the session's own request state arrived off `live/current` before the
  /// takeover fired (the doc listener delivers requests before it bids).
  void _onLeadershipTaken() {
    final current = state;
    if (current == null || !(_coordinator?.publishesRequests ?? false)) return;
    if (current.session.requestsOpen ||
        ref.read(appStateProvider).band.songRequests.enabled) {
      _publisher?.onOpenChanged(current.session);
    }
  }

  void _markPollOk() {
    final current = state;
    if (current == null || current.health == PollHealth.ok) return;
    state = current.copyWith(health: PollHealth.ok, clearError: true);
  }

  void _reportError(Object e) {
    debugPrint('live poll error: $e');
    final message = switch (e) {
      StripeApiException(:final friendlyMessage) => friendlyMessage,
      StripeNetworkException() => 'No connection — retrying…',
      _ => e.toString(),
    };
    state = state?.copyWith(health: PollHealth.error, lastError: message);
  }

  /// The app is on screen again — redial the relay feed rather than wait for
  /// the OS to surface a socket that died while we were suspended. No-op for
  /// sessions without a relay jar.
  void relayReconnectNow() => _coordinator?.reconnectNow();

  void editGoal(int goalMinor) {
    final current = state;
    if (current == null || goalMinor <= 0) return;
    current.session.goalMinor = goalMinor;
    // Lowering the goal can instantly owe rollovers (total ≥ 2× new goal).
    current.session.applyRollovers();
    state = current.copyWith(session: current.session);
    _coordinator?.onGoalEdited(current.session);
    final app = ref.read(appStateProvider);
    unawaited(ref
        .read(appStateProvider.notifier)
        .updateBand(app.band.copyWith(lastGoalMinor: goalMinor)));
  }

  /// A goal edit landed from another device (last-write-wins through the
  /// coordination doc). Echoes of our own edits arrive here too — equal
  /// values are dropped so nothing loops.
  void _applyRemoteGoal(int goalMinor) {
    final current = state;
    if (current == null || goalMinor <= 0) return;
    if (current.session.goalMinor == goalMinor) return;
    current.session.goalMinor = goalMinor;
    current.session.applyRollovers();
    state = current.copyWith(session: current.session);
  }

  /// The mid-set pause/resume for song requests. Session state first, then
  /// the other devices (coordination doc), then the fan page — immediately,
  /// because "we stopped taking requests" must not wait out a throttle.
  void toggleRequestsOpen() =>
      setRequestsOpen(!(state?.session.requestsOpen ?? false));

  /// [toggleRequestsOpen]'s explicit form — the settings screen's road into
  /// a RUNNING set: flipping the band's master switch mid-session must open
  /// (or close) tonight's requests too, or a set that went live before the
  /// feature existed can never honestly take a request until it is stopped
  /// and restarted. Equal state is a no-op, so settings echoes cost no
  /// relay call. No session, no-op — the go-live default handles the rest.
  void setRequestsOpen(bool open) {
    final current = state;
    if (current == null || current.session.requestsOpen == open) return;
    current.session.requestsOpen = open;
    state = current.copyWith(session: current.session);
    _coordinator?.onRequestsEdited(current.session);
    _publishOpen();
  }

  /// Marks a request played/skipped ([LiveSession.statusPlayed]/
  /// [LiveSession.statusSkipped]); null puts it back in the queue.
  void setSongStatus(String songId, String? status) {
    final current = state;
    if (current == null) return;
    if (status == null) {
      current.session.clearSongStatus(songId);
    } else {
      current.session.setSongStatus(songId, status);
    }
    state = current.copyWith(session: current.session);
    _coordinator?.onRequestsEdited(current.session);
    _publishQueue();
  }

  /// The artist vouched for a fan-declared (relay) tip: flip it to verified
  /// in place. Survives a crash via the snapshot the coordinator persists,
  /// and reaches other devices through the rewritten tip doc.
  void markVerified(String tipId) {
    final current = state;
    if (current == null) return;
    Tip? match;
    for (final tip in current.session.tips) {
      if (tip.id == tipId) {
        match = tip;
        break;
      }
    }
    if (match == null || match.verified) return;
    final verified = match.copyWith(verified: true);
    current.session.replaceTip(verified);
    state = current.copyWith(session: current.session);
    _coordinator?.onTipVerified(current.session, verified);
    _publishQueue();
  }

  /// Request state landed from another device (LWW through the coordination
  /// doc). Echoes of our own edits arrive here too — equal state is dropped,
  /// the same discipline as [_applyRemoteGoal]. When THIS device is the
  /// publisher (the leader), a follower's flip is republished to the fan
  /// page from here — that is the only road a follower's edit has to it.
  void _applyRemoteRequests(bool open, Map<String, String> statuses) {
    final current = state;
    if (current == null) return;
    final session = current.session;
    final openChanged = session.requestsOpen != open;
    if (!openChanged && mapEquals(session.songStatuses, statuses)) return;
    session.requestsOpen = open;
    session.replaceSongStatuses(statuses);
    state = current.copyWith(session: session);
    if (openChanged) {
      _publishOpen();
    } else {
      _publishQueue();
    }
  }

  /// Rewritten tip docs from the cloud listener — the same money the
  /// session already holds, updated in place. Deliberately NOT the ingest
  /// path: no confetti, no newTips batch, no relay archive append.
  void _applyUpdatedTips(List<Tip> updated) {
    final current = state;
    if (current == null) return;
    var changed = false;
    for (final tip in updated) {
      changed = current.session.replaceTip(tip) || changed;
    }
    if (!changed) return;
    state = current.copyWith(session: current.session);
    _publishQueue();
  }

  void setLocked(bool locked) {
    state = state?.copyWith(locked: locked);
  }

  /// Ends the session, archives it, and returns it for the summary screen.
  ///
  /// [durable] is passed straight to the coordinator: the callers that tear
  /// the account's Firebase app down right after this (the venue end-of-stint,
  /// the revocation guard) ask for a committed archive and get an
  /// [ArchiveNotCommittedException] when it cannot be had. The stage's own
  /// Stop leaves it false and stays instant — see [SessionCoordinator.stop].
  Future<LiveSession?> stop({bool durable = false}) async {
    final current = state;
    if (current == null) return null;
    final coordinator = _coordinator;
    _coordinator = null;
    // Best-effort, fire-and-forget like everything about the fan page: the
    // set is over and must not wait on the relay. Ungated on leadership —
    // ANY device may stop the whole session, and the leader learns of it
    // through onRemoteEnded, which never sends the close. A no-op without a
    // jar; if the call is lost the 12h window lapses on its own.
    final publisher = _publisher;
    _publisher = null;
    publisher?.onStop();
    _fxSub?.close();
    _fxSub = null;
    final session = current.session..endedAt = DateTime.now();
    Object? failure;
    StackTrace? failureTrace;
    if (coordinator != null) {
      try {
        await coordinator.stop(session, durable: durable);
      } catch (e, st) {
        // The set is over whatever the archive did — the transports are down
        // and the stage must not be left on a night that ended. Finish the
        // teardown, then hand the failure to the caller: it is the one that
        // knows what it is about to destroy.
        failure = e;
        failureTrace = st;
      }
    }
    state = null;
    ref.read(storedSessionProvider.notifier).refresh();
    // Tips that arrived during the set aren't in the home preview's cached
    // Stripe query — refresh it so Recent tips reflects the night just played.
    ref.invalidate(recentTipsProvider);
    // An account flip that landed mid-set held its profile reload back —
    // this is the moment it runs (see AppStateNotifier.onSessionEnded).
    ref.read(appStateProvider.notifier).onSessionEnded();
    if (failure != null) {
      Error.throwWithStackTrace(failure, failureTrace ?? StackTrace.current);
    }
    return session;
  }

  /// The session was stopped on another device: tear down to "no session"
  /// WITHOUT the summary — only the stopping device gets the return value,
  /// and the archive is already its doing.
  void _onRemoteEnded() {
    if (state == null) return;
    _teardown();
    state = null;
    ref.read(storedSessionProvider.notifier).refresh();
    ref.invalidate(recentTipsProvider);
    ref.read(appStateProvider.notifier).onSessionEnded();
  }

  void _teardown() {
    _fxSub?.close();
    _fxSub = null;
    // The abandon path: cancel any pending publish WITHOUT closing the
    // window — a session ended elsewhere is the stopping device's to close.
    _publisher?.dispose();
    _publisher = null;
    final coordinator = _coordinator;
    _coordinator = null;
    if (coordinator != null) unawaited(coordinator.dispose());
  }
}

final liveSessionProvider =
    NotifierProvider<LiveSessionController, LiveState?>(
        LiveSessionController.new);

/// The active band's session persisted for crash/restart recovery — watched
/// separately from [liveSessionProvider] because discarding/resuming it
/// never changes [LiveState] (which stays null throughout), so nothing would
/// tell widgets to rebuild. Refreshed explicitly wherever the active-session
/// storage key is written or cleared; watching the account id rebuilds it on
/// every band switch.
class StoredSessionNotifier extends Notifier<LiveSession?> {
  @override
  LiveSession? build() {
    // storageId, not accountId: entering and leaving demo changes WHERE the
    // snapshot lives without changing the band, and the two must not be able
    // to see each other's unfinished sets (#52).
    final storageId =
        ref.watch(appStateProvider.select((s) => s.storageId));
    // The snapshot is device-local, but a band switch inside a cloud
    // profile arrives as a revision bump rather than a new account id.
    ref.watch(repoRevisionProvider);
    return ref
        .read(accountDataRepositoryProvider)
        .readActiveSession(storageId);
  }

  void refresh() => state = ref
      .read(accountDataRepositoryProvider)
      .readActiveSession(ref.read(appStateProvider).storageId);
}

final storedSessionProvider =
    NotifierProvider<StoredSessionNotifier, LiveSession?>(
        StoredSessionNotifier.new);
