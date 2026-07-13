import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tip_channel.dart';
import '../data/stripe/stripe_client.dart';
import '../domain/tip.dart';
import '../domain/fx_rates.dart';
import '../domain/live_session.dart';
import '../domain/rollover_math.dart';
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
  /// second pill then. Never returns to null within a session.
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
  ProviderSubscription<FxRates?>? _fxSub;

  /// WHERE this session persists, snapshotted at [_begin] alongside its key
  /// and jars — every persistence write goes to these slots, so a session can
  /// never leak data into another band's history. [AppState.storageId], not
  /// the band id: a demo set belongs to demo's namespace, and writing it
  /// under the active band put a night that never happened into the artist's
  /// own History (#52).
  String _accountId = '';

  @override
  LiveState? build() {
    ref.onDispose(_teardown);
    return null;
  }

  /// Starts a brand-new session. Throws [SessionAlreadyActiveException]
  /// when the account already runs one on another device (cloud profiles) —
  /// the caller points the artist at the Join banner.
  Future<void> start({required int goalMinor}) async {
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
        onRemoteEnded: _onRemoteEnded,
      ),
    );
    _coordinator = coordinator;

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
    debugPrint('live ingest: +${tips.length} tip(s), '
        'total ${current.session.totalMinor}');
    state = current.copyWith(
      lastTip: tips.last.tip,
      confettiTick: current.confettiTick + tips.length,
      newTips: tips,
    );
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
