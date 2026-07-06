import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/stage_settings.dart';

void main() {
  group('StageSettings', () {
    test('defaults: 3D plain 2 L jar, abstract set, golden hour, coins only', () {
      const s = StageSettings();
      expect(s.style, StageStyle.jar3d);
      expect(s.vessel, JarVessel.jar2);
      expect(s.scene, JarScene.abstractGlow);
      expect(s.theme, JarTheme.goldenHour);
      expect(s.showNotes, isFalse, reason: 'paper money is opt-in');
      expect(s.soundEnabled, isFalse);
      expect(
        s.tipSoundEnabled,
        isFalse,
        reason: 'no surprise audio on an unattended stage device',
      );
      expect(s.quality, StageQuality.auto);
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
      );
      expect(StageSettings.fromJson(s.toJson()), s);
    });

    test('the sound toggles are independent', () {
      const s = StageSettings(soundEnabled: true);
      expect(s.copyWith(tipSoundEnabled: true).soundEnabled, isTrue);
      expect(s.tipSoundEnabled, isFalse);
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
        'lastGoalMinor': 20000,
        'preferDeviceAuth': false,
      };
      final s = AppSettings.fromJson(legacy);
      expect(s.pollIntervalSec, 6);
      expect(s.lastGoalMinor, 20000);
      expect(s.stage, const StageSettings());
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
