/// The performer's stage-visual preferences, persisted inside [AppSettings].
///
/// Wire values (`wire`) match the stage library's bridge protocol keys
/// (renderer/PROTOCOL.md) — decode is tolerant: unknown stored values fall
/// back to defaults so an old app build never chokes on newer settings.
library;

/// How the live screen is rendered.
enum StageStyle {
  /// Today's numbers-first screen: big total, goal bar, feed. Fully native,
  /// works everywhere — also the terminal fallback when WebView is missing.
  classic('classic', 'Classic'),

  /// The Canvas-2D jar — lightweight, for weak or old tablets.
  jar2d('jar2d', '2D jar'),

  /// The full three.js jar with backdrop scenes.
  jar3d('jar3d', '3D scene');

  const StageStyle(this.wire, this.label);
  final String wire;
  final String label;

  static StageStyle fromWire(String? wire,
          {StageStyle fallback = StageStyle.jar3d}) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// Vessels the 3D renderer can stand on stage (real-world dimensions).
///
/// [capacityMajor] is the vessel's recommended goal in major currency units —
/// what a jar of that size physically holds in coins (the prototype's clean
/// goal ladder: 20 / 50 / 100 / … / 6000). The jar always fills toward the
/// artist's actual goal; this number is guidance so the vessel and the goal
/// feel matched (a caviar jar for a €5,000 night would pour absurd coins).
enum JarVessel {
  caviar('caviar', 'Caviar jar — 95 ml', 20),
  tin('tin', 'Tin can — 0.3 L', 50),
  mug('mug', 'Beer mug — 0.5 L', 100),
  jar05('jar05', 'Jar — 0.5 L', 125),
  jar1('jar1', 'Jar — 1 L', 250),
  jar2('jar2', 'Jar — 2 L', 500),
  // Hidden from the picker (see [selectable]) but kept in the library so
  // already-saved stages and the renderer bridge keep resolving it. The plain
  // 2 L [jar2] is the selectable stand-in and the default.
  stage('stage', 'Stage jar — stylized 2 L', 500),
  jar3('jar3', 'Jar — 3 L', 1000),
  jar5('jar5', 'Pickle jar — 5 L', 1500),
  bucket('bucket', 'Bucket — 10 L', 3000),
  bowl('bowl', 'Fishbowl — 20 L', 6000);

  const JarVessel(this.wire, this.label, this.capacityMajor);
  final String wire;
  final String label;
  final int capacityMajor;

  static JarVessel fromWire(String? wire,
          {JarVessel fallback = JarVessel.tin}) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => fallback);

  /// Vessels the picker offers. [stage] is intentionally left out — it stays a
  /// valid library/wire value, just not something a performer can pick.
  static List<JarVessel> get selectable =>
      values.where((v) => v != stage).toList(growable: false);

  /// Smallest vessel whose recommended capacity covers the goal (the biggest
  /// one for stadium-sized dreams).
  static JarVessel forGoalMajor(num goalMajor) =>
      values.firstWhere((v) => v.capacityMajor >= goalMajor,
          orElse: () => JarVessel.bowl);
}

/// Backdrop sets for the 3D renderer.
enum JarScene {
  abstractGlow('abstract', 'Abstract glow'),
  pub('pub', 'Irish pub'),
  concert('concert', 'Concert stage'),
  street('street', 'Night street'),
  metro('metro', 'Metro underpass'),
  cafe('cafe', 'Cozy café');

  const JarScene(this.wire, this.label);
  final String wire;
  final String label;

  static JarScene fromWire(String? wire,
          {JarScene fallback = JarScene.abstractGlow}) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// Stage color themes (match the live.tips public-page presets).
enum JarTheme {
  goldenHour('golden-hour', 'Golden Hour'),
  nordSky('nord-sky', 'Nord Sky'),
  forestSignal('forest-signal', 'Forest Signal'),
  rosePulse('rose-pulse', 'Rose Pulse'),
  cobaltStage('cobalt-stage', 'Cobalt Stage'),
  graphiteLime('graphite-lime', 'Graphite Lime');

  const JarTheme(this.wire, this.label);
  final String wire;
  final String label;

  static JarTheme fromWire(String? wire,
          {JarTheme fallback = JarTheme.goldenHour}) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// Bounds (logical px) for the drag-resizable wide-stage QR rail. The default
/// is the historical fixed width; on a tablet+ stage the performer drags the
/// rail's inner edge to widen/narrow it and the choice persists here. Kept in
/// the domain layer so the persisted value is always clamped to a sane range,
/// independent of the widget that renders the handle. See [StageSettings.railWidth].
const double kStageRailDefaultWidth = 280;
const double kStageRailMinWidth = 240;
const double kStageRailMaxWidth = 640;

/// Render-quality tier for the 3D renderer (bloom on/off/auto-detect).
enum StageQuality {
  auto('auto', 'Auto'),
  high('high', 'High'),
  low('low', 'Low');

