import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_support.dart';
import '../../core/theme.dart';
import '../../domain/app_account.dart';
import '../../domain/pending_redirect.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
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
///
/// ALWAYS a pushed route, never RootGate's landing — and that is a rule, not
/// an accident. It used to be the root for "the local profile has no bands
/// left", which made the one screen a tap on the local row could reach the
/// very screen the tap came from: the flip rebuilt the root as this list, the
/// pushed copy popped into it, and the artist was back where they started with
/// the row now checked and dead (#38). An empty profile set now lands on the
/// create step like every other empty profile set, so the pop below can never
/// arrive at a rebuild of this widget — [Navigator.canPop] is the whole guard
/// it needs.
class AccountSwitchScreen extends ConsumerWidget {
  const AccountSwitchScreen({super.key});

  /// Switching the active profile is a DIRECTORY flip — it never ends a
  /// session, so it is REFUSED while one runs, with the same guard and the
  /// same kind of message as the band switcher. (The old asymmetry — bands
  /// blocked, accounts didn't — is how a flip landed under a live set and
  /// left the app rendering the account it had just left.) Every account
  /// whose own FirebaseApp session is alive (see AccountSessions) is one tap
  /// away, no re-auth; only an account whose session is gone needs its
  /// provider's sign-in run again, and on success the auth controller adopts
  /// the user.
  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    AppAccount account,
  ) async {
    final block = ref.read(appStateProvider.notifier).accountActionBlock;
    if (block != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(block == AccountActionBlock.switching
            ? context.s.t('widgets.band_switcher.switching')
            : context.s.t('settings.account.stop_session_switch')),
      ));
      return;
    }
    final navigator = Navigator.of(context);
    final liveUid = ref.read(authControllerProvider).user?.uid;
    final sessions = ref.read(accountSessionsProvider);
    if (account.isLocal ||
        account.id == liveUid ||
        sessions.isAlive(account.id)) {
      await ref.read(accountsDirectoryProvider.notifier).setActive(account.id);
      if (context.mounted && navigator.canPop()) navigator.pop();
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    // On the web this leaves the page for the provider and returns null; the
    // sign-in finishes on the way back and lands on Settings (RedirectOrigin).
    final user = switch (account.kind) {
      AccountKind.apple =>
        await controller.signInWithApple(origin: RedirectOrigin.settings),
      AccountKind.google =>
        await controller.signInWithGoogle(origin: RedirectOrigin.settings),
      // A guest account has no credential: with its session gone there is
      // nothing to sign back in with. That row is disabled (and removable).
      _ => null,
    };
    // Null is a cancel or a failure: stay put, the error renders inline.
    if (user != null && context.mounted && navigator.canPop()) {
      navigator.pop();
    }
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
    if (user != null && context.mounted && navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final s = context.s;
    final directory = ref.watch(accountsDirectoryProvider);
    final auth = ref.watch(authControllerProvider);
    final canSignIn = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available;
    // Sessions live in their own FirebaseApp instances — every one of them
    // stays reachable without a re-auth, not just the one in the foreground.
    final sessions = ref.watch(accountSessionsProvider);
    ref.watch(accountSessionsChangesProvider);
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
                  sessionAlive: account.id == liveUid ||
                      sessions.isAlive(account.id),
                  enabled: !auth.busy &&
                      (account.isLocal ||
                          account.id == liveUid ||
                          sessions.isAlive(account.id) ||
                          (canSignIn &&
                              account.kind != AccountKind.anonymous)),
                  // The only unreachable account there is: a guest whose
                  // session is gone. Offer to forget it rather than keep a
                  // dead row around forever.
                  onForget: account.kind == AccountKind.anonymous &&
                          account.id != liveUid &&
                          !sessions.isAlive(account.id)
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
    this.sessionAlive = false,
    this.onForget,
  });

  final AppAccount account;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  /// Whether this account's own session is alive on the device — one tap
  /// re-enters it; a dead session means the provider sign-in runs again.
  final bool sessionAlive;

  final VoidCallback? onForget;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final name = accountDisplayName(context, account);
    final subtitle = active
        ? context.s.t('settings.account.switch_current')
        : onForget != null
            ? context.s.t('widgets.account_switcher.anonymous_locked')
            : account.isLocal
                ? (account.email ??
                    accountProviderLabel(context, account.kind))
                : sessionAlive
                    ? context.s.t('settings.account.session_alive')
                    : context.s.t('settings.account.session_gone');
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
