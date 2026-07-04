import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../domain/stage_settings.dart';
import '../../state/providers.dart';
import '../live/stage/stage_resolver.dart';
import 'stage_preview_screen.dart';

/// The "Stage look" block of the settings screen: style, vessel, scene,
/// theme, notes, sound, quality — every stage preference the performer owns.
/// Writes through the same updateSettings path as the rest of settings.
class StageSettingsSection extends ConsumerWidget {
  const StageSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).settings;
    final stage = settings.stage;
    final webViewSupported = ref.watch(stageCapabilityProvider);
    final is3d = stage.style == StageStyle.jar3d;
    final isJar = stage.style != StageStyle.classic;

    void update(StageSettings next) {
      ref
          .read(appStateProvider.notifier)
          .updateSettings(settings.copyWith(stage: next));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.theater_comedy_rounded),
          title: const Text('Stage style'),
          subtitle: !webViewSupported && isJar
              ? const Text('Jar styles need a WebView — this platform '
                  'shows the classic screen instead.')
              : null,
          trailing: DropdownButton<StageStyle>(
            value: stage.style,
            underline: const SizedBox(),
            items: [
              for (final s in StageStyle.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (v) {
              if (v != null) update(stage.copyWith(style: v));
            },
          ),
        ),
        if (is3d) ...[
          Builder(builder: (context) {
            final currency = ref
                    .watch(appStateProvider)
                    .effectiveTipJar
                    ?.currency ??
                'eur';
            String fits(JarVessel v) => formatAmount(
                v.capacityMajor * minorUnitsPerMajor(currency), currency);
            return ListTile(
              leading: const Icon(Icons.local_drink_rounded),
              title: const Text('Vessel'),
              subtitle: const Text('Any size fills toward your goal.'),
              trailing: DropdownButton<JarVessel>(
                value: stage.vessel,
                underline: const SizedBox(),
                items: [
                  for (final v in JarVessel.values)
                    DropdownMenuItem(
                        value: v,
                        child: Text('${v.label} · ~${fits(v)}')),
                ],
                onChanged: (v) {
                  if (v != null) update(stage.copyWith(vessel: v));
                },
              ),
            );
          }),
          ListTile(
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
        ],
        if (isJar) ...[
          ListTile(
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
            secondary: const Icon(Icons.payments_rounded),
            title: const Text('Banknotes in the jar'),
            subtitle: const Text('Mix folded notes into the coin pile'),
            value: stage.showNotes,
            onChanged: (v) => update(stage.copyWith(showNotes: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded),
            title: const Text('Coin sounds'),
            subtitle: const Text('Synthesized clinks and milestone chimes'),
            value: stage.soundEnabled,
            onChanged: (v) => update(stage.copyWith(soundEnabled: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded),
            title: const Text('New-tip fanfare'),
            subtitle: const Text('A bright ta-da when a tip arrives — hear '
                'it land mid-song and thank them from the stage'),
            value: stage.tipSoundEnabled,
            onChanged: (v) => update(stage.copyWith(tipSoundEnabled: v)),
          ),
          if (is3d)
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: const Text('Render quality'),
              subtitle: const Text('Auto drops effects if the device '
                  'can\'t hold a smooth frame rate'),
              trailing: DropdownButton<StageQuality>(
                value: stage.quality,
                underline: const SizedBox(),
                items: [
                  for (final q in StageQuality.values)
                    DropdownMenuItem(value: q, child: Text(q.label)),
                ],
                onChanged: (v) {
                  if (v != null) update(stage.copyWith(quality: v));
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: const Text('Preview the stage'),
            subtitle: const Text('Pour some pretend tips — no session needed'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const StagePreviewScreen(),
            )),
          ),
        ],
      ],
    );
  }
}
