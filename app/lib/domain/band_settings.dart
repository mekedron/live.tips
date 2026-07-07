import 'app_settings.dart';
import 'poster.dart';

/// Per-band preferences — everything a band carries with it that isn't a
/// jar or a secret: which URL its QR encodes, its last session goal (minor
/// units of *its* currency), and its poster wording. Device-wide preferences
/// (theme, stage look, poll cadence) stay in [AppSettings].
class BandSettings {
  const BandSettings({
    this.qrMode = QrMode.connected,
    this.lastGoalMinor = 10000,
    this.poster = const PosterSettings(),
  });

  /// Which donation URL this band's QR encodes.
  final QrMode qrMode;

  /// Last goal this band used — prefilled next time.
  final int lastGoalMinor;

  /// This band's print-poster theme, captions, and paper size.
  final PosterSettings poster;

  BandSettings copyWith({
    QrMode? qrMode,
    int? lastGoalMinor,
    PosterSettings? poster,
  }) =>
      BandSettings(
        qrMode: qrMode ?? this.qrMode,
        lastGoalMinor: lastGoalMinor ?? this.lastGoalMinor,
        poster: poster ?? this.poster,
      );

  Map<String, dynamic> toJson() => {
        'qrMode': qrMode.wire,
        'lastGoalMinor': lastGoalMinor,
        'poster': poster.toJson(),
      };

  factory BandSettings.fromJson(Map<String, dynamic> json) => BandSettings(
        qrMode: QrMode.fromWire(json['qrMode'] as String?),
        lastGoalMinor: (json['lastGoalMinor'] as num?)?.toInt() ?? 10000,
        poster: json['poster'] is Map
            ? PosterSettings.fromJson(
                Map<String, dynamic>.from(json['poster'] as Map),
              )
            : const PosterSettings(),
      );
}
