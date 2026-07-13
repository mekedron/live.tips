import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform_support.dart';
import '../core/theme.dart';
import '../domain/app_account.dart';
import '../domain/band_account.dart';
import '../features/onboarding/onboarding_details_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_providers.dart';
import '../state/live_session_controller.dart';
import '../state/providers.dart';
import 'lt_ui.dart';
import 'sign_in_sheet.dart';

/// The switcher/settings label for a profile's auth provider.
String accountProviderLabel(BuildContext context, AccountKind kind) =>
    switch (kind) {
      AccountKind.local =>
        context.s.t('widgets.account_switcher.provider_local'),
      AccountKind.anonymous =>
        context.s.t('widgets.account_switcher.provider_anonymous'),
      AccountKind.apple =>
        context.s.t('widgets.account_switcher.provider_apple'),
      AccountKind.google =>
        context.s.t('widgets.account_switcher.provider_google'),
    };

/// What a profile calls itself: the chosen account name, else the email,
/// else the provider label — and the local profile is always "On this
/// device".
String accountDisplayName(BuildContext context, AppAccount account) {
  if (account.isLocal) {
    return context.s.t('widgets.account_switcher.on_this_device');
  }
  if (account.name.trim().isNotEmpty) return account.name;
  return account.email ?? accountProviderLabel(context, account.kind);
}

/// The label under a band row: which payment methods it has configured,
/// read straight from the band's stored jars (cheap prefs lookups).
String bandMethodsSummary(
  BuildContext context,
  WidgetRef ref,
  String accountId,
) {
  final repo = ref.read(accountDataRepositoryProvider);
  final tipJar = repo.readTipJar(accountId);
  final relayJar = repo.readRelayJar(accountId);
  final methods = <String>[
    if (tipJar != null) 'Stripe',
    if (relayJar?.hasRevolut ?? false) 'Revolut',
    if (relayJar?.hasMobilePay ?? false) 'MobilePay',
    if (relayJar?.hasMonzo ?? false) 'Monzo',
  ];
  return methods.isEmpty
      ? context.s.t('widgets.band_switcher.not_set_up')
      : methods.join(' · ');
}

/// The band name as a tap target with a chevron — tapping opens the
/// switcher sheet. Used in the home headers; [compact] renders the smaller
/// chip used on the side rail, welcome, and jar setup.
class BandNameButton extends ConsumerWidget {
  const BandNameButton({
    super.key,
    required this.fontSize,
    required this.weight,
  });

  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final style = outfitStyle(fontSize, c.text, weight: weight);
    final name = app.displayName.isEmpty
        ? context.s.t('widgets.band_switcher.your_account')
        : app.displayName;
    // Demo has no real band to switch unless others already exist — the
    // escape hatch back to a real band must stay reachable.
    if (app.demo && app.accounts.length < 2) {
      return Text(name, style: style);
    }
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: InkWell(
        onTap: () => showBandSwitcherSheet(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Text.rich(
          TextSpan(
            text: name,
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: fontSize * 0.8,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
          style: style,
        ),
      ),
    );
  }
}

/// Small pill naming the active band, opening the switcher — for surfaces
/// outside the home header (side rail, welcome, jar setup).
class BandChip extends ConsumerWidget {
  const BandChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final name = app.displayName.isEmpty
        ? context.s.t('widgets.band_switcher.new_account')
        : app.displayName;
    return Material(
      color: c.chip,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showBandSwitcherSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_rounded, size: 15, color: c.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: outfitStyle(
                    13,
                    c.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 16, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The switcher: every band on this device plus "Add a band". Switching is
/// blocked (rows greyed, hint shown) while a live session runs — a session
/// is bound to its band's key and relay socket.
Future<void> showBandSwitcherSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _BandSwitcherSheet(),
  );
}

class _BandSwitcherSheet extends ConsumerWidget {
  const _BandSwitcherSheet();

  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    BandAccount account,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(appStateProvider.notifier);
    final app = ref.read(appStateProvider);
    final stopSessionMsg = context.s.t(
      'widgets.band_switcher.stop_session_switch',
    );

