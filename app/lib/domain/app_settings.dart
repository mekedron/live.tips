import 'stage_settings.dart';

/// The app's own light/dark appearance. Independent of the live stage screen,
/// which always renders dark regardless of this setting — it's designed to
/// be read from a distance during a performance, not to match device chrome.
enum AppThemeMode {
  system('system', 'System'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  const AppThemeMode(this.wire, this.label);
  final String wire;
  final String label;

  static AppThemeMode fromWire(
    String? wire, {
    AppThemeMode fallback = AppThemeMode.system,
  }) => values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// What the on-stage QR code points at: the Stripe payment link directly, or
/// the connected-mode fan page that offers every configured method
/// (card via Stripe, MobilePay, Revolut).
enum QrMode {
  stripe('stripe', 'Stripe only'),
  connected('connected', 'All methods');

  const QrMode(this.wire, this.label);
  final String wire;
  final String label;

  static QrMode fromWire(String? wire, {QrMode fallback = QrMode.connected}) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// Device-wide app behavior, persisted locally. Band-scoped preferences
/// (QR mode, goal, poster wording) live in `BandSettings`, one per band;
/// legacy blobs that still carry those keys decode fine — the extras are
/// simply ignored (the boot migration lifts them into the first band).
class AppSettings {
  const AppSettings({
    this.pollIntervalSec = 4,
    this.themeMode = AppThemeMode.system,
    this.stage = const StageSettings(),
    this.localeCode,
  });

  /// How often the live session polls Stripe for new tips.
  final int pollIntervalSec;

  /// The app's appearance — system-follows by default, or a manual override.
  final AppThemeMode themeMode;

  /// How the live stage looks (style, vessel, scene, theme…).
  final StageSettings stage;

  /// The chosen UI language as a locale code (e.g. `de`), or null to follow
  /// the device language. Resolved against the shipped locales at launch.
  final String? localeCode;

  static const _unset = Object();

  AppSettings copyWith({
    int? pollIntervalSec,
    AppThemeMode? themeMode,
    StageSettings? stage,
    Object? localeCode = _unset,
  }) => AppSettings(
    pollIntervalSec: pollIntervalSec ?? this.pollIntervalSec,
    themeMode: themeMode ?? this.themeMode,
    stage: stage ?? this.stage,
    localeCode: localeCode == _unset ? this.localeCode : localeCode as String?,
  );

  Map<String, dynamic> toJson() => {
    'pollIntervalSec': pollIntervalSec,
    'themeMode': themeMode.wire,
    'stage': stage.toJson(),
    if (localeCode != null) 'localeCode': localeCode,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    pollIntervalSec: (json['pollIntervalSec'] as num?)?.toInt() ?? 4,
    themeMode: AppThemeMode.fromWire(json['themeMode'] as String?),
    stage: json['stage'] is Map
        ? StageSettings.fromJson(
            Map<String, dynamic>.from(json['stage'] as Map),
          )
        : const StageSettings(),
    localeCode: json['localeCode'] as String?,
  );
}
