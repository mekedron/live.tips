import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../domain/app_account.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/sign_in_sheet.dart';

/// Switching the CLOUD ACCOUNT — every account this device knows, the local
/// "no account" profile included, plus a door to a new sign-in.
///
/// Its own screen on purpose. An account carries a whole set of profiles;
/// swapping it swaps all of them at once, and that is nothing like picking
/// which band you're playing tonight (the profile switcher sheet). Two
/// concepts, two surfaces — mixing them into one list is how a user ends up
/// signing into a second account when they meant to switch bands.
class AccountSwitchScreen extends ConsumerWidget {
  const AccountSwitchScreen({super.key});

  /// Switching the active profile is a DIRECTORY flip — it never ends a
  /// session. An account whose Firebase session is still the live one
  /// (typically the one we just switched away from) is re-entered by flipping
  /// back to it; only an account with no session left needs its provider's
  /// sign-in run again, and on success the auth controller adopts the user.
  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    AppAccount account,
  ) async {
    final navigator = Navigator.of(context);
    final liveUid = ref.read(authControllerProvider).user?.uid;
    if (account.isLocal || account.id == liveUid) {
      await ref.read(accountsDirectoryProvider.notifier).setActive(account.id);
      if (context.mounted) navigator.pop();
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    final user = switch (account.kind) {
      AccountKind.apple => await controller.signInWithApple(),
      AccountKind.google => await controller.signInWithGoogle(),
      // A guest account has no credential: with its session gone there is
      // nothing to sign back in with. That row is disabled (and removable).
      _ => null,
    };
    // Null is a cancel or a failure: stay put, the error renders inline.
    if (user != null && context.mounted) navigator.pop();
  }

  /// Drops a guest account whose session is gone. There is nothing to
  /// recover and nothing to sign back into — the only honest choices are a
  /// dead row forever or this, said bluntly.
  Future<void> _confirmForget(
    BuildContext context,
    WidgetRef ref,
    AppAccount account,
  ) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.account.forget_title')),
        content: Text(s.t('settings.account.forget_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('common.remove')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountsDirectoryProvider.notifier).remove(account.id);
  }

  Future<void> _signInAnother(BuildContext context) async {
    final navigator = Navigator.of(context);
    final user = await showSignInSheet(context);
    if (user != null && context.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    final directory = ref.watch(accountsDirectoryProvider);
    final auth = ref.watch(authControllerProvider);
    final canSignIn = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available;
    // The account whose Firebase session is alive right now — switching
    // profiles doesn't drop it, so it stays reachable without a re-auth.
    final liveUid = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings.account.switch_title'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                s.t('settings.account.switch_intro'),
                style: TextStyle(
                  fontFamily: kFontBody,
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final account in directory.accounts)
                _AccountRow(
                  account: account,
                  active: account.id == directory.activeAccountId,
                  // A live session is re-entered by a directory flip, whatever
                  // the provider. Without one, Apple/Google sign in again —
                  // and a guest account, having no credential, cannot.
                  enabled: !auth.busy &&
                      (account.isLocal ||
                          account.id == liveUid ||
                          (canSignIn &&
                              account.kind != AccountKind.anonymous)),
                  // The only unreachable account there is: a guest whose
                  // session is gone. Offer to forget it rather than keep a
                  // dead row around forever.
                  onForget: account.kind == AccountKind.anonymous &&
                          account.id != liveUid
                      ? () => _confirmForget(context, ref, account)
                      : null,
                  onTap: () => _switchTo(context, ref, account),
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
              if (canSignIn) ...[
                Divider(height: 24, color: c.divider),
                _SignInAnotherRow(
                  enabled: !auth.busy,
                  onTap: () => _signInAnother(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One account: name/email, provider label, and a check when it's the one in
/// use. A guest account whose session is gone is the one unreachable row —
/// disabled, with the reason as subtitle and a way to forget it.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.active,
    required this.enabled,
    required this.onTap,
    this.onForget,
  });

  final AppAccount account;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  /// Set only for an account this device can never enter again.
  final VoidCallback? onForget;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final name = accountDisplayName(context, account);
    final subtitle = active
        ? context.s.t('settings.account.switch_current')
        : onForget != null
            ? context.s.t('widgets.account_switcher.anonymous_locked')
            : (account.email ?? accountProviderLabel(context, account.kind));
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && !active ? onTap : null,
        child: Opacity(
          opacity: enabled || active ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                InitialAvatar(
                  name: account.isLocal ? '' : name,
                  anonymous:
                      account.isLocal || account.kind == AccountKind.anonymous,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: outfitStyle(
                          15,
                          c.text,
                          weight: active ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                LtPill(
                  label: accountProviderLabel(context, account.kind),
                  soft: false,
                ),
                if (active)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.check_circle_rounded,
                        size: 22, color: c.accent),
                  )
                else if (onForget != null)
                  IconButton(
                    onPressed: onForget,
                    tooltip: context.s.t('settings.account.forget_row'),
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 22, color: c.danger),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "+ Sign in to another account" — the door to an account this device has
/// never seen.
class _SignInAnotherRow extends StatelessWidget {
  const _SignInAnotherRow({required this.enabled, required this.onTap});

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  child: Icon(Icons.person_add_alt_rounded,
                      size: 20, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.s.t('widgets.account_switcher.sign_in_another'),
                    style: outfitStyle(15, c.text, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
