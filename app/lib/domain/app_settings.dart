/// User-tunable app behavior, persisted locally.
class AppSettings {
  const AppSettings({
    this.pollIntervalSec = 4,
    this.lastGoalMinor = 10000,
    this.preferDeviceAuth = true,
  });

  /// How often the live session polls Stripe for new donations.
  final int pollIntervalSec;

  /// Last goal the artist used — prefilled next time.
  final int lastGoalMinor;

  /// Prefer Face ID / Touch ID / device passcode to unlock stage lock;
  /// falls back to the in-app PIN when unavailable.
  final bool preferDeviceAuth;

  AppSettings copyWith({
    int? pollIntervalSec,
    int? lastGoalMinor,
    bool? preferDeviceAuth,
  }) =>
      AppSettings(
        pollIntervalSec: pollIntervalSec ?? this.pollIntervalSec,
        lastGoalMinor: lastGoalMinor ?? this.lastGoalMinor,
        preferDeviceAuth: preferDeviceAuth ?? this.preferDeviceAuth,
      );

  Map<String, dynamic> toJson() => {
        'pollIntervalSec': pollIntervalSec,
        'lastGoalMinor': lastGoalMinor,
        'preferDeviceAuth': preferDeviceAuth,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        pollIntervalSec: (json['pollIntervalSec'] as num?)?.toInt() ?? 4,
        lastGoalMinor: (json['lastGoalMinor'] as num?)?.toInt() ?? 10000,
        preferDeviceAuth: json['preferDeviceAuth'] as bool? ?? true,
      );
}