    // Leaving a half-finished new account behind — one that was named on the
    // details step but never got a payment method, and holds no data? It has
    // no home in the app (RootGate parks it on Welcome), and no way to remove
    // it short of finishing onboarding. Offer to discard it on the way out.
    final leavingId = app.accountId;
    final abandoning =
        account.id != leavingId &&
        !app.connected &&
        !ref.read(accountDataRepositoryProvider).accountHasData(leavingId);
    if (abandoning) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.s.t('widgets.band_switcher.discard_title')),
          content: Text(context.s.t('widgets.band_switcher.discard_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.s.t('widgets.band_switcher.keep_editing')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.s.t('widgets.band_switcher.discard_switch')),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }

    final ok = await notifier.switchAccount(account.id);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(stopSessionMsg)));
      return;
    }
    // The unfinished account is no longer active — remove it now that we've
    // landed safely on the chosen one.
    if (abandoning) await notifier.removeAccount(leavingId);
    // Only close the sheet if it is still up — the user may have swiped it
    // away during the keychain read, and popping then would eat whatever
    // route sits underneath.
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _addBand(BuildContext context, WidgetRef ref) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final account = await ref.read(appStateProvider.notifier).addAccount();
    if (account == null) return;
    if (context.mounted) Navigator.of(context).pop();
    // The new empty band is active now; the details step starts its
    // onboarding, and RootGate (welcome, behind this route) is the fallback
    // if the user backs out.
    rootNavigator.push(
      MaterialPageRoute(builder: (_) => const OnboardingDetailsScreen()),
    );
  }

  /// Switches to another PROFILE (an accounts-directory entry, not a band).
  /// The local profile flips instantly; a cloud profile needs a fresh
  /// session, so its provider's sign-in runs again — on success the auth
  /// controller adopts the user and makes it active.
  Future<void> _switchProfile(
    BuildContext context,
    WidgetRef ref,
    AppAccount account,
  ) async {
    if (account.isLocal) {
      await ref
          .read(accountsDirectoryProvider.notifier)
          .setActive(kLocalAccountId);
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    final user = switch (account.kind) {
      AccountKind.apple => await controller.signInWithApple(),
      AccountKind.google => await controller.signInWithGoogle(),
      // Anonymous rows are disabled — once signed out there is no way back
      // into a guest account.
      _ => null,
    };
    // Null is a cancel or failure: stay put, the error renders inline.
    if (user != null && context.mounted) Navigator.of(context).pop();
  }

  /// "+ Sign in to another account" — the shared Apple/Google sheet; a
  /// successful sign-in makes the new account active, so the switcher
  /// underneath has nothing left to say and dismisses too.
  Future<void> _signInAnother(BuildContext context) async {
    final navigator = Navigator.of(context);
    final user = await showSignInSheet(context);
    if (user != null && context.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final live = ref.watch(liveSessionProvider);
    final directory = ref.watch(accountsDirectoryProvider);
    final auth = ref.watch(authControllerProvider);
    final blocked = live != null || app.switching;
    // Cloud rows only make sense where a sign-in could actually run.
    final canSignIn = platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available;
    final others = [
      for (final account in directory.accounts)
        if (account.id != directory.activeAccountId) account,
    ];

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
                context.s.t('widgets.band_switcher.title'),
                style: outfitStyle(18, c.text, weight: FontWeight.w700),
              ),
            ),
            // Which PROFILE these bands live under: the local device
            // profile or a signed-in cloud account.
            _ActiveProfileHeader(profile: directory.active),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Text(
                  live != null
                      ? context.s.t('widgets.band_switcher.live_running_hint')
                      : context.s.t('widgets.band_switcher.switching'),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12.5,
                    color: c.textMuted,
                  ),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final account in app.accounts)
                    _BandRow(
                      account: account,
                      active: !app.demo && account.id == app.accountId,
                      enabled: !blocked,
                      onTap: () => _switchTo(context, ref, account),
                    ),
                ],
              ),
            ),
            Divider(height: 16, color: c.divider),
            _AddBandRow(enabled: !blocked, onTap: () => _addBand(context, ref)),
            // ------------------------------------------ other profiles ---
            if (others.isNotEmpty || canSignIn) ...[
              Divider(height: 16, color: c.divider),
              if (others.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                  child: LtSectionLabel(
                    context.s.t('widgets.account_switcher.other_accounts'),
                  ),
                ),
              for (final account in others)
                _ProfileRow(
                  account: account,
                  // A signed-out guest account can never be re-entered; a
                  // cloud account needs its provider, so it needs [canSignIn].
                  enabled: !blocked &&
                      !auth.busy &&
                      (account.isLocal ||
                          (canSignIn &&
                              account.kind != AccountKind.anonymous)),
                  onTap: () => _switchProfile(context, ref, account),
                ),
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
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
              if (canSignIn)
                _SignInAnotherRow(
                  enabled: !blocked && !auth.busy,
                  onTap: () => _signInAnother(context),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The sheet's subheader: the active profile's name plus a small provider
/// pill — so "whose bands am I looking at" answers itself.
class _ActiveProfileHeader extends StatelessWidget {
  const _ActiveProfileHeader({required this.profile});

  final AppAccount profile;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: [
          Icon(
            profile.isLocal ? Icons.smartphone_rounded : Icons.cloud_rounded,
            size: 16,
            color: c.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              accountDisplayName(context, profile),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: outfitStyle(13.5, c.textSecondary, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          LtPill(
            label: accountProviderLabel(context, profile.kind),
            soft: false,
          ),
        ],
      ),
    );
  }
}

/// A collapsed non-active profile: name/email plus provider label. Cloud
/// rows re-authenticate on tap; signed-out guest accounts stay disabled
/// with the reason as their subtitle.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.account,
    required this.enabled,
    required this.onTap,
  });

  final AppAccount account;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final name = accountDisplayName(context, account);
    final subtitle = account.kind == AccountKind.anonymous
        ? context.s.t('widgets.account_switcher.anonymous_locked')
        : (account.email ?? accountProviderLabel(context, account.kind));
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
                InitialAvatar(
                  name: account.isLocal ? '' : name,
                  anonymous: account.isLocal ||
                      account.kind == AccountKind.anonymous,
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
                        style: outfitStyle(15, c.text, weight: FontWeight.w600),
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
                Icon(Icons.chevron_right_rounded, size: 22, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "+ Sign in to another account" — mirrors [_AddBandRow]'s look.
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

class _BandRow extends ConsumerWidget {
  const _BandRow({
    required this.account,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final BandAccount account;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final name = account.name.isEmpty
        ? context.s.t('widgets.band_switcher.unnamed_account')
        : account.name;
    final subtitle = bandMethodsSummary(context, ref, account.id);
    final dim = enabled ? 1.0 : 0.45;
    return Material(
      color: active ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && !active ? onTap : null,
        child: Opacity(
          opacity: dim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                InitialAvatar(
                  name: name,
                  anonymous: account.name.isEmpty,
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
                if (active)
                  Icon(Icons.check_circle_rounded, size: 22, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBandRow extends StatelessWidget {
  const _AddBandRow({required this.enabled, required this.onTap});

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
                  child: Icon(Icons.add_rounded, size: 22, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.s.t('widgets.band_switcher.add_account'),
                        style: outfitStyle(15, c.text, weight: FontWeight.w600),
                      ),
                      Text(
                        context.s.t(
                          'widgets.band_switcher.add_account_subtitle',
                        ),
                        style: TextStyle(
                          fontFamily: kFontBody,
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
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
