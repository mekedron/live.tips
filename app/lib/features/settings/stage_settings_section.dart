import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/stage_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/enum_labels.dart';
import '../../state/providers.dart';
import '../../widgets/lt_ui.dart';
import '../live/stage/stage_resolver.dart';
import 'stage_preview_screen.dart';

/// One-line summary of the current stage look — "3D jar · Concert stage ·
/// Golden Hour" — for the Home quick row and settings subtitles.
String stageLookSummary(BuildContext context, StageSettings stage) {
  final parts = <String>[
    stage.style.l10nLabel(context),
    if (stage.style == StageStyle.jar3d) stage.scene.l10nLabel(context),
    if (stage.style != StageStyle.classic) stage.theme.l10nLabel(context),
  ];
  return parts.join(' · ');
}

/// Stage-look controls in a modal sheet — restyle the stage from Home or
/// mid-show without leaving for the settings tab.
Future<void> showStageLookSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        children: [
          Text(
            context.s.t('settings.stage.look_sheet_title'),
            style: outfitStyle(18, context.lt.text, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const StageSettingsSection(),
        ],
      ),
    ),
  );
}

/// The "Stage look" rows: style, vessel, scene, theme, notes, sounds,
/// quality, preview — every stage preference the performer owns. Renders as
/// a plain divided column; wrap it in a card (settings) or sheet (live).
class StageSettingsSection extends ConsumerWidget {
  const StageSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
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

    final currency = ref.watch(appStateProvider).currency;
    String fits(JarVessel v) =>
        formatAmount(v.capacityMajor * minorUnitsPerMajor(currency), currency);

    final rows = <Widget>[
      LtRow(
        icon: Icons.theater_comedy_rounded,
        title: context.s.t('settings.stage.style_title'),
        subtitle: !webViewSupported && isJar
            ? context.s.t('settings.stage.style_webview_note')
            : null,
        trailing: _ValueText(stage.style.l10nLabel(context)),
        chevron: true,
        onTap: () async {
          final picked = await showLtPicker<StageStyle>(
            context: context,
            title: context.s.t('settings.stage.style_picker_title'),
            values: StageStyle.selectable,
            selected: stage.style,
            labelOf: (s) => s.l10nLabel(context),
          );
          if (picked != null) update(stage.copyWith(style: picked));
        },
      ),
      if (is3d)
        LtRow(
          icon: Icons.local_drink_rounded,
          title: context.s.t('settings.stage.vessel_title'),
          trailing: _ValueText(
            '${stage.vessel.l10nLabel(context)} · ~${fits(stage.vessel)}',
          ),
          chevron: true,
          onTap: () async {
            final picked = await showLtPicker<JarVessel>(
              context: context,
              title: context.s.t('settings.stage.vessel_picker_title'),
              values: JarVessel.selectable,
              selected: stage.vessel,
              labelOf: (v) => v.l10nLabel(context),
              detailOf: (v) => context.s.t('settings.stage.vessel_detail', {
                'amount': fits(v),
              }),
            );
            if (picked != null) update(stage.copyWith(vessel: picked));
          },
        ),
      if (is3d)
        LtRow(
          icon: Icons.landscape_rounded,
          title: context.s.t('settings.stage.scene_title'),
          trailing: _ValueText(stage.scene.l10nLabel(context)),
          chevron: true,
          onTap: () async {
            final picked = await showLtPicker<JarScene>(
              context: context,
              title: context.s.t('settings.stage.scene_title'),
              values: JarScene.values,
              selected: stage.scene,
              labelOf: (s) => s.l10nLabel(context),
            );
            if (picked != null) update(stage.copyWith(scene: picked));
          },
        ),
      if (isJar)
        LtRow(
          icon: Icons.palette_rounded,
          title: context.s.t('settings.stage.theme_title'),
          trailing: _ValueText(stage.theme.l10nLabel(context)),
          chevron: true,
          onTap: () async {
            final picked = await showLtPicker<JarTheme>(
              context: context,
              title: context.s.t('settings.stage.theme_picker_title'),
              values: JarTheme.values,
              selected: stage.theme,
              labelOf: (t) => t.l10nLabel(context),
            );
            if (picked != null) update(stage.copyWith(theme: picked));
          },
        ),
      if (isJar)
        LtRow(
          icon: Icons.payments_rounded,
          title: context.s.t('settings.stage.notes_title'),
          subtitle: context.s.t('settings.stage.notes_subtitle'),
          trailing: Switch(
            value: stage.showNotes,
            onChanged: (v) => update(stage.copyWith(showNotes: v)),
          ),
        ),
      if (isJar)
        LtRow(
          icon: Icons.volume_up_rounded,
          title: context.s.t('settings.stage.coin_sounds_title'),
          subtitle: context.s.t('settings.stage.coin_sounds_subtitle'),
          trailing: Switch(
            value: stage.soundEnabled,
            onChanged: (v) => update(stage.copyWith(soundEnabled: v)),
          ),
        ),
      if (isJar)
        LtRow(
          icon: Icons.notifications_active_rounded,
          title: context.s.t('settings.stage.tip_fanfare_title'),
          subtitle: context.s.t('settings.stage.tip_fanfare_subtitle'),
          trailing: Switch(
            value: stage.tipSoundEnabled,
            onChanged: (v) => update(stage.copyWith(tipSoundEnabled: v)),
          ),
        ),
      if (is3d)
        LtRow(
          icon: Icons.auto_awesome_rounded,
          title: context.s.t('settings.stage.quality_title'),
          subtitle: context.s.t('settings.stage.quality_subtitle'),
          trailing: _ValueText(stage.quality.l10nLabel(context)),
          chevron: true,
          onTap: () async {
            final picked = await showLtPicker<StageQuality>(
              context: context,
              title: context.s.t('settings.stage.quality_title'),
              values: StageQuality.values,
              selected: stage.quality,
              labelOf: (q) => q.l10nLabel(context),
            );
            if (picked != null) update(stage.copyWith(quality: picked));
          },
        ),
      if (isJar)
        LtRow(
          icon: Icons.play_circle_outline_rounded,
          title: context.s.t('settings.stage.preview_title'),
          subtitle: context.s.t('settings.stage.preview_subtitle'),
          chevron: true,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const StagePreviewScreen())),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, color: c.divider),
          rows[i],
        ],
      ],
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontBody,
        fontSize: 13.5,
        color: context.lt.textSecondary,
      ),
    );
  }
}
