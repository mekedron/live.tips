import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/lt_ui.dart';
import 'device_kind_screen.dart';

/// The first-run pitch — and ONLY that. RootGate shows it when nobody is
/// signed in and nothing is configured anywhere on this device; every other
/// "nothing set up yet" state renders inside the shell instead. That is why
/// there is no profile switcher here any more: there is nothing to switch to,
/// and a screen with no chrome must never be somewhere a user can get stuck.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    return Scaffold(
      // The language switcher lives top-right from the very first screen, so a
      // fresh user can pick their language before anything else.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguagePill()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: LayoutBuilder(
              // Scrolls on short screens, spacers breathe on tall ones.
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                              child: Icon(
                                Icons.volunteer_activism,
                                size: 38,
                                color: c.onAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'live.tips',
                            textAlign: TextAlign.center,
                            style: outfitStyle(
                              34,
                              c.text,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.s.t('welcome.tagline'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 16,
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _FeatureCard(
                            icon: Icons.account_balance_rounded,
                            title: context.s.t('welcome.feature_stripe_title'),
                            body: context.s.t('welcome.feature_stripe_body'),
                          ),
                          const SizedBox(height: 12),
                          _FeatureCard(
                            icon: Icons.qr_code_2_rounded,
                            title: context.s.t('welcome.feature_qr_title'),
                            body: context.s.t('welcome.feature_qr_body'),
                          ),
                          const SizedBox(height: 12),
                          _FeatureCard(
                            icon: Icons.celebration_rounded,
                            title: context.s.t('welcome.feature_jar_title'),
                            body: context.s.t('welcome.feature_jar_body'),
                          ),
                          const SizedBox(height: 12),
                          const Spacer(flex: 5),
                          LtPrimaryButton(
                            label: context.s.t('welcome.get_started'),
                            trailingIcon: Icons.arrow_forward_rounded,
                            // The device-kind question comes first — what
                            // this install IS shapes every step after it.
                            // The account question (when on offer) follows
                            // on the performer path.
                            onPressed: () {
                              // A fresh run: the step counter starts clean.
                              ref
                                  .read(onboardingPreludeProvider.notifier)
                                  .reset();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DeviceKindScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            // Demo from Welcome is the same choice as the
                            // demo card on the kind step — record it so the
                            // Settings row can say what this device is.
                            onPressed: () {
                              ref
                                  .read(deviceKindProvider.notifier)
                                  .choose(DeviceKind.demo);
                              ref.read(appStateProvider.notifier).enterDemo();
                            },
                            icon: Icon(
                              Icons.play_circle_outline_rounded,
                              size: 20,
                              color: c.textSecondary,
                            ),
                            label: Text(context.s.t('welcome.try_demo')),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: c.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  context.s.t('welcome.trust'),
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
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: outfitStyle(14.5, c.text)),
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
