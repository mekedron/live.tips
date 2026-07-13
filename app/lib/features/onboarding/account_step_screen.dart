import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../data/firebase/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
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
    // The caller-side gate (see WelcomeScreen) should make this unreachable,
    // but if we do land here without cloud accounts there is nothing to
    // choose — replace ourselves with the local flow's first screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canSignIn = platformSupportsCloudAccounts &&
          ref.read(authControllerProvider.notifier).available;
      if (!canSignIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => firstBandSetupScreen()),
        );
      }
    });
  }

  /// Runs one of the controller's sign-in methods. A null result is a
  /// cancellation or a failure — the sheet stays put and any error renders
  /// inline from the controller state.
  Future<void> _signIn(
    Future<AuthUser?> Function(AuthController) attempt,
  ) async {
    final navigator = Navigator.of(context);
    final user = await attempt(ref.read(authControllerProvider.notifier));
    if (!mounted || user == null) return;
    // A provider that already knows the user's name skips the naming step.
    final unnamed = (user.displayName ?? '').trim().isEmpty;
    navigator.push(
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
    return Scaffold(
      appBar: AppBar(title: Text(context.s.t('onboarding.account_step.title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                context.s.t('onboarding.account_step.heading'),
                style: outfitStyle(22, c.text, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                context.s.t('onboarding.account_step.subtitle'),
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
