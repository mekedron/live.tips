import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/donation_source.dart';
import '../data/relay/relay_tip_channel.dart';
import '../data/stripe/stripe_client.dart';
import '../domain/donation.dart';
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
    this.lastDonation,
    this.confettiTick = 0,
    this.newTips = const [],
    this.relay,
  });

  final LiveSession session;
  final PollHealth health;
  final String? lastError;

  /// Health of the relay tip feed (MobilePay/Revolut donor page), or null
  /// when this session runs without a relay channel — the stage shows no
  /// second pill then. Never returns to null within a session.
  final RelayHealth? relay;

  /// Stage lock: input is blocked until the artist authenticates.
  final bool locked;
  final Donation? lastDonation;

  /// Increases once per newly arrived donation — UI listens and fires 🎉.
  /// Doubles as the serial for [newTips]: consumers act on the batch only
  /// when this advanced (the batch is CARRIED by later copyWith calls, so
  /// non-emptiness alone means nothing).
  final int confettiTick;

  /// Every donation added in the latest poll tick, with its jar attribution
  /// (fill delta, rollovers) — the stage renderers pour exactly this.
  final List<JarTipAttribution> newTips;

  LiveState copyWith({
    LiveSession? session,
    PollHealth? health,
    String? lastError,
    bool clearError = false,
    bool? locked,
    Donation? lastDonation,
    int? confettiTick,
    List<JarTipAttribution>? newTips,
    RelayHealth? relay,
  }) =>
      LiveState(
        session: session ?? this.session,
        health: health ?? this.health,
        lastError: clearError ? null : (lastError ?? this.lastError),
        locked: locked ?? this.locked,
        lastDonation: lastDonation ?? this.lastDonation,
        confettiTick: confettiTick ?? this.confettiTick,
        newTips: newTips ?? this.newTips,
        relay: relay ?? this.relay,
      );
}

/// Owns the active session: the polling timer, incoming donations, the goal,
/// stage lock, and persistence so a crash or restart never loses a set.
class LiveSessionController extends Notifier<LiveState?> {
  Timer? _timer;
  DonationSource? _source;
  RelayTipChannel? _relay;
  StreamSubscription<Donation>? _relayTipsSub;
  StreamSubscription<RelayHealth>? _relayStatusSub;
  bool _polling = false;
  int _skipTicks = 0;

  @override
  LiveState? build() {
    ref.onDispose(_teardown);
    return null;
  }

  Future<void> start({required int goalMinor}) async {
    final app = ref.read(appStateProvider);
    // Demo, Stripe, or a relay jar — any of them can host a session; only a
    // fully unconfigured app has nothing to run one against.
    if (!app.connected) return;
    final now = DateTime.now();
    final session = LiveSession(
      id: 'ses_${now.millisecondsSinceEpoch.toRadixString(36)}',
      startedAt: now,
      currency: app.currency,
      goalMinor: goalMinor,
    );
    unawaited(ref
        .read(appStateProvider.notifier)
        .updateSettings(app.settings.copyWith(lastGoalMinor: goalMinor)));
    await _begin(session);
  }

  /// Restores the session persisted before a crash/app restart. The stored
  /// event cursor means donations made while the app was dead still count.
  Future<bool> resumeStored() async {
    final local = ref.read(localStoreProvider);
    final stored = local.readActiveSession();
    if (stored == null) return false;
    await _begin(stored,
        resumeCursor: local.readActiveCursor(), resumed: true);
    return true;
  }

  Future<void> discardStored() async {
    await ref.read(localStoreProvider).clearActiveSession();
    ref.read(storedSessionProvider.notifier).refresh();
  }

