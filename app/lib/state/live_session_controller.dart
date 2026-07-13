import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tip_source.dart';
import '../data/tip_channel.dart';
import '../data/stripe/stripe_client.dart';
import '../domain/tip.dart';
import '../domain/fx_rates.dart';
import '../domain/live_session.dart';
import '../domain/rollover_math.dart';
import 'providers.dart';

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

/// Owns the active session: the polling timer, incoming tips, the goal,
/// stage lock, and persistence so a crash or restart never loses a set.
class LiveSessionController extends Notifier<LiveState?> {
  Timer? _timer;
  TipSource? _source;
  TipChannel? _relay;
  StreamSubscription<Tip>? _relayTipsSub;
  ProviderSubscription<FxRates?>? _fxSub;
  StreamSubscription<RelayHealth>? _relayStatusSub;
  bool _polling = false;
  int _skipTicks = 0;

  /// The band this session belongs to, snapshotted at [_begin] alongside its
  /// key and jars — every persistence write goes to this band's slots, so a
  /// session can never leak data into another band's history.
  String _accountId = '';

  @override
  LiveState? build() {
    ref.onDispose(_teardown);
    return null;
  }

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
    await _begin(session);
  }

  /// Restores the session persisted before a crash/app restart. The stored
  /// event cursor means tips made while the app was dead still count.
  Future<bool> resumeStored() async {
    final app = ref.read(appStateProvider);
    if (app.switching) return false;
    final repo = ref.read(accountDataRepositoryProvider);
    final stored = repo.readActiveSession(app.accountId);
    if (stored == null) return false;
    await _begin(stored,
        resumeCursor: repo.readActiveCursor(app.accountId), resumed: true);
    return true;
  }

  Future<void> discardStored() async {
    await ref
        .read(accountDataRepositoryProvider)
        .clearActiveSession(ref.read(appStateProvider).accountId);
    ref.read(storedSessionProvider.notifier).refresh();
  }

  Future<void> _begin(LiveSession session,
      {String? resumeCursor, bool resumed = false}) async {
    _teardown();
    final app = ref.read(appStateProvider);
    _accountId = app.accountId;
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
    // No tip jar is fine (relay-only): the factory returns a silent source.
    _source = ref.read(tipSourceFactoryProvider)(
        demo: app.demo, apiKey: app.apiKey, jar: app.effectiveTipJar);
    // A restored session may owe rollovers (goal edits, older builds).
    session.applyRollovers();

    // The relay tip feed (MobilePay/Revolut fan page) — null when this
    // session has none (demo, or no connected-mode jar).
    _relay = ref.read(relayChannelFactoryProvider)(
        demo: app.demo, jar: app.effectiveRelayJar, secret: app.relaySecret);

    state = LiveState(
      session: session,
      relay: _relay == null ? null : RelayHealth.connecting,
    );
    await ref
        .read(accountDataRepositoryProvider)
        .saveActiveSession(_accountId, session, resumeCursor);
    ref.read(storedSessionProvider.notifier).refresh();

    // Subscribe BEFORE start(): broadcast streams don't replay, and the
    // first status transition arrives as soon as the socket opens.
    final relay = _relay;
    if (relay != null) {
      _relayTipsSub = relay.tips.listen((tip) => _ingest([tip]));
      _relayStatusSub = relay.status
          .listen((health) => state = state?.copyWith(relay: health));
      relay.start();
    }

    try {
      await _source!.prime(session.startedAt,
          resumeCursor: resumeCursor, backfill: resumed);
      state = state?.copyWith(health: PollHealth.ok, clearError: true);
    } catch (e) {
      _reportError(e);
    }

    final seconds = app.settings.pollIntervalSec.clamp(2, 60);
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => _tick());
    unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_polling || state == null || _source == null) return;
    if (_skipTicks > 0) {
      _skipTicks--;
      return;
    }
    _polling = true;
    try {
      final fresh = await _source!.pollNew();
      final current = state;
      if (current == null) return;
      if (current.health != PollHealth.ok) {
        state = current.copyWith(health: PollHealth.ok, clearError: true);
      }
      _ingest(fresh);
    } catch (e) {
      if (e is StripeApiException && e.isRateLimited) _skipTicks = 3;
      _reportError(e);
    } finally {
      _polling = false;
    }
  }

  /// Applies freshly arrived tips — from the Stripe poll OR the relay
  /// channel — to the session: attribution (fill deltas, rollovers), the
  /// newTips batch + confettiTick celebration serial, and the crash-recovery
  /// snapshot. Duplicates (same tip id) are dropped by the session, so
  /// at-least-once feeds are safe to replay through here.
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
    unawaited(ref
        .read(accountDataRepositoryProvider)
        .saveActiveSession(_accountId, current.session, _source?.cursor));
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
      // Fire-and-forget like saveActiveSession above. setString updates the
      // SharedPreferences in-memory cache synchronously, so the refresh
      // below already sees the new tips — only the disk write is deferred.
      unawaited(ref
          .read(accountDataRepositoryProvider)
          .appendRelayHistory(_accountId, relayTips));
      ref.read(relayHistoryProvider.notifier).refresh();
    }
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
  void relayReconnectNow() => _relay?.reconnectNow();

  void editGoal(int goalMinor) {
    final current = state;
    if (current == null || goalMinor <= 0) return;
    current.session.goalMinor = goalMinor;
    // Lowering the goal can instantly owe rollovers (total ≥ 2× new goal).
    current.session.applyRollovers();
    state = current.copyWith(session: current.session);
    unawaited(ref
        .read(accountDataRepositoryProvider)
        .saveActiveSession(_accountId, current.session, _source?.cursor));
    final app = ref.read(appStateProvider);
    unawaited(ref
        .read(appStateProvider.notifier)
        .updateBand(app.band.copyWith(lastGoalMinor: goalMinor)));
  }

  void setLocked(bool locked) {
    state = state?.copyWith(locked: locked);
  }

  /// Ends the session, archives it, and returns it for the summary screen.
  Future<LiveSession?> stop() async {
    final current = state;
    if (current == null) return null;
    _teardown();
    final session = current.session..endedAt = DateTime.now();
    final repo = ref.read(accountDataRepositoryProvider);
    await repo.appendSessionToHistory(_accountId, session);
    await repo.clearActiveSession(_accountId);
    state = null;
    ref.read(storedSessionProvider.notifier).refresh();
    // Tips that arrived during the set aren't in the home preview's cached
    // Stripe query — refresh it so Recent tips reflects the night just played.
    ref.invalidate(recentTipsProvider);
    return session;
  }

  void _teardown() {
    _timer?.cancel();
    _timer = null;
    _fxSub?.close();
    _fxSub = null;
    _source?.dispose();
    _source = null;
    _relayTipsSub?.cancel();
    _relayTipsSub = null;
    _relayStatusSub?.cancel();
    _relayStatusSub = null;
    final relay = _relay;
    _relay = null;
    if (relay != null) unawaited(relay.dispose());
    _polling = false;
    _skipTicks = 0;
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
    final accountId =
        ref.watch(appStateProvider.select((s) => s.accountId));
    return ref
        .read(accountDataRepositoryProvider)
        .readActiveSession(accountId);
  }

  void refresh() => state = ref
      .read(accountDataRepositoryProvider)
      .readActiveSession(ref.read(appStateProvider).accountId);
}

final storedSessionProvider =
    NotifierProvider<StoredSessionNotifier, LiveSession?>(
        StoredSessionNotifier.new);
