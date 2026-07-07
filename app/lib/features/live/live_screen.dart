import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/fullscreen.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/live_session.dart';
import '../../domain/stage_settings.dart';
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/goal_editor.dart';
import '../../widgets/qr_card.dart';
import '../lock/lock_service.dart';
import '../settings/stage_settings_section.dart';
import 'stage/jar_stage_view.dart';
import 'stage/stage_chrome.dart';
import 'stage/stage_hud.dart';
import 'stage/stage_resolver.dart';
import 'stage/stage_types.dart';

/// The stage screen: the jar fills full-bleed, glass controls float on top —
/// big total, goal progress, live donation feed, celebration. Designed to be
/// readable from a distance on a dark stage, to keep the screen awake, and
/// to be lockable while the device is unattended.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 1400),
    );
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // every session gets a fresh chance at the 3D stage (post-frame:
    // providers must not change while the tree is building)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(stageHealthProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop this session?'),
        content: const Text(
          'The session is saved to history with all its stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final session = await ref.read(liveSessionProvider.notifier).stop();
    if (!mounted || session == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _SessionSummaryDialog(session: session),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleBack() async {
    final live = ref.read(liveSessionProvider);
    if (live == null) {
      Navigator.of(context).pop();
      return;
    }
    if (live.locked) return; // locked = no navigation
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the stage screen?'),
        content: const Text(
          'The session keeps collecting in the background — you can '
          'return from the home screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('stay'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('stop'),
            child: const Text('Stop session'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('leave'),
            child: const Text('Keep running'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'leave') {
      Navigator.of(context).pop();
    } else if (choice == 'stop') {
      await _confirmStop();
    }
  }

  // The lock button only shows where device auth exists (see canLock), so
  // locking just flips the flag — the OS prompt comes on unlock.
  void _lock() => ref.read(liveSessionProvider.notifier).setLocked(true);

  Future<void> _unlock() async {
    if (await ref.read(lockServiceProvider).authenticate()) {
      ref.read(liveSessionProvider.notifier).setLocked(false);
    }
  }

  Future<void> _editGoal() async {
    final live = ref.read(liveSessionProvider);
    if (live == null) return;
    final session = live.session;
    final newGoal = await showGoalEditorSheet(
      context,
      initialMinor: session.goalMinor,
      currency: session.currency,
      title: 'Adjust tonight\'s goal',
    );
    if (newGoal != null) {
      ref.read(liveSessionProvider.notifier).editGoal(newGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveSessionProvider);
    final app = ref.watch(appStateProvider);
    // The one QR every stage surface shows; null only when nothing is
    // configured (then the affordances hide rather than crash).
    final qrUrl = app.activeQrUrl;
    // Without a Stripe key nothing is being watched (relay feed comes in a
    // later step) — the health pill must not claim otherwise.
    final okLabel =
        app.hasStripe || app.demo ? 'Watching Stripe' : 'Session running';
    final stageConfig = app.settings.stage;
    // The stage can only be locked where the device itself can authenticate —
    // no Face ID / device unlock (e.g. the browser) → no lock button.
    final canLock =
        ref.watch(deviceAuthAvailableProvider).asData?.value ?? false;
    final effectiveStyle = resolveEffectiveStyle(
      stageConfig.style,
      webViewSupported: ref.watch(stageCapabilityProvider),
      health: ref.watch(stageHealthProvider),
    );

    ref.listen<LiveState?>(liveSessionProvider, (previous, next) {
      if (previous != null &&
          next != null &&
          next.confettiTick > previous.confettiTick) {
        // jar stages celebrate in-scene — screen confetti is classic-only
        if (effectiveStyle == StageStyle.classic) _confetti.play();
        HapticFeedback.mediumImpact();
      }
    });

    // Forced dark regardless of the app's light/dark setting: the stage is
    // meant to be read from a distance during a live performance, not to
    // match the device's ambient chrome.
    if (live == null) {
      // Session just ended (summary flow pops us) — render nothing.
      return Theme(
        data: buildDarkTheme(),
        child:
            const Scaffold(backgroundColor: kStageBlack, body: SizedBox()),
      );
    }

    return Theme(
      data: buildDarkTheme(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: kStageBlack,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 780;
              final safeTop = MediaQuery.paddingOf(context).top;
              return Stack(
                children: [
                  // ---- the stage itself, edge to edge ----
                  Positioned.fill(
                    child: effectiveStyle == StageStyle.classic
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              safeTop + 72,
                              // wide: keep the numbers clear of the QR rail
                              wide ? kStageRailInset : 16,
                              wide ? 16 : 100,
                            ),
                            child: JarStageView(
                              snapshot: StageSnapshot.fromState(live),
                              tips: live.newTips,
                              tipSerial: live.confettiTick,
                              config: stageConfig,
                            ),
                          )
                        : JarStageView(
                            snapshot: StageSnapshot.fromState(live),
                            tips: live.newTips,
                            tipSerial: live.confettiTick,
                            config: stageConfig,
                          ),
                  ),
                  // ---- wide: floating QR + messages panel ----
                  if (wide && qrUrl != null)
                    Positioned(
                      right: 16,
                      top: safeTop + 76,
                      bottom: 16,
                      width: kStageRailWidth,
                      child: StageQrPanel(
                        url: qrUrl,
                        name: app.displayName,
                        messages: live.session.donations.reversed
                            .where((d) => d.hasMessage)
                            .take(3)
                            .toList(),
                      ),
                    ),
                  // ---- top controls ----
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          StageGlassButton(
                            icon: Icons.stop_rounded,
                            iconColor: const Color(0xFFFF6B5E),
                            tooltip: 'Stop session',
                            size: wide ? 44 : 40,
                            onTap: _confirmStop,
                          ),
                          const SizedBox(width: 8),
                          _LivePill(
                            startedAt: live.session.startedAt,
                            compact: !wide,
                          ),
                          if (wide) ...[
                            const SizedBox(width: 8),
                            _HealthPill(
                                health: live.health,
                                error: live.lastError,
                                okLabel: okLabel),
                          ] else if (live.health != PollHealth.ok) ...[
                            const SizedBox(width: 8),
                            _HealthPill(
                              health: live.health,
                              error: live.lastError,
                              okLabel: okLabel,
                              dotOnly: true,
                            ),
                          ],
                          const Spacer(),
                          if (wide) ...[
                            StageGlassButton(
                              icon: Icons.flag_rounded,
                              tooltip: 'Adjust goal',
                              onTap: _editGoal,
                            ),
                            const SizedBox(width: 8),
                            StageGlassButton(
                              icon: Icons.palette_rounded,
                              tooltip: 'Stage look',
                              onTap: () => showStageLookSheet(context),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (fullscreenAvailable) ...[
                            StageFullscreenButton(size: wide ? 44 : 40),
                            const SizedBox(width: 8),
                          ],
                          if (canLock)
                            StageGlassButton(
                              icon: Icons.lock_outline_rounded,
                              tooltip: 'Lock stage screen',
                              size: wide ? 44 : 40,
                              onTap: _lock,
                            ),
                        ],
                      ),
                    ),
                  ),
                  // ---- mobile: bottom glass action bar ----
                  if (!wide)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kStageGlassSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              if (qrUrl != null) ...[
                                Expanded(
                                  // Web: the jar renders as an <iframe> platform
                                  // view that swallows pointer events, so ANY
                                  // control floating over it must be wrapped in a
                                  // PointerInterceptor — otherwise its taps fall
                                  // through to the iframe and nothing happens. That
                                  // was the "Show QR doesn't work in live mode" bug:
                                  // the glass buttons wrap themselves, but this
                                  // hand-rolled coral button has to opt in here.
                                  // (Harmless no-op on native platforms.)
                                  child: PointerInterceptor(
                                    child: Material(
                                      color: kStageAccent,
                                      borderRadius: BorderRadius.circular(12),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () =>
                                            showFullscreenQr(context, qrUrl),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 11),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.qr_code_2_rounded,
                                                  size: 19,
                                                  color: Color(0xFF40160A)),
                                              const SizedBox(width: 7),
                                              Text(
                                                'Show QR',
                                                style: outfitStyle(14,
                                                    const Color(0xFF40160A),
                                                    weight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else
                                const Spacer(),
                              const SizedBox(width: 8),
                              StageGlassSquare(
                                icon: Icons.flag_rounded,
                                tooltip: 'Adjust goal',
                                onTap: _editGoal,
                              ),
                              const SizedBox(width: 8),
                              StageGlassSquare(
                                icon: Icons.palette_rounded,
                                tooltip: 'Stage look',
                                onTap: () => showStageLookSheet(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 28,
                      maxBlastForce: 30,
                      minBlastForce: 8,
                      gravity: 0.25,
                      shouldLoop: false,
                      colors: const [
                        kStageAccent,
                        Colors.white,
                        Color(0xFFFFB79F),
                        kGold,
                        Colors.pinkAccent,
                      ],
                    ),
                  ),
                  if (live.locked) _LockOverlay(onUnlockHold: _unlock),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "● LIVE · 42:17" — pulsing dot, tracked LIVE, tabular clock.
class _LivePill extends StatelessWidget {
  const _LivePill({required this.startedAt, this.compact = false});

  final DateTime startedAt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 40 : 44,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      decoration: BoxDecoration(
        color: kStageGlassSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(color: Color(0xFFFF6B5E)),
          SizedBox(width: compact ? 8 : 9),
          Text(
            'LIVE',
            style: outfitStyle(compact ? 12 : 13, Colors.white,
                weight: FontWeight.w700, letterSpacing: 1),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 16,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 8),
          _ElapsedClock(startedAt: startedAt, compact: compact),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({
    required this.health,
    this.error,
    this.dotOnly = false,
    this.okLabel = 'Watching Stripe',
  });

  final PollHealth health;
  final String? error;
  final bool dotOnly;

  /// What "everything is fine" means for this session — "Watching Stripe"
  /// when a Stripe key is polled, honest neutral wording otherwise.
  final String okLabel;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (health) {
      PollHealth.ok => (const Color(0xFF4FCB8D), okLabel),
      PollHealth.connecting => (const Color(0xFFFFC24D), 'Connecting…'),
      PollHealth.error =>
        (const Color(0xFFFF6B5E), error ?? 'Connection trouble'),
    };
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
        ],
      ),
    );
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        height: dotOnly ? 40 : 44,
        padding: EdgeInsets.symmetric(horizontal: dotOnly ? 15 : 14),
        decoration: BoxDecoration(
          color: kStageGlassSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot,
            if (!dotOnly) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: outfitStyle(
                    12, Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.startedAt, this.compact = false});

  final DateTime startedAt;
  final bool compact;

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    return Text(
      formatDuration(elapsed),
      style: TextStyle(
        fontFamily: kFontOutfit,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: widget.compact ? 13 : 14,
        color: Colors.white.withValues(alpha: 0.75),
      ),
    );
  }
}

String formatDuration(Duration duration) {
  String two(int value) => value.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '${two(minutes)}:${two(seconds)}';
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay({required this.onUnlockHold});

  final Future<void> Function() onUnlockHold;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // swallow every tap
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: GestureDetector(
              onLongPress: onUnlockHold,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kStageGlass,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 17, color: Colors.white.withValues(alpha: 0.75)),
                    const SizedBox(width: 8),
                    Text(
                      'Locked · hold to unlock',
                      style: outfitStyle(
                          13.5, Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overall % of goal, honest past 100% (a 3-jar night should not say "100%").
int _overallPct(LiveSession session) => session.goalMinor <= 0
    ? 0
    : (session.totalMinor / session.goalMinor * 100).round();

class _SessionSummaryDialog extends StatelessWidget {
  const _SessionSummaryDialog({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return AlertDialog(
      title: Text(session.goalReached ? '🎉 Goal reached!' : 'Session done'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatAmount(session.totalMinor, session.currency),
            style: moneyStyle(36, c.accent),
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Tips', value: '${session.count}'),
          _SummaryRow(
            label: 'Duration',
            value: formatDuration(session.elapsed()),
          ),
          _SummaryRow(
            label: 'Goal',
            value:
                '${formatAmount(session.goalMinor, session.currency)} · ${_overallPct(session)}%',
          ),
          if (session.bankedJars > 0)
            _SummaryRow(
              label: 'Full jars',
              value:
                  '🏆 ${session.bankedJars} · ${formatAmount(session.bankedMinor, session.currency)} banked',
            ),
          if (session.count > 0)
            _SummaryRow(
              label: 'Average tip',
              value: formatAmount(session.averageMinor, session.currency),
            ),
          if (session.biggest != null)
            _SummaryRow(
              label: 'Biggest tip',
              value:
                  '${formatAmount(session.biggest!.amountMinor, session.currency)} from ${session.biggest!.displayName}',
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  color: c.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
