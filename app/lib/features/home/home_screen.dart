import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../state/live_session_controller.dart';
import '../../state/providers.dart';
import '../../widgets/donation_tile.dart';
import '../../widgets/qr_card.dart';
import '../../widgets/test_mode_banner.dart';
import '../history/history_screen.dart';
import '../live/live_screen.dart';
import '../settings/settings_screen.dart';
import 'stage_quick_settings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _goalController;

  /// Dev convenience: `flutter run --dart-define=AUTO_RESUME=1` jumps
  /// straight back into a stored session — no clicking through the UI.
  static const _autoResume =
      bool.fromEnvironment('AUTO_RESUME', defaultValue: false);

  @override
  void initState() {
    super.initState();
    if (_autoResume) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final controller = ref.read(liveSessionProvider.notifier);
        if (ref.read(liveSessionProvider) == null &&
            controller.hasStoredSession) {
          final resumed = await controller.resumeStored();
          if (resumed && mounted) _openLive();
        }
      });
    }
    final app = ref.read(appStateProvider);
    _goalController = TextEditingController(
      text: formatMajorPlain(
        app.settings.lastGoalMinor,
        app.effectiveTipJar?.currency ?? 'usd',
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final app = ref.read(appStateProvider);
    final currency = app.effectiveTipJar?.currency ?? 'usd';
    final goal = parseMajorToMinor(_goalController.text, currency);
    if (goal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter tonight\'s goal amount first')),
      );
      return;
    }
    await ref.read(liveSessionProvider.notifier).start(goalMinor: goal);
    if (mounted) _openLive();
  }

  void _openLive() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LiveScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final live = ref.watch(liveSessionProvider);
    final jar = app.effectiveTipJar!;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.volunteer_activism, color: kGold, size: 26),
            SizedBox(width: 10),
            Text('live.tips', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (app.isTestMode)
            TestModeBanner(label: app.demo ? 'DEMO' : 'TEST MODE'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 820;
                final goCard = _GoLiveCard(
                  jarName: jar.displayName,
                  currency: jar.currency,
                  goalController: _goalController,
                  live: live,
                  onStart: _startSession,
                  onReturn: _openLive,
                );
                final linkCard =
                    TipLinkCard(url: jar.url, title: 'Your tip link');
                final recentCard = const _RecentTipsCard();

                if (wide) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  goCard,
                                  const SizedBox(height: 20),
                                  recentCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: linkCard),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    goCard,
                    const SizedBox(height: 20),
                    linkCard,
                    const SizedBox(height: 20),
                    recentCard,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoLiveCard extends ConsumerWidget {
  const _GoLiveCard({
    required this.jarName,
    required this.currency,
    required this.goalController,
    required this.live,
    required this.onStart,
    required this.onReturn,
  });

  final String jarName;
  final String currency;
  final TextEditingController goalController;
  final LiveState? live;
  final VoidCallback onStart;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(liveSessionProvider.notifier);
    final hasStored = live == null && controller.hasStoredSession;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hey, $jarName 👋', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              live != null
                  ? 'A session is running — the stage screen is one tap away.'
                  : 'Set tonight\'s goal and go live when you hit the stage.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (live != null)
              FilledButton.icon(
                onPressed: onReturn,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Return to session · ${formatAmount(live!.session.totalMinor, live!.session.currency)} so far',
                ),
              )
            else ...[
              TextField(
                controller: goalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tonight\'s goal',
                  suffixText: currency.toUpperCase(),
                ),
              ),
              const SizedBox(height: 8),
              const StageQuickSettings(),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.sensors_rounded),
                label: const Text('Start live session'),
              ),
              if (hasStored) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final resumed = await controller.resumeStored();
                          if (resumed && context.mounted) onReturn();
                        },
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Resume interrupted session'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Discard it',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        await controller.discardStored();
                        // hasStored is read in build; poke a rebuild
                        ref.invalidate(liveSessionProvider);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentTipsCard extends ConsumerWidget {
  const _RecentTipsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final app = ref.watch(appStateProvider);
    final recent = ref.watch(recentDonationsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Recent tips', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen()),
                    ),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
            if (app.demo)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Demo mode — start a session to watch pretend fans '
                  'shower you with tips.',
                ),
              )
            else
              recent.when(
                data: (donations) => donations.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No tips yet. Put that QR code where people '
                          'can see it! 🎯',
                        ),
                      )
                    : Column(
                        children: [
                          for (final d in donations)
                            DonationTile(donation: d, dense: true),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5)),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Couldn\'t load recent tips: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