  Future<void> _begin(LiveSession session,
      {String? resumeCursor, bool resumed = false}) async {
    _teardown();
    final app = ref.read(appStateProvider);
    // No tip jar is fine (relay-only): the factory returns a silent source.
    _source = ref.read(donationSourceFactoryProvider)(
        demo: app.demo, apiKey: app.apiKey, jar: app.effectiveTipJar);
    // A restored session may owe rollovers (goal edits, older builds).
    session.applyRollovers();

    // The relay tip feed (MobilePay/Revolut donor page) — null when this
    // session has none (demo, or no connected-mode jar).
    _relay = ref.read(relayChannelFactoryProvider)(
        demo: app.demo, jar: app.effectiveRelayJar, secret: app.relaySecret);

    state = LiveState(
      session: session,
      relay: _relay == null ? null : RelayHealth.connecting,
    );
    await ref.read(localStoreProvider).saveActiveSession(session, resumeCursor);
    ref.read(storedSessionProvider.notifier).refresh();

    // Subscribe BEFORE start(): broadcast streams don't replay, and the
    // first status transition arrives as soon as the socket opens.
    final relay = _relay;
    if (relay != null) {
      _relayTipsSub = relay.tips.listen((donation) => _ingest([donation]));
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

  /// Applies freshly arrived donations — from the Stripe poll OR the relay
  /// channel — to the session: attribution (fill deltas, rollovers), the
  /// newTips batch + confettiTick celebration serial, and the crash-recovery
  /// snapshot. Duplicates (same donation id) are dropped by the session, so
  /// at-least-once feeds are safe to replay through here.
  void _ingest(List<Donation> fresh) {
    final current = state;
    if (current == null || fresh.isEmpty) return;
    final tips = <JarTipAttribution>[];
    for (final donation in fresh) {
      final tip = current.session.addDonationAttributed(donation);
      if (tip != null) tips.add(tip);
    }
    if (tips.isEmpty) return; // every one a duplicate — nothing changed
    debugPrint('live ingest: +${tips.length} donation(s), '
        'total ${current.session.totalMinor}');
    state = current.copyWith(
      lastDonation: tips.last.donation,
      confettiTick: current.confettiTick + tips.length,
      newTips: tips,
    );
    unawaited(ref
        .read(localStoreProvider)
        .saveActiveSession(current.session, _source?.cursor));
    // Tip-page (relay) tips exist nowhere but this device — archive them so
    // History still has them after the session ends. Real money only: demo
    // relay tips (livemode:false) must never enter the archive. Replays
    // (relay redelivery, resume/backfill) are deduped by id in the store,
    // same as the session dedupes above, so double-writes are harmless.
    final relayTips = [
      for (final tip in tips)
        if (!tip.donation.verified && tip.donation.livemode) tip.donation,
    ];
    if (relayTips.isNotEmpty) {
      // Fire-and-forget like saveActiveSession above. setString updates the
      // SharedPreferences in-memory cache synchronously, so the refresh
      // below already sees the new tips — only the disk write is deferred.
      unawaited(ref.read(localStoreProvider).appendRelayHistory(relayTips));
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

  void editGoal(int goalMinor) {
    final current = state;
    if (current == null || goalMinor <= 0) return;
    current.session.goalMinor = goalMinor;
    // Lowering the goal can instantly owe rollovers (total ≥ 2× new goal).
    current.session.applyRollovers();
    state = current.copyWith(session: current.session);
    unawaited(ref
        .read(localStoreProvider)
        .saveActiveSession(current.session, _source?.cursor));
    final app = ref.read(appStateProvider);
    unawaited(ref
        .read(appStateProvider.notifier)
        .updateSettings(app.settings.copyWith(lastGoalMinor: goalMinor)));
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
    final local = ref.read(localStoreProvider);
    await local.appendSessionToHistory(session);
    await local.clearActiveSession();
    state = null;
    ref.read(storedSessionProvider.notifier).refresh();
    // Tips that arrived during the set aren't in the home preview's cached
    // Stripe query — refresh it so Recent tips reflects the night just played.
    ref.invalidate(recentDonationsProvider);
    return session;
  }

  void _teardown() {
    _timer?.cancel();
    _timer = null;
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

/// The session persisted for crash/restart recovery — watched separately
/// from [liveSessionProvider] because discarding/resuming it never changes
/// [LiveState] (which stays null throughout), so nothing would tell widgets
/// to rebuild. Refreshed explicitly wherever the active-session storage key
/// is written or cleared.
class StoredSessionNotifier extends Notifier<LiveSession?> {
  @override
  LiveSession? build() => ref.read(localStoreProvider).readActiveSession();

  void refresh() => state = ref.read(localStoreProvider).readActiveSession();
}

final storedSessionProvider =
    NotifierProvider<StoredSessionNotifier, LiveSession?>(
        StoredSessionNotifier.new);
