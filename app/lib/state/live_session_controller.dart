import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/donation_source.dart';
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
  });

  final LiveSession session;
  final PollHealth health;
  final String? lastError;

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
  }) =>
      LiveState(
        session: session ?? this.session,
        health: health ?? this.health,
        lastError: clearError ? null : (lastError ?? this.lastError),
        locked: locked ?? this.locked,
        lastDonation: lastDonation ?? this.lastDonation,
        confettiTick: confettiTick ?? this.confettiTick,
        newTips: newTips ?? this.newTips,
      );
}

/// Owns the active session: the polling timer, incoming donations, the goal,
/// stage lock, and persistence so a crash or restart never loses a set.
class LiveSessionController extends Notifier<LiveState?> {
  Timer? _timer;
  DonationSource? _source;
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

    state = LiveState(session: session);
    await ref.read(localStoreProvider).saveActiveSession(session, resumeCursor);
    ref.read(storedSessionProvider.notifier).refresh();

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
      if (fresh.isEmpty) {
        if (current.health != PollHealth.ok) {
          state = current.copyWith(health: PollHealth.ok, clearError: true);
        }
        return;
      }
      final tips = <JarTipAttribution>[];
      for (final donation in fresh) {
        final tip = current.session.addDonationAttributed(donation);
        if (tip != null) tips.add(tip);
      }
      debugPrint('live poll: +${tips.length} donation(s), '
          'total ${current.session.totalMinor}');
      state = current.copyWith(
        health: PollHealth.ok,
        clearError: true,
        lastDonation: tips.isEmpty ? current.lastDonation : tips.last.donation,
        confettiTick: current.confettiTick + tips.length,
        newTips: tips,
      );
      await ref
          .read(localStoreProvider)
          .saveActiveSession(current.session, _source?.cursor);
    } catch (e) {
      if (e is StripeApiException && e.isRateLimited) _skipTicks = 3;
      _reportError(e);
    } finally {
      _polling = false;
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
