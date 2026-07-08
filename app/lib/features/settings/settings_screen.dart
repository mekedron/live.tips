import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/external_link.dart';

import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../domain/app_settings.dart';
import '../../domain/tip_method.dart';
import '../../state/providers.dart';
import '../../widgets/band_switcher.dart';
import '../../widgets/lt_ui.dart';
import '../shell/app_shell.dart';
import 'account_details_screen.dart';
import 'relay_method_screen.dart';
import 'stripe_key_screen.dart';

const _kAppVersion = '0.3.0';

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
    final app = ref.read(appStateProvider);
    if (ref.read(appStateProvider.notifier).accountActionsBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Stop the live session before removing a band.')));
      return;
    }
    final hasOthers = app.accounts.length > 1;
    final name = app.displayName.isEmpty ? 'this band' : app.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $name from this device?'),
        content: Text(
          '${app.hasStripe ? 'Removes the API key and this band\'s local '
              'data. This action can\'t be undone.' : 'Removes this '
              'band\'s live.tips page and local data from this device. '
              'This action can\'t be undone.'}'
          '${hasOthers ? ' Your other bands stay.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(appStateProvider.notifier)
          .removeAccount(ref.read(appStateProvider).accountId);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final app = ref.watch(appStateProvider);
    final settings = app.settings;
    final isRail = AppShellScope.of(context)?.isRail ?? false;

    final sections = <Widget>[
      // ------------------------------------------------ account details ---
      if (app.demo)
        LtRowGroup(
          header: 'Account',
          children: [
            const LtRow(
              icon: Icons.science_rounded,
              title: 'Demo mode',
              subtitle: 'No Stripe account connected',
            ),
            LtRow(
              icon: Icons.logout_rounded,
              title: 'Exit demo',
              chevron: true,
              onTap: () {
                ref.read(appStateProvider.notifier).exitDemo();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        )
      else
        LtRowGroup(
          header: 'Account details',
          children: [
            LtRow(
              icon: Icons.badge_rounded,
              title: app.displayName.isEmpty ? 'Your band' : app.displayName,
              subtitle: 'Name, currency and thank-you message',
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AccountDetailsScreen()),
              ),
            ),
            LtRow(
              icon: Icons.swap_horiz_rounded,
              title: 'Switch account',
              subtitle: 'Work with another band on this device',
              chevron: true,
              onTap: () => showBandSwitcherSheet(context, ref),
            ),
            LtRow(
              icon: Icons.delete_outline_rounded,
              iconColor: c.danger,
              title: 'Remove this account from this device',
              titleColor: c.danger,
              chevron: true,
              onTap: _confirmRemoveBand,
            ),
          ],
        ),
      // ----------------------------------------------- payment methods ---
      if (!app.demo)
        LtRowGroup(
          header: 'Payment methods',
          children: [
            LtRow(
              leading: _MethodStatusDot(
                  icon: Icons.credit_card_rounded, connected: app.hasStripe),
              title: app.hasStripe ? 'Stripe' : 'Add Stripe',
              subtitle: app.hasStripe
                  ? '${_maskedKey(app.apiKey)} — verified card tips'
                  : 'Verified card tips',
              trailing: app.hasStripe
                  ? StatusPill(
                      status:
                          app.isTestMode ? LtKeyStatus.test : LtKeyStatus.live,
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
                  connected: app.relayJar?.hasRevolut ?? false),
              title: 'Revolut',
              subtitle: (app.relayJar?.hasRevolut ?? false)
                  ? '@${app.relayJar!.revolutUsername}'
                  : 'Not set',
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const RelayMethodScreen(method: TipMethod.revolut)),
              ),
            ),
            LtRow(
              leading: _MethodStatusDot(
                  icon: TipMethod.mobilepay.icon,
                  connected: app.relayJar?.hasMobilePay ?? false),
              title: 'MobilePay',
              subtitle: (app.relayJar?.hasMobilePay ?? false)
                  ? 'Box ${_shortBoxId(app.relayJar!.mobilepayBoxId!)}'
                  : 'Not set',
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const RelayMethodScreen(method: TipMethod.mobilepay)),
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
            const LtSectionLabel('Appearance'),
            const SizedBox(height: 10),
            LtSegmented<AppThemeMode>(
              values: AppThemeMode.values,
              selected: settings.themeMode,
              onChanged: (mode) => ref
                  .read(appStateProvider.notifier)
                  .updateSettings(settings.copyWith(themeMode: mode)),
              labelOf: (mode) => switch (mode) {
                AppThemeMode.system => 'Auto',
                AppThemeMode.light => 'Light',
                AppThemeMode.dark => 'Dark',
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
      // The tip jar (link / poster / recreate) and Stage look now live on the
      // Home screen and the stage-look sheet, so Settings no longer repeats them.
      // -------------------------------------------------- live session ---
      LtRowGroup(
        header: 'Live session',
        children: [
          LtRow(
            icon: Icons.speed_rounded,
            title: 'Check for new tips every',
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
                              settings.copyWith(pollIntervalSec: seconds)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // -------------------------------------------------------- footer ---
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              'live.tips v$_kAppVersion · open source — your keys, your money',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: kFontBody, fontSize: 12, color: c.textMuted),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                      textStyle: outfitStyle(12, c.accent)),
                  onPressed: () => openExternal(kProjectUrl),
                  child: const Text('Source code'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      textStyle: outfitStyle(12, c.accent)),
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'live.tips',
                    applicationVersion: _kAppVersion,
                  ),
                  child: const Text('Licenses'),
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
                Text('Settings',
                    style: outfitStyle(32, c.text, weight: FontWeight.w800)),
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
                child: Text('Settings',
                    style: outfitStyle(20, c.text, weight: FontWeight.w700)),
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
            border:
                connected ? null : Border.all(color: c.textFaint, width: 1.5),
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
