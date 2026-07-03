import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/donation.dart';
import '../../domain/live_session.dart';
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/donation_tile.dart';
import '../../widgets/qr_card.dart';
import '../lock/lock_service.dart';

/// The stage screen: big total, goal progress, live donation feed, confetti.
/// Designed to be readable from a distance on a dark stage, to keep the
/// screen awake, and to be lockable while the device is unattended.
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
            'The session is saved to history with all its stats.'),
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
            'return from the home screen.'),
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

  Future<void> _lock() async {
    final lockService = ref.read(lockServiceProvider);
    if (await lockService.ensureUnlockMethod(context)) {
      ref.read(liveSessionProvider.notifier).setLocked(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Set up Face ID / device unlock or an app PIN to use stage lock.'),
      ));
    }
  }

  Future<void> _unlock() async {
    final lockService = ref.read(lockServiceProvider);
    if (await lockService.unlock(context)) {
      ref.read(liveSessionProvider.notifier).setLocked(false);
    }
  }

  Future<void> _editGoal() async {
    final live = ref.read(liveSessionProvider);
    if (live == null) return;
    final session = live.session;
    final controller = TextEditingController(
      text: formatMajorPlain(session.goalMinor, session.currency),
    );
    final newGoal = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Adjust tonight\'s goal',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Goal',
                suffixText: session.currency.toUpperCase(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final bump in [50, 100, 200])
                  ActionChip(
                    label: Text('+$bump'),
                    onPressed: () {
                      final current = parseMajorToMinor(
                              controller.text, session.currency) ??
                          session.goalMinor;
                      controller.text = formatMajorPlain(
                        current +
                            bump * minorUnitsPerMajor(session.currency),
                        session.currency,
                      );
                    },
                  ),
                ActionChip(
                  label: const Text('×2'),
                  onPressed: () {
                    final current = parseMajorToMinor(
                            controller.text, session.currency) ??
                        session.goalMinor;
                    controller.text =
                        formatMajorPlain(current * 2, session.currency);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final value =
                    parseMajorToMinor(controller.text, session.currency);
                Navigator.of(context).pop(value);
              },
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
    if (newGoal != null) {
      ref.read(liveSessionProvider.notifier).editGoal(newGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveSessionProvider);
    final jar = ref.watch(appStateProvider).effectiveTipJar;

    ref.listen<LiveState?>(liveSessionProvider, (previous, next) {
      if (previous != null &&
          next != null &&
          next.confettiTick > previous.confettiTick) {
        _confetti.play();
        HapticFeedback.mediumImpact();
      }
    });

    if (live == null || jar == null) {
      // Session just ended (summary flow pops us) — render nothing.
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 780;
                    return Column(
                      children: [
                        _TopBar(
                          live: live,
                          showQrButton: !wide,
                          qrUrl: jar.url,
                          onStop: _confirmStop,
                          onEditGoal: _editGoal,
                          onLock: _lock,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _MainColumn(live: live)),
                              if (wide) ...[
                                const SizedBox(width: 24),
                                _QrPanel(
                                    url: jar.url, name: jar.displayName),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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
                  kGold,
                  Colors.white,
                  Colors.orangeAccent,
                  Colors.amberAccent,
                  Colors.pinkAccent,
                ],
              ),
            ),
            if (live.locked) _LockOverlay(onUnlockHold: _unlock),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.live,
    required this.showQrButton,
    required this.qrUrl,
    required this.onStop,
    required this.onEditGoal,
    required this.onLock,
  });

  final LiveState live;
  final bool showQrButton;
  final String qrUrl;
  final VoidCallback onStop;
  final VoidCallback onEditGoal;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Stop session',
          onPressed: onStop,
          icon: const Icon(Icons.stop_circle_outlined),
          color: Colors.redAccent,
          iconSize: 30,
        ),
        const SizedBox(width: 4),
        _HealthDot(health: live.health, error: live.lastError),
        const SizedBox(width: 10),
        _ElapsedClock(startedAt: live.session.startedAt),
        const Spacer(),
        if (showQrButton)
          IconButton(
            tooltip: 'Show QR',
            onPressed: () => showFullscreenQr(context, qrUrl),
            icon: const Icon(Icons.qr_code_2_rounded),
            iconSize: 28,
          ),
        IconButton(
          tooltip: 'Adjust goal',
          onPressed: onEditGoal,
          icon: const Icon(Icons.flag_rounded),
          iconSize: 26,
        ),
        IconButton(
          tooltip: 'Lock stage screen',
          onPressed: onLock,
          icon: const Icon(Icons.lock_outline_rounded),
          iconSize: 26,
        ),
      ],
    );
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({required this.health, this.error});

  final PollHealth health;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (health) {
      PollHealth.ok => (Colors.greenAccent, 'Watching your Stripe account'),
      PollHealth.connecting => (Colors.amberAccent, 'Connecting…'),
      PollHealth.error => (Colors.redAccent, error ?? 'Connection trouble'),
    };
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
          ],
        ),
      ),
    );
  }
}

