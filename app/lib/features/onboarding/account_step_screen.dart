import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../data/firebase/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/onboarding_draft.dart';
import '../../widgets/lt_ui.dart';
import 'account_name_screen.dart';
import 'onboarding_flow.dart';

/// The account question, asked once, right after Welcome and before any band
/// setup: sign in with Apple or Google, start an anonymous cloud account, or
/// skip the whole thing and stay local like before. Callers only push this
/// when cloud accounts are actually on offer (supported platform, Firebase
/// up, nobody signed in) — but it guards anyway by forwarding straight to
/// the band details when they aren't.
class AccountStepScreen extends ConsumerStatefulWidget {
  const AccountStepScreen({super.key});

  @override
  ConsumerState<AccountStepScreen> createState() => _AccountStepScreenState();
}

class _AccountStepScreenState extends ConsumerState<AccountStepScreen> {
  @override
  void initState() {
    super.initState();
    // Nothing to ask when there is nothing to choose: no cloud accounts on
    // this platform, or the question is already answered because somebody is
    // signed in. The signed-in case is the important one — this step used to
    // keep offering "Continue without an account" to a user who HAD one, and
    // taking it built the profile inside the cloud account anyway.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canSignIn = platformSupportsCloudAccounts &&
          ref.read(authControllerProvider.notifier).available;
      final signedIn = ref.read(authControllerProvider).user != null;
      if (!canSignIn || signedIn) {
        _replaceWithSetup();
        return;
      }
      // Only a screen the user actually sees counts in the step indicator —
      // marking before the auto-skip decision would inflate every flow that
      // never showed this question.
      ref.read(onboardingPreludeProvider.notifier).markAccountStep();
    });
  }

  void _replaceWithSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
    );
  }

  /// Runs one of the controller's sign-in methods. A null result is a
  /// cancellation or a failure — the sheet stays put and any error renders
  /// inline from the controller state.
  ///
  /// A success REPLACES this step: the account question is settled, and going
  /// Back from the details screen must not offer to answer it again.
  Future<void> _signIn(
    Future<AuthUser?> Function(AuthController) attempt,
  ) async {
    final navigator = Navigator.of(context);
    final user = await attempt(ref.read(authControllerProvider.notifier));
    if (!mounted || user == null) return;
    // A provider that already knows the user's name skips the naming step.
    final unnamed = (user.displayName ?? '').trim().isEmpty;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            unnamed ? const AccountNameScreen() : firstBandSetupScreen(),
      ),
    );
  }

  /// Today's local flow, untouched: no account, everything on this device.
  void _continueWithout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final auth = ref.watch(authControllerProvider);
    // This screen is step 1 of the run; the total previews the shortest
    // remaining flow (details + methods + one method), growing as later
    // steps reveal themselves — it never shrinks on the way Back.
    final prelude = ref.watch(onboardingPreludeProvider);
    final total = (prelude < 1 ? 1 : prelude) +
        (ref.watch(onboardingDraftProvider)?.totalSteps ?? 3);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.t('onboarding.account_step.title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: LtPill(
                label: context.s.t('onboarding.account_step.step_pill', {
                  'step': 1,
                  'total': total,
                }),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              LtProgressSegments(total: total, filled: 1),
              const SizedBox(height: 16),
              Text(
                context.s.t('onboarding.account_step.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                context.s.t('onboarding.account_step.subtitle_profiles'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _AccountOption(
                leading: Icon(Icons.apple, size: 22, color: c.text),
                title: context.s.t('onboarding.account_step.apple'),
                enabled: !auth.busy,
                onTap: () => _signIn((a) => a.signInWithApple()),
              ),
              const SizedBox(height: 12),
              _AccountOption(
                leading: Text(
                  'G',
                  style: outfitStyle(18, c.text, weight: FontWeight.w800),
                ),
                title: context.s.t('onboarding.account_step.google'),
                enabled: !auth.busy,
                onTap: () => _signIn((a) => a.signInWithGoogle()),
              ),
              const SizedBox(height: 12),
              _AccountOption(
                leading: Icon(
                  Icons.person_outline_rounded,
                  size: 22,
                  color: c.text,
                ),
                title: context.s.t('onboarding.account_step.guest'),
                subtitle: context.s.t('onboarding.account_step.guest_subtitle'),
                enabled: !auth.busy,
                onTap: () => _signIn((a) => a.signInAnonymously()),
              ),
              if (auth.busy) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ],
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.error!,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13,
                    height: 1.45,
                    color: c.danger,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // The clearly-secondary escape hatch: keep everything local.
              TextButton(
                onPressed: auth.busy ? null : _continueWithout,
                child: Text(context.s.t('onboarding.account_step.skip')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One sign-in choice, styled like the Welcome feature cards but tappable:
/// round soft badge, title (plus optional subtitle), chevron.
class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: 16,
      padding: EdgeInsets.zero,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Padding(
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
                child: leading,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: outfitStyle(14.5, c.text)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
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
              Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
