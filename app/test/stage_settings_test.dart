import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/stage_settings.dart';

void main() {
  group('StageSettings', () {
    test(
        'defaults: 3D beer mug, abstract set, golden hour, coin sound off, '
        'fanfare on', () {
      const s = StageSettings();
      expect(s.style, StageStyle.jar3d);
      expect(s.vessel, JarVessel.mug,
          reason: 'rated ~100 — matches the default goal of 100 major units');
      expect(s.scene, JarScene.abstractGlow);
      expect(s.theme, JarTheme.goldenHour);
      expect(s.showNotes, isFalse, reason: 'paper money is opt-in');
      expect(s.soundEnabled, isFalse,
          reason: 'coin clinks are opt-in; the fanfare alone is enough');
      expect(
        s.tipSoundEnabled,
        isTrue,
        reason: 'tip moments should be audible out of the box',
      );
      expect(s.quality, StageQuality.high);
      expect(s.railWidth, kStageRailDefaultWidth);
    });

    test('json round-trip preserves every field', () {
      const s = StageSettings(
        style: StageStyle.jar2d,
        vessel: JarVessel.bucket,
        scene: JarScene.metro,
        theme: JarTheme.rosePulse,
        showNotes: false,
        soundEnabled: true,
        tipSoundEnabled: true,
        quality: StageQuality.low,
        railWidth: 372,
      );
      expect(StageSettings.fromJson(s.toJson()), s);
    });

    test('railWidth clamps to the valid rail range on copyWith and decode', () {
      // Below the floor and above the ceiling both snap back into range.
      expect(
        const StageSettings().copyWith(railWidth: 10).railWidth,
        kStageRailMinWidth,
      );
      expect(
        const StageSettings().copyWith(railWidth: 5000).railWidth,
        kStageRailMaxWidth,
      );
      expect(
        StageSettings.fromJson({'railWidth': 99999}).railWidth,
        kStageRailMaxWidth,
      );
      // A sane persisted value survives untouched.
      expect(StageSettings.fromJson({'railWidth': 320}).railWidth, 320);
    });

    test('legacy stage blob without railWidth gets the default width', () {
      final s = StageSettings.fromJson({'style': 'jar2d'});
      expect(s.railWidth, kStageRailDefaultWidth);
    });

    test('the sound toggles are independent', () {
      const s = StageSettings(soundEnabled: true, tipSoundEnabled: false);
      final flipped = s.copyWith(tipSoundEnabled: true);
      expect(flipped.soundEnabled, isTrue, reason: 'unrelated toggle stays put');
      expect(flipped.tipSoundEnabled, isTrue);
    });

    test('wire values match the bridge protocol', () {
      expect(StageStyle.jar3d.wire, 'jar3d');
      expect(JarScene.abstractGlow.wire, 'abstract');
      expect(JarTheme.goldenHour.wire, 'golden-hour');
      expect(JarVessel.stage.wire, 'stage');
      expect(StageQuality.high.wire, 'high');
    });

    test('the retired auto quality tier decodes to high', () {
      // Old stages persisted `quality: auto`; that tier is gone (the renderer
      // no longer auto-degrades) so it decodes to the new default, High.
      expect(StageQuality.fromWire('auto'), StageQuality.high);
      expect(StageSettings.fromJson({'quality': 'auto'}).quality,
          StageQuality.high);
    });

    test('the 2D jar stays in the library but is hidden from the picker', () {
      // Still decodes from the wire (already-saved stages keep working)...
      expect(StageStyle.values, contains(StageStyle.jar2d));
      expect(StageStyle.fromWire('jar2d'), StageStyle.jar2d);
      // ...but performers can't pick it; 2D is never something we land on.
      expect(StageStyle.selectable, isNot(contains(StageStyle.jar2d)));
      expect(StageStyle.selectable, contains(StageStyle.jar3d));
    });

    test('the stage jar stays in the library but is hidden from the picker', () {
      // Still decodes from the wire (already-saved stages keep working)...
      expect(JarVessel.values, contains(JarVessel.stage));
      expect(JarVessel.fromWire('stage'), JarVessel.stage);
      // ...but performers can't pick it; the plain 2 L jar stands in.
      expect(JarVessel.selectable, isNot(contains(JarVessel.stage)));
      expect(JarVessel.selectable, contains(JarVessel.jar2));
    });

    test('the auto vessel is pickable, persists, and never renders itself', () {
      // In the picker (first, ahead of the size ladder) and on the wire...
      expect(JarVessel.selectable.first, JarVessel.auto);
      expect(JarVessel.fromWire('auto'), JarVessel.auto);
      expect(StageSettings.fromJson({'vessel': 'auto'}).vessel, JarVessel.auto);
      // ...but resolution always lands on a real jar, even for a zero goal
      // (auto's own capacityMajor of 0 must never match).
      expect(JarVessel.forGoalMajor(0), JarVessel.caviar);
      expect(JarVessel.auto.resolveForGoalMajor(0), JarVessel.caviar);
    });

    test('forGoalMajor rounds UP to the smallest vessel that covers the goal',
        () {
      expect(JarVessel.forGoalMajor(20), JarVessel.caviar);
      expect(JarVessel.forGoalMajor(45), JarVessel.tin);
      // Between two sizes the jar must still hold the goal — 75 gets the
      // 100-rated mug, not the 50-rated tin it would overflow.
      expect(JarVessel.forGoalMajor(75), JarVessel.mug);
      expect(JarVessel.forGoalMajor(100), JarVessel.mug);
      expect(JarVessel.forGoalMajor(101), JarVessel.jar05);
      // The hidden stylized stage jar never wins — plain 2 L sorts first.
      expect(JarVessel.forGoalMajor(500), JarVessel.jar2);
      // Stadium-sized dreams cap at the biggest vessel.
      expect(JarVessel.forGoalMajor(1000000), JarVessel.bowl);
    });

    test('resolveForGoalMajor leaves manual picks alone', () {
      expect(JarVessel.caviar.resolveForGoalMajor(5000), JarVessel.caviar);
      expect(JarVessel.auto.resolveForGoalMajor(2000), JarVessel.bucket);
    });

    test('unknown wire values decode to defaults (forward compatibility)', () {
      final s = StageSettings.fromJson({
        'style': 'hologram',
        'vessel': 'swimming-pool',
        'scene': 'mars',
        'theme': 'vantablack',
        'quality': 'ultra',
      });
      expect(s, const StageSettings());
    });
  });

  group('AppSettings + stage', () {
    test('round-trips the nested stage settings', () {
      const s = AppSettings(
        pollIntervalSec: 7,
        stage: StageSettings(style: StageStyle.classic),
      );
      final revived = AppSettings.fromJson(s.toJson());
      expect(revived.pollIntervalSec, 7);
      expect(revived.stage.style, StageStyle.classic);
    });

    test('legacy settings_v1 blob without a stage key gets defaults', () {
      final legacy = {
        'pollIntervalSec': 6,
        'lastGoalMinor': 20000, // band-scoped now; AppSettings ignores it
        'preferDeviceAuth': false,
      };
      final s = AppSettings.fromJson(legacy);
      expect(s.pollIntervalSec, 6);
      expect(s.stage, const StageSettings());
      // The goal moved to BandSettings — the same legacy blob still decodes
      // it in its new home (the boot migration lifts it into the first band).
      expect(BandSettings.fromJson(legacy).lastGoalMinor, 20000);
    });

    test('default goal matches the default vessel', () {
      // 100 major units — what the out-of-the-box beer mug is rated for, so
      // a fresh stage never opens with a jar/goal mismatch.
      expect(const BandSettings().lastGoalMinor, 10000);
      expect(
        JarVessel.forGoalMajor(const BandSettings().lastGoalMinor / 100),
        const StageSettings().vessel,
      );
    });
  });

  group('AppThemeMode', () {
    test('defaults to system', () {
      const s = AppSettings();
      expect(s.themeMode, AppThemeMode.system);
    });

    test('wire values', () {
      expect(AppThemeMode.system.wire, 'system');
      expect(AppThemeMode.light.wire, 'light');
      expect(AppThemeMode.dark.wire, 'dark');
    });

    test('round-trips through AppSettings json', () {
      const s = AppSettings(themeMode: AppThemeMode.dark);
      expect(AppSettings.fromJson(s.toJson()).themeMode, AppThemeMode.dark);
    });

    test('unknown or missing wire value falls back to system', () {
      expect(AppThemeMode.fromWire('solarized'), AppThemeMode.system);
      expect(AppThemeMode.fromWire(null), AppThemeMode.system);
    });

    test('legacy settings_v1 blob without a themeMode key gets system', () {
      final legacy = {'pollIntervalSec': 6};
      expect(AppSettings.fromJson(legacy).themeMode, AppThemeMode.system);
    });
  });
}
