import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../domain/device_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../venue/venue_intro_screen.dart';
import 'account_step_screen.dart';
import 'onboarding_flow.dart';

/// The first-run pitch — and ONLY that. RootGate shows it when nobody is
/// signed in and nothing is configured anywhere on this device; every other
/// "nothing set up yet" state renders inside the shell instead. That is why
/// there is no profile switcher here any more: there is nothing to switch to,
/// and a screen with no chrome must never be somewhere a user can get stuck.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  /// A device that removed its last profile arrives here with an EMPTY
  /// registry (see AppStateNotifier.removeAccount) — everything past this
  /// screen configures the ACTIVE band, so walking in mints the first one.
  /// A fresh install already got its band from main() and this is a no-op.
  static Future<void> _ensureFirstBand(WidgetRef ref) async {
    if (ref.read(appStateProvider).accounts.isEmpty) {
      await ref.read(appStateProvider.notifier).addAccount();
    }
  }

  /// "Get started" — the performer path. This device is the performer's own
  /// (the overwhelmingly common case), so the old "What is this device?"
  /// question is answered here implicitly and onboarding continues with the
  /// account question (when on offer) or the first band step.
  Future<void> _getStarted(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    // A fresh run: the step counter starts clean.
    await _ensureFirstBand(ref);
    await ref.read(deviceKindProvider.notifier).choose(DeviceKind.performer);
    if (!context.mounted) return;
    final offerSignIn = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available &&
        ref.read(authControllerProvider).user == null;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => offerSignIn
            ? const AccountStepScreen()
            : firstBandSetupScreen(),
      ),
    );
  }

  /// The quiet venue link — a shared device is a different trust decision,
  /// but it is rare enough that it no longer deserves a full onboarding step.
  ///
  /// It ASKS. It does not choose: nothing is written here, and the intro
  /// screen's Continue is the only thing that ever writes the venue kind
  /// (#42). This link used to commit the device and only then explain what it
  /// had done — so the warning's Back arrow (the universal "I've read this, no
  /// thanks") popped into a venue sign-in screen demanding a code, and the one
  /// way back out was a destructive wipe. A question that costs a wipe to
  /// un-ask is not a question. Backing out of the explanation now leaves the
  /// device exactly as it was: unset, on Welcome.
  void _pickVenue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VenueIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final venueAvailable = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available;
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
                            onPressed: () =>
                                unawaited(_getStarted(context, ref)),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            // Demo from Welcome is the same choice as the
                            // demo card on the kind step — record it so the
                            // Settings row can say what this device is.
                            onPressed: () async {
                              await _ensureFirstBand(ref);
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
                          // The venue path is deliberately quiet: a link for
                          // the rare person setting up a shared tablet, not a
                          // choice everyone has to weigh. Hidden entirely
                          // when venue mode can't exist on this platform.
                          if (venueAvailable) ...[
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => _pickVenue(context),
                              child: Text(
                                context.s.t('welcome.venue_link'),
                                style: TextStyle(
                                  fontFamily: kFontBody,
                                  fontSize: 13,
                                  color: c.textMuted,
                                ),
                              ),
                            ),
                          ],
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
