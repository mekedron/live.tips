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
import '../../state/root_world.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../../widgets/profile_switcher.dart';
import '../../widgets/sign_in_sheet.dart';
import '../shell/app_shell.dart';
import 'account_details_screen.dart';
import 'cloud_account_screen.dart';
import 'relay_method_screen.dart';
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
///
/// "Not going anywhere" is true until the artist uses one of the doors in here
/// — sign out is one — and then the root DOES move. Those pushes are
/// [RootBoundRoute]s for exactly that reason: this screen describes the world it
/// was pushed over, so it comes down with it rather than re-rendering against
/// whatever profile the flip left active (#48). The guard below
/// (`app.accountId.isEmpty`) is not that rule and must not be widened into it:
/// after a sign-out the LOCAL profile is active and its id is not empty, which
/// is a perfectly true state — just not the artist's.
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

    final sections = <Widget>[
      // --------------------------------------------------- cloud account ---
      // TWO rows, mirroring the profile group below: who is signed in (a door
      // to everything that edits the ACCOUNT — name, sign-in methods,
      // security, moving local profiles in, sign out — see
      // [CloudAccountScreen]) and the switch. The five account rows that used
      // to sit flat here moved behind the first door, unchanged.
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
            ] else
              // Who is signed in — and the door to editing it. A
              // [RootBoundRoute]: the pushed screen describes THIS account,
              // and its own sign-out row is one of the flips that must take
              // it down (#48).
              LtRow(
                icon: Icons.account_circle_rounded,
                title: accountDisplayName(context, cloudEntry),
                subtitle: [
                  accountProviderLabel(context, cloudEntry.kind),
                  if (cloudEntry.email != null) cloudEntry.email!,
                ].join(' · '),
                chevron: true,
                onTap: () => Navigator.of(context).push(
                  RootBoundRoute(
                    builder: (_) => const CloudAccountScreen(),
                  ),
                ),
              ),
            // The account door — in the ACCOUNT group, opening the ACCOUNT
            // sheet (#49). It stands beside "Switch profile" below, and the two
            // are not a redrawn split: they open two sheets that ask two
            // different questions, in the same shape, under the same rules —
            // and they wear the same icon, so the pair reads as one pattern.
            // Only where there is another account to reach, though: with none,
            // the sheet would hold this device and a sign-in offer the row
            // above it already makes.
            if (!venueMode && directory.accounts.any((a) => !a.isLocal))
              LtRow(
                icon: Icons.swap_horiz_rounded,
                title: s.t('settings.account.switch_title'),
                subtitle: s.t('settings.account.switch_subtitle'),
                chevron: true,
                onTap: () => showAccountSheet(context, ref),
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
              onTap: () => unawaited(_exitDemo()),
            ),
          ],
        )
      else
        // TWO rows, same shape as the account group above: the profile's
        // details (a door — name, currency, thank-you message, and the
        // profile's one, account-wide delete now live inside it, see
        // [AccountDetailsScreen]) and the switch.
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
            // The PROFILE switcher: the profiles of the account in use, and the
            // one way to make another. The accounts are the row in the account
            // group above, and the door at the foot of this sheet — a control
            // never carries a word for a thing it does not do (#49).
            LtRow(
              icon: Icons.swap_horiz_rounded,
              title: s.t('settings.main.switch_profile'),
              subtitle: s.t('settings.main.switch_profile_subtitle'),
              chevron: true,
              onTap: () => showProfileSheet(context, ref),
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
