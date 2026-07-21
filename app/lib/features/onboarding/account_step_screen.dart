import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../data/firebase/auth_service.dart';
import '../../domain/pending_redirect.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../widgets/lt_ui.dart';
import 'account_name_screen.dart';
import 'onboarding_flow.dart';
import 'profile_pick_screen.dart';

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
      final canSignIn =
          platformSupportsCloudAccounts &&
          ref.read(authControllerProvider.notifier).available;
      final signedIn = ref.read(authControllerProvider).user != null;
      if (!canSignIn || signedIn) _replaceWithSetup();
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
  ///
  /// On the web an Apple/Google sign-in also returns null — the page is leaving
  /// for the provider. Nothing to do here: the flow resumes from
  /// RedirectSignInGate on the way back, which pushes the very same next
  /// screen (naming, or the band setup) that a success below pushes.
  Future<void> _signIn(
    Future<AuthUser?> Function(AuthController) attempt,
  ) async {
    final navigator = Navigator.of(context);
    final user = await attempt(ref.read(authControllerProvider.notifier));
    if (!mounted || user == null) return;
    // A provider that already knows the user's name skips the naming step.
    // Either way the next stop is the profile fork, not band creation: the
    // account that just signed in may already HAVE profiles (a new device,
    // a re-onboarding), and ProfilePickScreen offers them before anything
    // new is minted.
    final unnamed = (user.displayName ?? '').trim().isEmpty;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            unnamed ? const AccountNameScreen() : const ProfilePickScreen(),
      ),
    );
  }

  /// The two weaker answers both cost something the artist cannot see from the
  /// card, so each confirms once against a plain list of what is lost.
  ///
  /// The buttons are deliberately the wrong way round from a normal dialog:
  /// "Sign in instead" is the filled one and it CANCELS. We are not asking a
  /// neutral question — Apple/Google is the answer that keeps their history
  /// recoverable and their notifications working, and the weight of the buttons
  /// should say so. "Continue anyway" is a plain text button, still one tap,
  /// never hidden.
  Future<bool> _confirmDowngrade({
    required String title,
    required List<String> risks,
  }) async {
    final c = context.lt;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final risk in risks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close_rounded, size: 18, color: c.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(risk, style: outfitStyle(14.5, c.text)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: c.textMuted),
            child: Text(context.s.t('onboarding.account_step.risk_proceed')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.s.t('onboarding.account_step.risk_stay')),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  /// An anonymous cloud account syncs and pushes like any other — what it has
  /// no answer for is a lost phone, because nothing out there knows it is them.
  Future<void> _guest() async {
    final ok = await _confirmDowngrade(
      title: context.s.t('onboarding.account_step.guest_confirm_title'),
      risks: [
        context.s.t('onboarding.account_step.guest_risk_device'),
        context.s.t('onboarding.account_step.guest_risk_signin'),
      ],
    );
    if (ok && mounted) await _signIn((a) => a.signInAnonymously());
  }

  /// Today's local flow, untouched: no account, everything on this device.
  ///
  /// Push leads the list because it is the one that surprises people. No account
  /// means no cloud jar, and the whole notification pipeline hangs off that —
  /// the artist does not lose "sync", they lose being told a tip arrived.
  Future<void> _continueWithout() async {
    final ok = await _confirmDowngrade(
      title: context.s.t('onboarding.account_step.offline_confirm_title'),
      risks: [
        context.s.t('onboarding.account_step.offline_risk_push'),
        context.s.t('onboarding.account_step.offline_risk_sync'),
        context.s.t('onboarding.account_step.offline_risk_device'),
      ],
    );
    if (!ok || !mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => firstBandSetupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final auth = ref.watch(authControllerProvider);
    // No step number here, and that is deliberate (see OnboardingStep): the
    // account question is a BRANCH, not a queue. How many screens follow it
    // depends on the answer, on what the provider hands back, and on what the
    // account turns out to hold — so every number this screen ever showed was a
    // guess, and the next screen contradicted it ("Step 1 of 4", then "Step 2
    // of 5"). The counted run starts where its length is known: the setup.
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
                context.s.t('onboarding.account_step.subtitle_profiles'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // The two that actually recover an account get the accent frame
              // and the label saying so. This screen is not a menu of four equal
              // answers — one pair keeps the artist's history reachable from a
              // second phone, the other pair does not, and the page should look
              // like it knows the difference.
              LtSectionLabel(
                context.s.t('onboarding.account_step.recommended'),
                color: c.accent,
              ),
              const SizedBox(height: 8),
              _AccountOption(
                leading: Icon(Icons.apple, size: 22, color: c.text),
                title: context.s.t('onboarding.account_step.apple'),
                enabled: !auth.busy,
                recommended: true,
                onTap: () => _signIn(
                  (a) => a.signInWithApple(origin: RedirectOrigin.onboarding),
                ),
              ),
              const SizedBox(height: 10),
              _AccountOption(
                leading: Text(
                  'G',
                  style: outfitStyle(18, c.text, weight: FontWeight.w800),
                ),
                title: context.s.t('onboarding.account_step.google'),
                enabled: !auth.busy,
                recommended: true,
                onTap: () => _signIn(
                  (a) => a.signInWithGoogle(origin: RedirectOrigin.onboarding),
                ),
              ),
              const SizedBox(height: 18),
              _OrDivider(label: context.s.t('onboarding.account_step.or')),
              const SizedBox(height: 18),
              _AccountOption(
                leading: Icon(
                  Icons.person_outline_rounded,
                  size: 22,
                  color: c.text,
                ),
                title: context.s.t('onboarding.account_step.guest'),
                subtitle: context.s.t('onboarding.account_step.guest_subtitle'),
                enabled: !auth.busy,
                onTap: _guest,
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
              const SizedBox(height: 8),
              // The clearly-secondary escape hatch: keep everything local.
              TextButton(
                onPressed: auth.busy ? null : _continueWithout,
                style: TextButton.styleFrom(foregroundColor: c.textMuted),
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
///
/// [recommended] makes it the dominant card the way the Stripe card is dominant
/// on the method step ([_MethodCard]): the SAME border every card has, but
/// bigger — wider padding, a bigger badge, heavier type, an accent chevron. The
/// accent frame this used to draw was a color the design system does not use for
/// "preferred"; it only ever means "selected". The glyph keeps its own colors
/// either way — Apple's mark and Google's G are not ours to tint.
class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.enabled,
    required this.onTap,
    this.recommended = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      radius: recommended ? 20 : 16,
      padding: EdgeInsets.zero,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: recommended ? 18 : 16,
            vertical: recommended ? 17 : 14,
          ),
          child: Row(
            children: [
              Container(
                width: recommended ? 44 : 40,
                height: recommended ? 44 : 40,
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
                    Text(
                      title,
                      style: outfitStyle(
                        recommended ? 16.5 : 14.5,
                        c.text,
                        weight: recommended ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
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
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: recommended ? c.accent : c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The line that splits the two recommended answers from the two that cost
/// something — a rule with the word "or" sitting in it.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Row(
      children: [
        Expanded(child: Divider(color: c.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 13,
              color: c.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: c.divider, height: 1)),
      ],
    );
  }
}
