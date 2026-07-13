import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/firebase/auth_service.dart';
import '../domain/pending_redirect.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_providers.dart';

/// The shared sign-in entry point: the account switcher's "Sign in to another
/// account" row and the Settings sign-in row. It offers the same three doors
/// as the first-run account step — Apple, Google, and a guest account. The
/// guest one belongs here too: a local-profile artist who skipped the account
/// question at first run had no way to answer it later, and "the cloud, but
/// without an identity" was reachable exactly once in the app's life.
///
/// Resolves to the signed-in user, or null when dismissed; a failed attempt
/// keeps the sheet up with the error inline. Callers gate on
/// [platformSupportsCloudAccounts] and the controller's `available`.
///
/// On the web an Apple/Google choice never resolves to a user here: the page
/// leaves for the provider and the sheet dies with it. The sign-in completes on
/// the way back (RedirectSignInGate), which lands the user on [origin].
Future<AuthUser?> showSignInSheet(
  BuildContext context, {
  RedirectOrigin origin = RedirectOrigin.settings,
}) {
  return showModalBottomSheet<AuthUser?>(
    context: context,
    builder: (_) => _SignInSheet(origin: origin),
  );
}

class _SignInSheet extends ConsumerWidget {
  const _SignInSheet({required this.origin});

  final RedirectOrigin origin;

  Future<void> _attempt(
    BuildContext context,
    Future<AuthUser?> Function() run,
  ) async {
    final navigator = Navigator.of(context);
    final user = await run();
    // Pop only on success — a cancellation or error leaves the sheet up
    // (the error renders inline under the options).
    if (user != null && context.mounted) navigator.pop(user);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                context.s.t('widgets.account_switcher.sign_in_title'),
                style: outfitStyle(18, c.text, weight: FontWeight.w700),
              ),
            ),
            _ProviderRow(
              leading: Icon(Icons.apple, size: 22, color: c.text),
              label: context.s.t('widgets.account_switcher.sign_in_apple'),
              enabled: !auth.busy,
              onTap: () => _attempt(
                  context, () => controller.signInWithApple(origin: origin)),
            ),
            _ProviderRow(
              leading: Text(
                'G',
                style: outfitStyle(17, c.text, weight: FontWeight.w800),
              ),
              label: context.s.t('widgets.account_switcher.sign_in_google'),
              enabled: !auth.busy,
              onTap: () => _attempt(
                  context, () => controller.signInWithGoogle(origin: origin)),
            ),
            _ProviderRow(
              leading: Icon(Icons.person_outline_rounded, size: 22, color: c.text),
              label: context.s.t('onboarding.account_step.guest'),
              subtitle: context.s.t('onboarding.account_step.guest_subtitle'),
              enabled: !auth.busy,
              onTap: () => _attempt(context, controller.signInAnonymously),
            ),
            if (auth.busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  auth.error!,
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    height: 1.45,
                    color: c.danger,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One sign-in option in the sheet: round soft badge + label.
class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.leading,
    required this.label,
    this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: leading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: outfitStyle(15, c.text, weight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 12.5,
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
      ),
    );
  }
}
