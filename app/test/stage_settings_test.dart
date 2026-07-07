import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/stage_settings.dart';

void main() {
  group('StageSettings', () {
    test('defaults: 3D plain 2 L jar, abstract set, golden hour, sound on', () {
      const s = StageSettings();
      expect(s.style, StageStyle.jar3d);
      expect(s.vessel, JarVessel.jar2);
      expect(s.scene, JarScene.abstractGlow);
      expect(s.theme, JarTheme.goldenHour);
      expect(s.showNotes, isFalse, reason: 'paper money is opt-in');
      expect(s.soundEnabled, isTrue);
      expect(
        s.tipSoundEnabled,
        isTrue,
        reason: 'donation moments should be audible out of the box',
      );
      expect(s.quality, StageQuality.auto);
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
      expect(StageQuality.auto.wire, 'auto');
    });

    test('the stage jar stays in the library but is hidden from the picker', () {
      // Still decodes from the wire (already-saved stages keep working)...
      expect(JarVessel.values, contains(JarVessel.stage));
      expect(JarVessel.fromWire('stage'), JarVessel.stage);
      // ...but performers can't pick it; the plain 2 L jar stands in.
      expect(JarVessel.selectable, isNot(contains(JarVessel.stage)));
      expect(JarVessel.selectable, contains(JarVessel.jar2));
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
