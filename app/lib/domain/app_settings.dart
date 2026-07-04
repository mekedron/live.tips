import 'stage_settings.dart';

/// User-tunable app behavior, persisted locally.
class AppSettings {
  const AppSettings({
    this.pollIntervalSec = 4,
    this.lastGoalMinor = 10000,
    this.preferDeviceAuth = true,
    this.stage = const StageSettings(),
  });

  /// How often the live session polls Stripe for new donations.
  final int pollIntervalSec;

  /// Last goal the artist used — prefilled next time.
  final int lastGoalMinor;

  /// Prefer Face ID / Touch ID / device passcode to unlock stage lock;
  /// falls back to the in-app PIN when unavailable.
  final bool preferDeviceAuth;

  /// How the live stage looks (style, vessel, scene, theme…).
  final StageSettings stage;

  AppSettings copyWith({
    int? pollIntervalSec,
    int? lastGoalMinor,
    bool? preferDeviceAuth,
    StageSettings? stage,
  }) =>
      AppSettings(
        pollIntervalSec: pollIntervalSec ?? this.pollIntervalSec,
        lastGoalMinor: lastGoalMinor ?? this.lastGoalMinor,
        preferDeviceAuth: preferDeviceAuth ?? this.preferDeviceAuth,
        stage: stage ?? this.stage,
      );

  Map<String, dynamic> toJson() => {
        'pollIntervalSec': pollIntervalSec,
        'lastGoalMinor': lastGoalMinor,
        'preferDeviceAuth': preferDeviceAuth,
        'stage': stage.toJson(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        pollIntervalSec: (json['pollIntervalSec'] as num?)?.toInt() ?? 4,
        lastGoalMinor: (json['lastGoalMinor'] as num?)?.toInt() ?? 10000,
        preferDeviceAuth: json['preferDeviceAuth'] as bool? ?? true,
        stage: json['stage'] is Map
            ? StageSettings.fromJson(
                Map<String, dynamic>.from(json['stage'] as Map))
            : const StageSettings(),
      );
}
