import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import 'connect_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: LayoutBuilder(
              // Scrolls on short screens, spacers breathe on tall ones.
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.volunteer_activism, size: 44, color: kGold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'live.tips',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A live tip jar for performers.\nCash is gone — the applause isn\'t.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  const _FeatureRow(
                    icon: Icons.account_balance_rounded,
                    text: 'Tips go straight to your own Stripe account — '
                        'no middleman, no platform cut.',
                  ),
                  const _FeatureRow(
                    icon: Icons.qr_code_2_rounded,
                    text: 'One QR code on stage. Fans scan, tap, done.',
                  ),
                  const _FeatureRow(
                    icon: Icons.celebration_rounded,
                    text: 'Watch tips land live, with a goal bar and confetti.',
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ConnectScreen()),
                    ),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Connect your Stripe account'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(appStateProvider.notifier).enterDemo(),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Try the demo'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Open source · your API key never leaves this device',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: kGold, size: 26),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
