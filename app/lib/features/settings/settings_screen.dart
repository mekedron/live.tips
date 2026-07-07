import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/external_link.dart';

import '../../core/stripe_onboarding.dart';
import '../../core/theme.dart';
import '../../domain/app_settings.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../shell/app_shell.dart';

const _kAppVersion = '0.2.0';

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

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Stripe?'),
        content: const Text(
          'Removes the API key and all local data from this device. '
          'Your Stripe account, payment link, and donations are untouched — '
          'you can reconnect any time.',
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
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appStateProvider.notifier).disconnect();
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
      // ------------------------------------------------------- account ---
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
          header: 'Account',
          children: [
            LtRow(
              icon: Icons.key_rounded,
              title: _maskedKey(app.apiKey),
              subtitle: 'Connected to your Stripe account',
              trailing: StatusPill(
                status:
                    app.isTestMode ? LtKeyStatus.test : LtKeyStatus.live,
                compact: true,
              ),
            ),
            LtRow(
              icon: Icons.link_off_rounded,
              iconColor: c.danger,
              title: 'Disconnect & wipe this device',
              titleColor: c.danger,
              chevron: true,
              onTap: _confirmDisconnect,
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
