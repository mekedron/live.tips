import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../domain/stage_settings.dart';
import '../../state/providers.dart';
import '../live/stage/stage_resolver.dart';

/// Compact stage-look controls for the "go live" card: jar type sits up
/// front, everything else (scene, theme, notes, sound) waits behind a
/// "More settings" disclosure so the start-session form doesn't turn into
/// the full settings screen. Writes through the same updateSettings path as
/// the settings screen's StageSettingsSection — same persisted, global
/// stage preference, just a shortcut to the ones worth changing nightly.
class StageQuickSettings extends ConsumerWidget {
  const StageQuickSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final app = ref.watch(appStateProvider);
    final settings = app.settings;
    final stage = settings.stage;
    final webViewSupported = ref.watch(stageCapabilityProvider);
    final is3d = stage.style == StageStyle.jar3d;
    final isJar = stage.style != StageStyle.classic;

    if (!isJar) return const SizedBox.shrink();

    void update(StageSettings next) {
      ref
          .read(appStateProvider.notifier)
          .updateSettings(settings.copyWith(stage: next));
    }

    final currency = app.effectiveTipJar?.currency ?? 'eur';
    String fits(JarVessel v) =>
        formatAmount(v.capacityMajor * minorUnitsPerMajor(currency), currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (is3d)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_drink_rounded),
            title: const Text('Jar type'),
            subtitle: const Text('Any size fills toward your goal.'),
            trailing: DropdownButton<JarVessel>(
              value: stage.vessel,
              underline: const SizedBox(),
              items: [
                for (final v in JarVessel.values)
                  DropdownMenuItem(
                      value: v, child: Text('${v.label} · ~${fits(v)}')),
              ],
              onChanged: (v) {
                if (v != null) update(stage.copyWith(vessel: v));
              },
            ),
          ),
        if (!webViewSupported)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Jar styles need a WebView — this platform shows the classic '
              'screen instead.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            'More settings',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          children: [
            if (is3d)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.landscape_rounded),
                title: const Text('Scene'),
                trailing: DropdownButton<JarScene>(
                  value: stage.scene,
                  underline: const SizedBox(),
                  items: [
                    for (final s in JarScene.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) {
                    if (v != null) update(stage.copyWith(scene: v));
                  },
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_rounded),
              title: const Text('Stage theme'),
              trailing: DropdownButton<JarTheme>(
                value: stage.theme,
                underline: const SizedBox(),
                items: [
                  for (final t in JarTheme.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) {
                  if (v != null) update(stage.copyWith(theme: v));
                },
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.payments_rounded),
              title: const Text('Banknotes in the jar'),
              subtitle: const Text('Mix folded notes into the coin pile'),
              value: stage.showNotes,
              onChanged: (v) => update(stage.copyWith(showNotes: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.volume_up_rounded),
              title: const Text('Coin sounds'),
              subtitle:
                  const Text('Synthesized clinks and milestone chimes'),
              value: stage.soundEnabled,
              onChanged: (v) => update(stage.copyWith(soundEnabled: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_rounded),
              title: const Text('New-tip fanfare'),
              subtitle: const Text(
                  'A bright ta-da when a tip arrives — hear it land '
                  'mid-song and thank them from the stage'),
              value: stage.tipSoundEnabled,
              onChanged: (v) => update(stage.copyWith(tipSoundEnabled: v)),
            ),
          ],
        ),
      ],
    );
  }
}
