import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/external_link.dart';

import '../../core/platform_support.dart';
import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../domain/app_account.dart';
import '../../domain/app_settings.dart';
import '../../domain/device_kind.dart';
import '../../domain/tip_method.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../state/venue_providers.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/profile_switcher.dart';
import '../../widgets/sign_in_sheet.dart';
import '../account/cloud_upload_offer.dart';
import '../shell/app_shell.dart';
import '../onboarding/account_name_screen.dart';
import '../venue/venue_reapproval_screen.dart';
import 'account_details_screen.dart';
import 'relay_method_screen.dart';
import 'security_screen.dart';
import 'sign_in_methods_screen.dart';
import 'stripe_key_screen.dart';

/// Settings as a pushed ROUTE, with a Back arrow of its own.
///
/// The shell hangs this screen on a tab, and every door out of a state — sign
/// in, sign out, the sign-in methods, delete account, what this device is, the
/// demo — lives behind it. The band-less roots (RootGate's picker and its
/// create step) have no tab bar to hang anything on, which is how an artist
/// with no profile came to have no Settings at all, and no way back to
/// onboarding (#40). They push this instead: the same screen, over a root that
/// is not going anywhere, so its Back arrow means what it says.
class SettingsRouteScreen extends StatelessWidget {
  const SettingsRouteScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.s.t('settings.main.title'))),
        body: const SettingsScreen(showTitle: false),
      );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.showTitle = true});

  /// The tab draws its own heading; the pushed route puts it in the app bar.
  final bool showTitle;

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

  /// What the dialogs call the account a cloud profile belongs to: the email
  /// if there is one (that is the thing an artist recognizes as "my account"),
  /// else its name, else the provider.
  String _accountLabel(AppAccount profile) =>
      profile.email ?? accountDisplayName(context, profile);

  /// DELETES the profile — from the ACCOUNT, on every device, for good. This
  /// is what the row labelled "Remove this profile from this device" used to
  /// run while promising the opposite (#27), so the dialog says the word
  /// delete, names the account it is deleting from, says "every other device",
  /// and — since a tap can't be taken back — makes the artist type the word.
  ///
  /// The ONLY removal a profile has (#37). A profile is in the account or it is
  /// not; there is no third state in which this device holds fewer of them than
  /// the artist's other phone. An artist walking away from a borrowed tablet
  /// signs the ACCOUNT out — which takes every profile off it, offline, and
  /// deletes nothing.
  Future<void> _confirmDeleteProfile() async {
    // On a venue device, destroying a profile is an account-level act — it
    // needs the same fresh phone approval as switching one.
    if (!await ensureVenueReapproval(context, ref)) return;
    if (!mounted) return;
    final s = context.s;
    final app = ref.read(appStateProvider);
    // A refusal always names itself — and it asks the same guard switch/add/
    // sign-out ask, so a session that died with its tab can no longer wedge
    // this shut.
    if (!accountActionAllowed(context, ref,
        sessionKey: 'settings.main.stop_session_remove_profile')) {
      return;
    }
    final profile = ref.read(accountsDirectoryProvider).active;
    final cloud = !profile.isLocal;
    final hasOthers = app.accounts.length > 1;
    final name = app.displayName.isEmpty
        ? s.t('settings.main.this_profile_fallback')
        : app.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteProfileDialog(
        title: s.t('settings.main.delete_title', {'name': name}),
        body: (cloud
                ? s.t('settings.main.delete_body_cloud',
                    {'name': name, 'account': _accountLabel(profile)})
                : s.t('settings.main.delete_body_local')) +
            (hasOthers ? s.t('settings.main.delete_body_others_suffix') : ''),
        // Type-to-confirm exactly where the act reaches past this device and
        // past this artist's other devices. The local profile's delete is
        // just as permanent, but it destroys only what is in front of you.
        typeToConfirm: cloud,
      ),
    );
    if (confirmed != true) return;
    final removed = await ref
        .read(appStateProvider.notifier)
        .removeAccount(ref.read(appStateProvider).accountId);
    if (!mounted) return;
    if (!removed) {
      // A cloud band's wipe refuses offline rather than half-deleting.
      // Nothing was removed — and a silent no-op would read as a dead
      // button. The snack points at the removal that DOES work offline.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('settings.main.delete_offline_snack'))),
      );
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    // switch/add/sign-out ask, for the same reason: no reshuffling under a
    // live set.
    if (!accountActionAllowed(context, ref,
        sessionKey: 'settings.account.stop_session_move')) {
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
    if (!accountActionAllowed(context, ref,
        sessionKey: 'settings.main.stop_session_remove_profile')) {
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

  /// Backing out of demo play — and the ORDER is the whole of it (#45).
  ///
  /// RootGate re-enters demo whenever the install says demo and the in-memory
  /// flag is off: that is how a demo device comes back after a restart. So the
  /// kind must be gone BEFORE the flag drops — and gone means landed, not sent.
  /// This used to fire the clear and not wait for it, which left a frame in
  /// which the install still said demo and the flag was already false: exactly
  /// the state RootGate answers by putting the artist back into demo, with the
  /// kind then cleared underneath it — a state neither branch describes. On the
  /// web the prefs write finishes in a microtask and usually beats the frame;
  /// on iOS/Android it is a platform-channel round trip that promises nothing.
  /// The comment already knew the rule. It just didn't wait.
  Future<void> _exitDemo() async {
    await ref.read(deviceKindProvider.notifier).clearDemo();
    if (!mounted) return;
    ref.read(appStateProvider.notifier).exitDemo();
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    // Nothing is open: the profile set is empty, or the picker has not been
    // answered yet (RootGate's band-less roots, which push this screen). The
    // profile's own rows would name — and act on — a profile that does not
    // exist, so they stand aside. The switcher stays: it is the door to the
    // profiles and accounts that DO exist, and it is the reason this screen is
    // reachable from there at all (#40).
    final hasProfile = app.accountId.isNotEmpty;
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
                  onTap: () => confirmSignOut(context, ref),
                ),
            ],
            // "Switch account" used to sit here, a second door to a second
            // switcher — one that knew about accounts and nothing about the
            // profiles inside them. There is one switcher now (#29), it is in
            // the profile group below where the artist looks for it, and it
            // lists both. The row is gone rather than aliased: two rows opening
            // the same sheet is the same split, redrawn.
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
              onTap: () => unawaited(_exitDemo()),
            ),
          ],
        )
      else
        LtRowGroup(
          header: s.t('settings.main.profile_details_header'),
          children: [
            if (hasProfile)
              LtRow(
                icon: Icons.badge_rounded,
                title: app.displayName.isEmpty
                    ? s.t('settings.main.your_profile_fallback')
                    : app.displayName,
                subtitle: s.t('settings.main.account_details_subtitle'),
                chevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountDetailsScreen(),
                  ),
                ),
              ),
            // THE switcher — profiles and the accounts they live under, one
            // list, one set of rules (#29).
            LtRow(
              icon: Icons.swap_horiz_rounded,
              title: s.t('settings.main.switch_profile'),
              subtitle: s.t('settings.main.switch_profile_subtitle'),
              chevron: true,
              onTap: () => showSwitcherSheet(context, ref),
            ),
            // ONE removal, and it is account-wide (#37). "Remove from this
            // device" sat here for a few hours and had to go with the model it
            // came from: a profile is in the account or it is not, and it is on
            // every device either way. The artist ending a gig on a borrowed
            // tablet signs the account OUT — offline-safe, and it takes the
            // whole account with it instead of one profile.
            if (hasProfile)
              LtRow(
                icon: Icons.delete_forever_rounded,
                iconColor: c.danger,
                title: s.t('settings.main.delete_profile_row'),
                titleColor: c.danger,
                subtitle: activeProfile.isLocal
                    ? s.t('settings.main.delete_profile_subtitle_local')
                    : s.t('settings.main.delete_profile_subtitle_cloud'),
                chevron: true,
                onTap: _confirmDeleteProfile,
              ),
          ],
        ),
      // ----------------------------------------------- payment methods ---
      if (!app.demo && hasProfile)
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
                if (widget.showTitle) ...[
                  Text(
                    s.t('settings.main.title'),
                    style: outfitStyle(32, c.text, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                ],
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
            if (widget.showTitle)
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

/// The delete confirmation. With [typeToConfirm] the artist has to type the
/// word before the button lights up — the ceremony a cloud profile's delete
/// deserves, because it reaches every device they own and there is nothing
/// anywhere to restore it from. Without it (the local profile) the red button
/// stands alone, as it always has.
class _DeleteProfileDialog extends StatefulWidget {
  const _DeleteProfileDialog({
    required this.title,
    required this.body,
    required this.typeToConfirm,
  });

  final String title;
  final String body;
  final bool typeToConfirm;

  @override
  State<_DeleteProfileDialog> createState() => _DeleteProfileDialogState();
}

class _DeleteProfileDialogState extends State<_DeleteProfileDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final word = s.t('settings.main.delete_confirm_word');
    final armed = !widget.typeToConfirm ||
        _typed.text.trim().toUpperCase() == word.toUpperCase();
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          if (widget.typeToConfirm) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _typed,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText:
                    s.t('settings.main.delete_confirm_hint', {'word': word}),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
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
          onPressed: armed ? () => Navigator.of(context).pop(true) : null,
          child: Text(s.t('common.delete')),
        ),
      ],
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
