import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/external_link.dart';

import '../../core/platform_support.dart';
import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../domain/app_account.dart';
import '../../domain/app_settings.dart';
import '../../domain/device_kind.dart';
import '../../domain/pending_redirect.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/sign_in_sheet.dart';
import '../account/cloud_upload_offer.dart';
import '../shell/app_shell.dart';
import '../onboarding/account_name_screen.dart';
import '../venue/venue_reapproval_screen.dart';
import 'account_details_screen.dart';
import 'account_switch_screen.dart';
import 'relay_method_screen.dart';
import 'security_screen.dart';
import 'sign_in_methods_screen.dart';
import 'stripe_key_screen.dart';

/// What the sign-out dialog resolved to. A guest can also leave by KEEPING
/// the account and giving it a real credential — that is the whole point of
/// offering the link there.
enum _SignOutChoice { cancel, signOut, linkApple, linkGoogle }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _maskedKey(String? key) {
    if (key == null) return '—';
    if (key.length <= 12) return '••••';
    return '${key.substring(0, 8)}…${key.substring(key.length - 4)}';
  }

  /// Box ids are unreadable uuids — show enough to recognize, no more.
  String _shortBoxId(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 8)}…';

  Future<void> _confirmRemoveBand() async {
    // On a venue device, destroying a profile is an account-level act — it
    // needs the same fresh phone approval as switching one.
    if (!await ensureVenueReapproval(context, ref)) return;
    if (!mounted) return;
    final s = context.s;
    final app = ref.read(appStateProvider);
    // A refusal always names itself — and it asks the same guard add/switch
    // ask, so a session that died with its tab can no longer wedge this shut.
    final block = ref.read(appStateProvider.notifier).accountActionBlock;
    if (block != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(block == AccountActionBlock.switching
              ? s.t('widgets.band_switcher.switching')
              : s.t('settings.main.stop_session_remove_profile')),
        ),
      );
      return;
    }
    final hasOthers = app.accounts.length > 1;
    final name = app.displayName.isEmpty
        ? s.t('settings.main.this_profile_fallback')
        : app.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.main.remove_title', {'name': name})),
        content: Text(
          '${app.hasStripe ? s.t('settings.main.remove_profile_body_stripe') : s.t('settings.main.remove_profile_body_relay')}'
          '${hasOthers ? s.t('settings.main.remove_profile_body_others_suffix') : ''}',
        ),
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
    if (confirmed == true) {
      final removed = await ref
          .read(appStateProvider.notifier)
          .removeAccount(ref.read(appStateProvider).accountId);
      if (!mounted) return;
      if (!removed) {
        // A cloud band's wipe refuses offline rather than half-deleting.
        // Nothing was removed — and a silent no-op would read as a dead
        // button.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.t('settings.main.remove_offline_snack'))),
        );
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmSignOut() async {
    final s = context.s;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    // A sign-out is an account flip like any other — refused mid-session,
    // by the same guard add/switch/remove ask. Silently ending an artist's
    // live set from a Settings tap is not an option.
    final block = ref.read(appStateProvider.notifier).accountActionBlock;
    if (block != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(block == AccountActionBlock.switching
              ? s.t('widgets.band_switcher.switching')
              : s.t('settings.account.stop_session_sign_out')),
        ),
      );
      return;
    }
    // Signing out of a guest account destroys it: an anonymous user has no
    // credential to come back with. The dialog says so, and offers the way
    // out that keeps the data — linking a real provider to this same uid.
    final anonymous = user.kind == AccountKind.anonymous;
    final choice = await showDialog<_SignOutChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.account.sign_out_title')),
        content: Text(
          anonymous
              ? s.t('settings.account.sign_out_anonymous_body')
              : s.t('settings.account.sign_out_body_profiles'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_SignOutChoice.cancel),
            child: Text(s.t('common.cancel')),
          ),
          if (anonymous) ...[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_SignOutChoice.linkApple),
              child: Text(s.t('settings.account.link_apple')),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_SignOutChoice.linkGoogle),
              child: Text(s.t('settings.account.link_google')),
            ),
          ],
          FilledButton(
            style: anonymous
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(_SignOutChoice.signOut),
            child: Text(s.t('settings.account.sign_out')),
          ),
        ],
      ),
    );
    final auth = ref.read(authControllerProvider.notifier);
    switch (choice) {
      case _SignOutChoice.signOut:
        await auth.signOut();
      // The guest upgrade. On the web this is linkWithRedirect: the page leaves
      // and the LINK is remembered across the reload (PendingRedirect.link), so
      // the guest's uid — and every band under it — is upgraded in place rather
      // than a second, empty account being signed in beside it.
      case _SignOutChoice.linkApple:
        await auth.signInWithApple(link: true, origin: RedirectOrigin.settings);
      case _SignOutChoice.linkGoogle:
        await auth.signInWithGoogle(
            link: true, origin: RedirectOrigin.settings);
      case _SignOutChoice.cancel:
      case null:
        break;
    }
  }

  /// The permanent home of the local→cloud move. The offer that pops after
  /// a sign-in is a convenience with a memory — it only asks about profiles
  /// it hasn't asked about — so without this row, an account that once said
  /// "Not now" had no way to ever bring those profiles over. Same question,
  /// same dialog, same migrator; the only difference is that the artist
  /// walked up to it.
  Future<void> _confirmMoveLocalProfiles() async {
    final s = context.s;
    // The move ends by switching to the migrated profile — the same guard
    // add/switch/remove ask, for the same reason: no reshuffling under a
    // live set.
    final block = ref.read(appStateProvider.notifier).accountActionBlock;
    if (block != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(block == AccountActionBlock.switching
              ? s.t('widgets.band_switcher.switching')
              : s.t('settings.account.stop_session_move')),
        ),
      );
      return;
    }
    final uid = ref.read(accountsDirectoryProvider).activeAccountId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('account.profile_upload.title')),
        content: Text(s.t('account.profile_upload.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.t('account.profile_upload.accept')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // The account this screen was about must still be the signed-in one —
    // the dialog sat open, and the upload writes into ITS subtree.
    if (ref.read(authControllerProvider).user?.uid != uid) return;
    await runCloudUpload(context, ref, uid);
  }

  /// Changing what this device is wipes it — the dialog says exactly that,
  /// because there is no half-way: data written under one trust model must
  /// not be inherited by another.
  Future<void> _confirmChangeDeviceKind() async {
    final s = context.s;
    final block = ref.read(appStateProvider.notifier).accountActionBlock;
    if (block != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(block == AccountActionBlock.switching
              ? s.t('widgets.band_switcher.switching')
              : s.t('settings.main.stop_session_remove_profile')),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('settings.device_kind.change_title')),
        content: Text(s.t('settings.device_kind.change_body')),
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
            child: Text(s.t('settings.device_kind.change_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deviceKindProvider.notifier).wipeDevice();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final s = context.s;
    final app = ref.watch(appStateProvider);
    final settings = app.settings;
    final isRail = AppShellScope.of(context)?.isRail ?? false;
    final auth = ref.watch(authControllerProvider);
    // Watched so a rename from the naming step refreshes the row.
    final directory = ref.watch(accountsDirectoryProvider);
    // No section at all where cloud accounts can't exist (Windows/Linux,
    // a failed Firebase boot) — local-only stays local-only. Demo hides it
    // too: demo has its own Account group.
    final cloudAvailable = !app.demo &&
        platformSupportsCloudAccounts &&
        ref.read(authControllerProvider.notifier).available;
    // On a public device the ways in and out of accounts live on the venue
    // banner and the sign-in screen, not here: Settings must not offer a
    // door that skips the wipe-and-approve ceremony.
    final venueMode = ref.watch(venueModeActiveProvider);
    final deviceKind = ref.watch(deviceKindProvider);
    // The account this screen is ABOUT is the active profile, not whichever
    // Firebase session happens to be alive: a switch to the local profile
    // leaves the guest session running, and reading the session here made
    // Settings keep showing the account you had just left. Null means the
    // local profile — the sign-in row.
    final activeProfile = directory.active;
    final cloudEntry = activeProfile.isLocal
        ? null
        // A user the directory hasn't caught up with yet (mid sign-in) falls
        // back to what the provider knows.
        : (auth.user != null && auth.user!.uid == activeProfile.id
            ? AppAccount(
                id: auth.user!.uid,
                name: activeProfile.name.isNotEmpty
                    ? activeProfile.name
                    : (auth.user!.displayName ?? ''),
                kind: auth.user!.kind,
                email: auth.user!.email ?? activeProfile.email,
              )
            : activeProfile);
    // Whether this device still holds local profiles worth moving into the
    // signed-in account (named, or holding data — pristine placeholders are
    // noise, not value). Needs the account's OWN session alive: the upload
    // writes into its Firestore subtree.
    final localStore = ref.watch(localStoreProvider);
    final canMoveLocalProfiles = cloudEntry != null &&
        auth.user?.uid == activeProfile.id &&
        ref.watch(cloudUploadRunnerProvider) != null &&
        (localStore.readAccountsRegistry()?.accounts.any((a) =>
                a.name.trim().isNotEmpty ||
                localStore.accountHasData(a.id)) ??
            false);

    final sections = <Widget>[
      // --------------------------------------------------- cloud account ---
      if (cloudAvailable)
        LtRowGroup(
          header: s.t('settings.account.header'),
          children: [
            if (cloudEntry == null) ...[
              if (!venueMode)
                LtRow(
                  icon: Icons.cloud_outlined,
                  title: s.t('settings.account.sign_in_row'),
                  subtitle: s.t('settings.account.sign_in_subtitle_profiles'),
                  chevron: true,
                  onTap: () => showSignInSheet(context),
                ),
            ] else ...[
              // Tappable: an account you can't name is an account you can't
              // tell apart from the next guest one. AuthController.setAccountName
              // existed all along with nothing to call it.
              LtRow(
                icon: Icons.account_circle_rounded,
                title: accountDisplayName(context, cloudEntry),
                subtitle: [
                  accountProviderLabel(context, cloudEntry.kind),
                  if (cloudEntry.email != null) cloudEntry.email!,
                ].join(' · '),
                chevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountNameScreen(rename: true),
                  ),
                ),
              ),
              // The permanent door #32 asked for. Not on a venue device: a
              // shared tablet must not be able to attach an identity to — or
              // delete — the artist's account.
              if (!venueMode)
                LtRow(
                  icon: Icons.key_rounded,
                  title: s.t('settings.sign_in_methods.row_title'),
                  subtitle: cloudEntry.kind == AccountKind.anonymous
                      ? s.t('settings.sign_in_methods.row_subtitle_guest')
                      : s.t('settings.sign_in_methods.row_subtitle'),
                  chevron: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignInMethodsScreen(),
                    ),
                  ),
                ),
              // Not on a venue device: Security can mint add-device codes,
              // and this tablet could confirm its own — anyone holding it
              // could join THEIR phone to the artist's account for good.
              // Devices are managed from the artist's own phone.
              if (!venueMode)
                LtRow(
                  icon: Icons.shield_outlined,
                  title: s.t('settings.security.row_title'),
                  subtitle: s.t('settings.security.row_subtitle'),
                  chevron: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  ),
                ),
              // The way over for a local profile stranded beside this
              // account. Always here while both coexist — the sign-in offer
              // is one-shot per profile, and a dialog that already ran must
              // never be the only door to the migrator.
              if (!venueMode && canMoveLocalProfiles)
                LtRow(
                  icon: Icons.cloud_upload_outlined,
                  title: s.t('settings.account.move_profiles_row'),
                  subtitle: s.t('settings.account.move_profiles_subtitle'),
                  chevron: true,
                  onTap: _confirmMoveLocalProfiles,
                ),
              if (!venueMode)
                LtRow(
                  icon: Icons.logout_rounded,
                  title: s.t('settings.account.sign_out'),
                  subtitle: cloudEntry.kind == AccountKind.anonymous
                      ? s.t('settings.account.sign_out_anonymous_warning')
                      : null,
                  chevron: true,
                  onTap: _confirmSignOut,
                ),
            ],
            // Switching the ACCOUNT is a deliberate, separate act — it swaps
            // every profile at once. It lives here, never in the profile
            // switcher. Shown as soon as there is anywhere else to go.
            if (!venueMode &&
                (cloudEntry != null || directory.accounts.length > 1))
              LtRow(
                icon: Icons.swap_horizontal_circle_outlined,
                title: s.t('settings.account.switch_row'),
                subtitle: s.t('settings.account.switch_subtitle'),
                chevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSwitchScreen(),
                  ),
                ),
              ),
          ],
        ),
      // ------------------------------------------------ account details ---
      if (app.demo)
        LtRowGroup(
          header: s.t('settings.main.demo_header'),
          children: [
            LtRow(
              icon: Icons.science_rounded,
              title: s.t('settings.main.demo_mode'),
              subtitle: s.t('settings.main.demo_no_stripe'),
            ),
            LtRow(
              icon: Icons.logout_rounded,
              title: s.t('settings.main.exit_demo'),
              chevron: true,
              onTap: () {
                // Clear the kind FIRST: RootGate re-enters demo whenever the
                // install says demo but the in-memory flag is off.
                ref.read(deviceKindProvider.notifier).clearDemo();
                ref.read(appStateProvider.notifier).exitDemo();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        )
      else
        LtRowGroup(
          header: s.t('settings.main.profile_details_header'),
          children: [
            LtRow(
              icon: Icons.badge_rounded,
              title: app.displayName.isEmpty
                  ? s.t('settings.main.your_profile_fallback')
                  : app.displayName,
              subtitle: s.t('settings.main.account_details_subtitle'),
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountDetailsScreen()),
              ),
            ),
            LtRow(
              icon: Icons.swap_horiz_rounded,
              title: s.t('settings.main.switch_profile'),
              subtitle: s.t('settings.main.switch_profile_subtitle'),
              chevron: true,
              onTap: () => showBandSwitcherSheet(context, ref),
            ),
            LtRow(
              icon: Icons.delete_outline_rounded,
              iconColor: c.danger,
              title: s.t('settings.main.remove_profile_row'),
              titleColor: c.danger,
              chevron: true,
              onTap: _confirmRemoveBand,
            ),
          ],
        ),
      // ----------------------------------------------- payment methods ---
      if (!app.demo)
        LtRowGroup(
          header: s.t('settings.main.payment_methods_header'),
          children: [
            LtRow(
              leading: _MethodStatusDot(
                icon: Icons.credit_card_rounded,
                connected: app.hasStripe,
              ),
              title: app.hasStripe ? 'Stripe' : s.t('settings.main.add_stripe'),
              subtitle: app.hasStripe
                  ? s.t('settings.main.stripe_connected_subtitle', {
                      'key': _maskedKey(app.apiKey),
                    })
                  : s.t('settings.main.stripe_add_subtitle'),
              trailing: app.hasStripe
                  ? StatusPill(
                      status: app.isTestMode
                          ? LtKeyStatus.test
                          : LtKeyStatus.live,
                      compact: true,
                    )
                  : null,
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StripeKeyScreen()),
              ),
            ),
            LtRow(
              leading: _MethodStatusDot(
                icon: TipMethod.revolut.icon,
                connected: app.relayJar?.hasRevolut ?? false,
              ),
              title: 'Revolut',
              subtitle: (app.relayJar?.hasRevolut ?? false)
                  ? '@${app.relayJar!.revolutUsername}'
                  : s.t('settings.main.not_set'),
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const RelayMethodScreen(method: TipMethod.revolut),
                ),
              ),
            ),
            LtRow(
              leading: _MethodStatusDot(
                icon: TipMethod.mobilepay.icon,
                connected: app.relayJar?.hasMobilePay ?? false,
              ),
              title: 'MobilePay',
              subtitle: (app.relayJar?.hasMobilePay ?? false)
                  ? s.t('settings.main.box', {
                      'id': _shortBoxId(app.relayJar!.mobilepayBoxId!),
                    })
                  : s.t('settings.main.not_set'),
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const RelayMethodScreen(method: TipMethod.mobilepay),
                ),
              ),
            ),
            LtRow(
              leading: _MethodStatusDot(
                icon: TipMethod.monzo.icon,
                connected: app.relayJar?.hasMonzo ?? false,
              ),
              title: 'Monzo',
              subtitle: (app.relayJar?.hasMonzo ?? false)
                  ? '@${app.relayJar!.monzoUsername}'
                  : s.t('settings.main.not_set'),
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const RelayMethodScreen(method: TipMethod.monzo),
                ),
              ),
            ),
          ],
        ),
      // ---------------------------------------------------- appearance ---
      LtCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LtSectionLabel(s.t('settings.main.appearance')),
            const SizedBox(height: 10),
            LtSegmented<AppThemeMode>(
              values: AppThemeMode.values,
              selected: settings.themeMode,
              onChanged: (mode) => ref
                  .read(appStateProvider.notifier)
                  .updateSettings(settings.copyWith(themeMode: mode)),
              labelOf: (mode) => switch (mode) {
                AppThemeMode.system => s.t('settings.main.theme_auto'),
                AppThemeMode.light => s.t('settings.main.theme_light'),
                AppThemeMode.dark => s.t('settings.main.theme_dark'),
              },
              iconOf: (mode) => switch (mode) {
                AppThemeMode.system => Icons.brightness_auto_rounded,
                AppThemeMode.light => Icons.light_mode_rounded,
                AppThemeMode.dark => Icons.dark_mode_rounded,
              },
            ),
          ],
        ),
      ),
      // ------------------------------------------------------ language ---
      LtRowGroup(
        header: s.t('settings.language.header'),
        children: [
          LtRow(
            icon: Icons.language_rounded,
            title:
                '${activeAppLocale(context).flag}  ${activeAppLocale(context).name}',
            subtitle: s.t('settings.language.row_subtitle'),
            chevron: true,
            onTap: () => showLanguageSheet(context, ref),
          ),
        ],
      ),
      // The tip jar (link / poster / recreate) and Stage look now live on the
      // Home screen and the stage-look sheet, so Settings no longer repeats them.
      // -------------------------------------------------- live session ---
      LtRowGroup(
        header: s.t('settings.main.live_session_header'),
        children: [
          LtRow(
            icon: Icons.speed_rounded,
            title: s.t('settings.main.poll_interval'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final seconds in const [2, 4, 8, 15])
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _IntervalChip(
                      label: '${seconds}s',
                      selected: settings.pollIntervalSec == seconds,
                      onTap: () => ref
                          .read(appStateProvider.notifier)
                          .updateSettings(
                            settings.copyWith(pollIntervalSec: seconds),
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // --------------------------------------------------- this device ---
      LtRowGroup(
        header: s.t('settings.device_kind.header'),
        children: [
          LtRow(
            icon: switch (deviceKind) {
              DeviceKind.venue => Icons.storefront_rounded,
              DeviceKind.demo => Icons.play_circle_outline_rounded,
              _ => Icons.mic_external_on_rounded,
            },
            title: switch (deviceKind) {
              DeviceKind.venue => s.t('settings.device_kind.current_venue'),
              DeviceKind.demo => s.t('settings.device_kind.current_demo'),
              _ => s.t('settings.device_kind.current_performer'),
            },
            subtitle: s.t('settings.device_kind.row_subtitle'),
            chevron: true,
            onTap: _confirmChangeDeviceKind,
          ),
        ],
      ),
      // -------------------------------------------------------- footer ---
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              s.t('settings.main.footer_tagline'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12,
                color: c.textMuted,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: outfitStyle(12, c.accent),
                  ),
                  onPressed: () => openExternal(kProjectUrl),
                  child: Text(s.t('settings.main.source_code')),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: outfitStyle(12, c.accent),
                  ),
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'live.tips',
                  ),
                  child: Text(s.t('settings.main.licenses')),
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    if (isRail) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.t('settings.main.title'),
                  style: outfitStyle(32, c.text, weight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                for (final section in sections) ...[
                  section,
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.t('settings.main.title'),
                  style: outfitStyle(20, c.text, weight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final section in sections) ...[
              section,
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// A payment-method row's leading cluster: a small status dot (green when the
/// method is connected/configured, a hollow ring when not) followed by the
/// method's icon — the at-a-glance "is this hooked up?" indicator.
class _MethodStatusDot extends StatelessWidget {
  const _MethodStatusDot({required this.icon, required this.connected});

  final IconData icon;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: connected ? c.success : Colors.transparent,
            shape: BoxShape.circle,
            border: connected
                ? null
                : Border.all(color: c.textFaint, width: 1.5),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 22, color: c.textSecondary),
      ],
    );
  }
}

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Material(
      color: selected ? c.accent : c.chip,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: outfitStyle(12, selected ? c.onAccent : c.textSecondary),
          ),
        ),
      ),
    );
  }
}