  const StageQuality(this.wire, this.label);
  final String wire;
  final String label;

  static StageQuality fromWire(String? wire,
          {StageQuality fallback = StageQuality.auto}) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => fallback);
}

/// Immutable bag of stage preferences.
class StageSettings {
  const StageSettings({
    this.style = StageStyle.jar3d,
    this.vessel = JarVessel.tin,
    this.scene = JarScene.abstractGlow,
    this.theme = JarTheme.goldenHour,
    this.showNotes = false,
    this.soundEnabled = false,
    this.tipSoundEnabled = true,
    this.quality = StageQuality.auto,
    this.railWidth = kStageRailDefaultWidth,
  });

  final StageStyle style;

  /// 3D only — which container stands on stage.
  final JarVessel vessel;

  /// 3D only — the backdrop set around the vessel.
  final JarScene scene;

  final JarTheme theme;

  /// Mix folded banknotes into the pile (both jar renderers).
  final bool showNotes;

  /// Synthesized coin clinks / milestone chimes (on by default).
  final bool soundEnabled;

  /// The "ta-da!" fanfare when a new tip arrives — loud enough that the
  /// artist hears money land mid-song and can thank the donor from the
  /// stage. Independent of [soundEnabled]; on by default.
  final bool tipSoundEnabled;

  final StageQuality quality;

  /// Wide (tablet+) stage only — the width (logical px) of the floating QR +
  /// recent-messages rail, drag-resizable on stage. Always kept within
  /// [kStageRailMinWidth]..[kStageRailMaxWidth]; the vessel, HUD, tip banner
  /// and camera all reframe to the strip this leaves free.
  final double railWidth;

  StageSettings copyWith({
    StageStyle? style,
    JarVessel? vessel,
    JarScene? scene,
    JarTheme? theme,
    bool? showNotes,
    bool? soundEnabled,
    bool? tipSoundEnabled,
    StageQuality? quality,
    double? railWidth,
  }) =>
      StageSettings(
        style: style ?? this.style,
        vessel: vessel ?? this.vessel,
        scene: scene ?? this.scene,
        theme: theme ?? this.theme,
        showNotes: showNotes ?? this.showNotes,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        tipSoundEnabled: tipSoundEnabled ?? this.tipSoundEnabled,
        quality: quality ?? this.quality,
        railWidth: (railWidth ?? this.railWidth)
            .clamp(kStageRailMinWidth, kStageRailMaxWidth),
      );

  Map<String, dynamic> toJson() => {
        'style': style.wire,
        'vessel': vessel.wire,
        'scene': scene.wire,
        'theme': theme.wire,
        'showNotes': showNotes,
        'soundEnabled': soundEnabled,
        'tipSoundEnabled': tipSoundEnabled,
        'quality': quality.wire,
        'railWidth': railWidth,
      };

  factory StageSettings.fromJson(Map<String, dynamic> json) => StageSettings(
        style: StageStyle.fromWire(json['style'] as String?),
        vessel: JarVessel.fromWire(json['vessel'] as String?),
        scene: JarScene.fromWire(json['scene'] as String?),
        theme: JarTheme.fromWire(json['theme'] as String?),
        showNotes: json['showNotes'] as bool? ?? false,
        soundEnabled: json['soundEnabled'] as bool? ?? false,
        tipSoundEnabled: json['tipSoundEnabled'] as bool? ?? true,
        quality: StageQuality.fromWire(json['quality'] as String?),
        railWidth: ((json['railWidth'] as num?)?.toDouble() ??
                kStageRailDefaultWidth)
            .clamp(kStageRailMinWidth, kStageRailMaxWidth),
      );

  @override
  bool operator ==(Object other) =>
      other is StageSettings &&
      other.style == style &&
      other.vessel == vessel &&
      other.scene == scene &&
      other.theme == theme &&
      other.showNotes == showNotes &&
      other.soundEnabled == soundEnabled &&
      other.tipSoundEnabled == tipSoundEnabled &&
      other.quality == quality &&
      other.railWidth == railWidth;

  @override
  int get hashCode => Object.hash(style, vessel, scene, theme, showNotes,
      soundEnabled, tipSoundEnabled, quality, railWidth);
}
