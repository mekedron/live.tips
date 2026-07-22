import 'app_settings.dart';
import 'poster.dart';
import 'song_request_settings.dart';

/// Per-band preferences — everything a band carries with it that isn't a
/// jar or a secret: which URL its QR encodes, its last session goal (minor
/// units of *its* currency), and its poster wording. Device-wide preferences
/// (theme, stage look, poll cadence) stay in [AppSettings].
class BandSettings {
  const BandSettings({
    this.qrMode = QrMode.connected,
    // 100 major units out of the box — the size the default beer-mug vessel
    // is rated for, so a fresh stage starts with jar and goal matched.
    this.lastGoalMinor = 10000,
    this.poster = const PosterSettings(),
    this.songRequests = const SongRequestSettings(),
  });

  /// Which tip URL this band's QR encodes.
  final QrMode qrMode;

  /// Last goal this band used — prefilled next time.
  final int lastGoalMinor;

  /// This band's print-poster theme, captions, and paper size.
  final PosterSettings poster;

  /// This band's song-request library and toggles (issue #64). Lives here —
  /// not on the jar — so it syncs with the profile and works for local
  /// accounts; the jar gets a published copy via `setJarRequests`.
  final SongRequestSettings songRequests;

  BandSettings copyWith({
    QrMode? qrMode,
    int? lastGoalMinor,
    PosterSettings? poster,
    SongRequestSettings? songRequests,
  }) =>
      BandSettings(
        qrMode: qrMode ?? this.qrMode,
        lastGoalMinor: lastGoalMinor ?? this.lastGoalMinor,
        poster: poster ?? this.poster,
        songRequests: songRequests ?? this.songRequests,
      );

  Map<String, dynamic> toJson() => {
        'qrMode': qrMode.wire,
        'lastGoalMinor': lastGoalMinor,
        'poster': poster.toJson(),
        'songRequests': songRequests.toJson(),
      };

  factory BandSettings.fromJson(Map<String, dynamic> json) => BandSettings(
        qrMode: QrMode.fromWire(json['qrMode'] as String?),
        lastGoalMinor: (json['lastGoalMinor'] as num?)?.toInt() ?? 10000,
        poster: json['poster'] is Map
            ? PosterSettings.fromJson(
                Map<String, dynamic>.from(json['poster'] as Map),
              )
            : const PosterSettings(),
        songRequests: json['songRequests'] is Map
            ? SongRequestSettings.fromJson(
                Map<String, dynamic>.from(json['songRequests'] as Map),
              )
            : const SongRequestSettings(),
      );
}
