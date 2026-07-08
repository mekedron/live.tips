import 'package:flutter/widgets.dart';

import '../domain/app_settings.dart';
import '../domain/poster.dart';
import '../domain/stage_settings.dart';
import '../domain/tip_method.dart';
import 'app_localizations.dart';

/// Localized display labels for the app's option enums. The enums keep an
/// English `.label` (used in logs, tests, and as the en.json source text);
/// these `l10nLabel(context)` helpers are what the UI shows. Keys live under
/// `enum.<group>.<wire>` so a translator sees them grouped.
///
/// The vessel / scene / theme names deliberately match the landing page's
/// wording (website/i18n/strings) so the app and site read identically.

extension AppThemeModeL10n on AppThemeMode {
  String l10nLabel(BuildContext c) => c.s.t('enum.theme_mode.$wire');
}

extension QrModeL10n on QrMode {
  String l10nLabel(BuildContext c) => c.s.t('enum.qr_mode.$wire');
}

extension TipMethodL10n on TipMethod {
  String l10nLabel(BuildContext c) => c.s.t('enum.tip_method.$wire');
}

extension StageStyleL10n on StageStyle {
  String l10nLabel(BuildContext c) => c.s.t('enum.stage_style.$wire');
}

extension JarVesselL10n on JarVessel {
  String l10nLabel(BuildContext c) => c.s.t('enum.vessel.$wire');
}

extension JarSceneL10n on JarScene {
  String l10nLabel(BuildContext c) => c.s.t('enum.scene.$wire');
}

extension JarThemeL10n on JarTheme {
  String l10nLabel(BuildContext c) => c.s.t('enum.jar_theme.$wire');
}

extension StageQualityL10n on StageQuality {
  String l10nLabel(BuildContext c) => c.s.t('enum.quality.$wire');
}

extension PosterThemeL10n on PosterTheme {
  String l10nLabel(BuildContext c) => c.s.t('enum.poster_theme.$wire');
}

extension PosterPaperSizeL10n on PosterPaperSize {
  String l10nLabel(BuildContext c) => c.s.t('enum.paper_size.$wire');
}
