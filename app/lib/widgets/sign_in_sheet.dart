import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/firebase/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_providers.dart';

/// Small bottom sheet with just the Apple / Google options — the shared
/// sign-in entry point for the account switcher's "Sign in to another
/// account" row and the Settings sign-in row. Resolves to the signed-in
/// user, or null when dismissed; a failed attempt keeps the sheet up with
/// the error inline. Callers gate on [platformSupportsCloudAccounts] and
/// the controller's `available`.
Future<AuthUser?> showSignInSheet(BuildContext context) {
  return showModalBottomSheet<AuthUser?>(
    context: context,
    builder: (_) => const _SignInSheet(),
  );
}

class _SignInSheet extends ConsumerWidget {
  const _SignInSheet();

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
              onTap: () => _attempt(context, controller.signInWithApple),
            ),
            _ProviderRow(
              leading: Text(
                'G',
                style: outfitStyle(17, c.text, weight: FontWeight.w800),
              ),
              label: context.s.t('widgets.account_switcher.sign_in_google'),
              enabled: !auth.busy,
              onTap: () => _attempt(context, controller.signInWithGoogle),
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
    required this.enabled,
    required this.onTap,
  });

  final Widget leading;
  final String label;
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
                  child: Text(
                    label,
                    style: outfitStyle(15, c.text, weight: FontWeight.w600),
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
