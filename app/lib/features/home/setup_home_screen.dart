import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/onboarding_draft.dart';
import '../../state/providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../onboarding/onboarding_details_screen.dart';
import '../shell/app_shell.dart';

/// Home for a profile with no payment method yet — the shell's empty state.
///
/// This screen exists so that "nothing set up yet" is a ROOM, not a dead end.
/// It used to be the Welcome pitch, which has no shell around it: no profile
/// switcher, no Settings, no sign-out. A user who signed in mid-onboarding, or
/// backed out of a half-made profile, was stranded there with their other
/// profiles invisible and no way out — a reload changed nothing. Here every
/// escape stays one tap away: the switcher above, Settings in the tab bar.
class SetupHomeScreen extends ConsumerWidget {
  const SetupHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final isRail = AppShellScope.of(context)?.isRail ?? false;
    // "Your other profiles are one tap away" — only where there ARE others.
    final hasOthers =
        ref.watch(appStateProvider.select((s) => s.accounts.length > 1));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isRail ? 40 : 20, isRail ? 36 : 8, isRail ? 40 : 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The switcher lives here too — the way back to the profiles
              // that already work, from the profile that doesn't yet.
              if (!isRail)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: BandNameButton(
                    fontSize: 24,
                    weight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 12),
              LtCard(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 34,
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.s.t('home.setup.title'),
                      textAlign: TextAlign.center,
                      style: outfitStyle(20, c.text, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.s.t('home.setup.body'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 14,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LtPrimaryButton(
                      label: context.s.t('home.setup.action'),
                      trailingIcon: Icons.arrow_forward_rounded,
                      // The same onboarding the switcher's "Add a profile"
                      // runs: details, then method select, then each method.
                      // A band-only run — no account steps in its counter.
                      onPressed: () {
                        ref
                            .read(onboardingPreludeProvider.notifier)
                            .reset();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OnboardingDetailsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (hasOthers) ...[
                const SizedBox(height: 12),
                Text(
                  context.s.t('home.setup.hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: c.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