class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.startedAt});

  final DateTime startedAt;

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
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        fontSize: 16,
        color: Colors.white70,
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

class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.live});

  final LiveState live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = live.session;
    final donations = session.donations.reversed.take(14).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatAmount(session.totalMinor, session.currency),
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'of ${formatAmount(session.goalMinor, session.currency)} goal · '
          '${(session.progress * 100).round()}%',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 14),
        _GoalProgressBar(
          progress: session.progress,
          reached: session.goalReached,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              icon: Icons.favorite_rounded,
              label: '${session.count} tips',
            ),
            if (session.biggest != null) ...[
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label:
                    'top ${formatAmount(session.biggest!.amountMinor, session.currency)}',
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _LastDonationHero(donation: live.lastDonation),
        const SizedBox(height: 8),
        Expanded(
          child: donations.isEmpty
              ? Center(
                  child: Text(
                    'Waiting for the first tip…\nthe QR code is doing its thing',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) =>
                      DonationTile(donation: donations[index], dense: true),
                ),
        ),
      ],
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({required this.progress, required this.reached});

  final double progress;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.015, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9D2E), kGold],
                ),
                boxShadow: reached
                    ? [
                        BoxShadow(
                          color: kGold.withValues(alpha: 0.7),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kGold),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _LastDonationHero extends StatelessWidget {
  const _LastDonationHero({this.donation});

  final Donation? donation;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: donation == null
          ? const SizedBox(height: 8, key: ValueKey('empty'))
          : Container(
              key: ValueKey(donation!.id),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: kGold.withValues(alpha: 0.65), width: 1.5),
                color: kGold.withValues(alpha: 0.08),
              ),
              child: Column(
                children: [
                  Text(
                    '💛 ${donation!.displayName} tipped '
                    '${formatAmount(donation!.amountMinor, donation!.currency)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (donation!.hasMessage) ...[
                    const SizedBox(height: 6),
                    Text(
                      '“${donation!.message!.trim()}”',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrBlock(data: url, size: 230),
          const SizedBox(height: 18),
          const Text(
            'Scan to tip 💛',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Locked · hold to unlock',
                      style: TextStyle(color: Colors.white70),
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

class _SessionSummaryDialog extends StatelessWidget {
  const _SessionSummaryDialog({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(session.goalReached ? '🎉 Goal reached!' : 'Session done'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatAmount(session.totalMinor, session.currency),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
              label: 'Tips', value: '${session.count}'),
          _SummaryRow(
              label: 'Duration',
              value: formatDuration(session.elapsed())),
          _SummaryRow(
            label: 'Goal',
            value:
                '${formatAmount(session.goalMinor, session.currency)} · ${(session.progress * 100).round()}%',
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
