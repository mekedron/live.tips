import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/install_prompt.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import 'connect_screen.dart';
import 'install_hint_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 6),
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.accent.withValues(alpha: 0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.volunteer_activism,
                                  size: 38, color: c.onAccent),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'live.tips',
                            textAlign: TextAlign.center,
                            style: outfitStyle(34, c.text,
                                weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your live tip jar.\nOn stage in minutes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 16,
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _FeatureCard(
                            icon: Icons.account_balance_rounded,
                            title: 'Straight to your Stripe',
                            body: 'No middleman, no platform cut — tips land '
                                'in your own account.',
                          ),
                          const SizedBox(height: 12),
                          const _FeatureCard(
                            icon: Icons.qr_code_2_rounded,
                            title: 'One QR on stage',
                            body: 'Fans scan, pick an amount, leave a name '
                                'and a message.',
                          ),
                          const SizedBox(height: 12),
                          const _FeatureCard(
                            icon: Icons.celebration_rounded,
                            title: 'A jar that fills live',
                            body: 'Watch your 3D jar fill toward tonight\'s '
                                'goal, tip by tip.',
                          ),
                          const Spacer(flex: 5),
                          LtPrimaryButton(
                            label: 'Connect your Stripe account',
                            trailingIcon: Icons.arrow_forward_rounded,
                            // Phones and tablets in a browser get the one-time
                            // "Add to Home Screen" nudge first; desktop and the
                            // installed PWA go straight to connecting.
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => shouldSuggestInstall
                                    ? const InstallHintScreen()
                                    : const ConnectScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.read(appStateProvider.notifier).enterDemo(),
                            icon: Icon(Icons.play_circle_outline_rounded,
                                size: 20, color: c.textSecondary),
                            label: const Text('Try the demo'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 14, color: c.textMuted),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Open source · your key never leaves this device',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: kFontBody,
                                    fontSize: 12,
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                            ],
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: outfitStyle(14.5, c.text)),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13,
                    height: 1.4,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
