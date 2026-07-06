import 'poster.dart';
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

/// User-tunable app behavior, persisted locally.
class AppSettings {
  const AppSettings({
    this.pollIntervalSec = 4,
    this.lastGoalMinor = 10000,
    this.themeMode = AppThemeMode.system,
    this.stage = const StageSettings(),
    this.poster = const PosterSettings(),
  });

  /// How often the live session polls Stripe for new donations.
  final int pollIntervalSec;

  /// Last goal the artist used — prefilled next time.
  final int lastGoalMinor;

  /// The app's appearance — system-follows by default, or a manual override.
  final AppThemeMode themeMode;

  /// How the live stage looks (style, vessel, scene, theme…).
  final StageSettings stage;

  /// Last-picked print-poster theme, caption language, and paper size.
  final PosterSettings poster;

  AppSettings copyWith({
    int? pollIntervalSec,
    int? lastGoalMinor,
    AppThemeMode? themeMode,
    StageSettings? stage,
    PosterSettings? poster,
  }) => AppSettings(
    pollIntervalSec: pollIntervalSec ?? this.pollIntervalSec,
    lastGoalMinor: lastGoalMinor ?? this.lastGoalMinor,
    themeMode: themeMode ?? this.themeMode,
    stage: stage ?? this.stage,
    poster: poster ?? this.poster,
  );

  Map<String, dynamic> toJson() => {
    'pollIntervalSec': pollIntervalSec,
    'lastGoalMinor': lastGoalMinor,
    'themeMode': themeMode.wire,
    'stage': stage.toJson(),
    'poster': poster.toJson(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    pollIntervalSec: (json['pollIntervalSec'] as num?)?.toInt() ?? 4,
    lastGoalMinor: (json['lastGoalMinor'] as num?)?.toInt() ?? 10000,
    themeMode: AppThemeMode.fromWire(json['themeMode'] as String?),
    stage: json['stage'] is Map
        ? StageSettings.fromJson(
            Map<String, dynamic>.from(json['stage'] as Map),
          )
        : const StageSettings(),
    poster: json['poster'] is Map
        ? PosterSettings.fromJson(
            Map<String, dynamic>.from(json['poster'] as Map),
          )
        : const PosterSettings(),
  );
}
