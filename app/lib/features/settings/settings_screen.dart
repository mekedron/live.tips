import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/stripe_onboarding.dart';
import '../../domain/app_settings.dart';
import '../../state/providers.dart';
import '../lock/lock_service.dart';
import '../setup/jar_setup_screen.dart';
import 'stage_settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasPin = false;
  bool _deviceAuthAvailable = false;

  @override
  void initState() {
    super.initState();
    _refreshLockInfo();
  }

  Future<void> _refreshLockInfo() async {
    final hasPin = await ref.read(secureStoreProvider).hasPin();
    final deviceAuth = await ref
        .read(lockServiceProvider)
        .deviceAuthAvailable();
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _deviceAuthAvailable = deviceAuth;
      });
    }
  }

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
    final theme = Theme.of(context);
    final app = ref.watch(appStateProvider);
    final jar = app.effectiveTipJar;
    final settings = app.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader('Account'),
              if (app.demo) ...[
                const ListTile(
                  leading: Icon(Icons.science_rounded),
                  title: Text('Demo mode'),
                  subtitle: Text('No Stripe account connected'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Exit demo'),
                  onTap: () {
                    ref.read(appStateProvider.notifier).exitDemo();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.key_rounded),
                  title: Text(_maskedKey(app.apiKey)),
                  subtitle: Text(
                    app.isTestMode
                        ? 'Test mode key — payments simulated'
                        : 'Live mode key',
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.link_off_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Disconnect & wipe this device',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: _confirmDisconnect,
                ),
              ],
              const SizedBox(height: 8),
              _SectionHeader('Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<AppThemeMode>(
                  segments: [
                    for (final mode in AppThemeMode.values)
                      ButtonSegment(
                        value: mode,
                        label: Text(mode.label),
                        icon: Icon(switch (mode) {
                          AppThemeMode.system => Icons.brightness_auto_rounded,
                          AppThemeMode.light => Icons.light_mode_rounded,
                          AppThemeMode.dark => Icons.dark_mode_rounded,
                        }),
                      ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => ref
                      .read(appStateProvider.notifier)
                      .updateSettings(
                        settings.copyWith(themeMode: selection.first),
                      ),
                ),
              ),
              if (!app.demo && jar != null) ...[
                const SizedBox(height: 8),
                _SectionHeader('Tip jar'),
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: Text(jar.displayName),
                  subtitle: Text('Currency: ${jar.currency.toUpperCase()}'),
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('Open payment link'),
                  subtitle: Text(
                    jar.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => launchUrl(
                    Uri.parse(jar.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Create a new tip link'),
                  subtitle: const Text(
                    'Change name or currency. The old link is deactivated '
                    '— printed QR codes stop working.',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JarSetupScreen(recreate: true),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _SectionHeader('Stage lock'),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Prefer Face ID / device unlock'),
                subtitle: Text(
                  _deviceAuthAvailable
                      ? 'Falls back to the app PIN if it fails'
                      : 'Not available on this device — the app PIN is used',
                ),
                value: settings.preferDeviceAuth && _deviceAuthAvailable,
                onChanged: _deviceAuthAvailable
                    ? (value) => ref
                          .read(appStateProvider.notifier)
                          .updateSettings(
                            settings.copyWith(preferDeviceAuth: value),
                          )
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.pin_rounded),
                title: Text(_hasPin ? 'Change app PIN' : 'Set app PIN'),
                subtitle: const Text(
                  'Backup unlock for the stage lock, stored only on this '
                  'device',
                ),
                onTap: () async {
                  final created = await ref
                      .read(lockServiceProvider)
                      .promptCreatePin(context);
                  if (created && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('PIN saved')));
                  }
                  _refreshLockInfo();
                },
                trailing: _hasPin
                    ? IconButton(
                        tooltip: 'Remove PIN',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          await ref.read(secureStoreProvider).clearPin();
                          _refreshLockInfo();
                        },
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              _SectionHeader('Stage look'),
              const StageSettingsSection(),
              const SizedBox(height: 8),
              _SectionHeader('Live session'),
              ListTile(
                leading: const Icon(Icons.speed_rounded),
                title: const Text('Check for new tips every'),
                trailing: DropdownButton<int>(
                  value: settings.pollIntervalSec,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('2 s')),
                    DropdownMenuItem(value: 4, child: Text('4 s')),
                    DropdownMenuItem(value: 8, child: Text('8 s')),
                    DropdownMenuItem(value: 15, child: Text('15 s')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(appStateProvider.notifier)
                          .updateSettings(
                            settings.copyWith(pollIntervalSec: value),
                          );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              _SectionHeader('About'),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('live.tips'),
                subtitle: Text(
                  'v0.1.0 · open-source tip jar — your keys, your money',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text('Source code'),
                subtitle: const Text(kProjectUrl),
                onTap: () => launchUrl(
                  Uri.parse(kProjectUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Open-source licenses'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'live.tips',
                  applicationVersion: '0.1.0',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
