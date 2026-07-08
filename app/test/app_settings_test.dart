import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/app_settings.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/poster.dart';

void main() {
  group('AppSettings', () {
    test('defaults', () {
      const settings = AppSettings();
      expect(settings.pollIntervalSec, 4);
      expect(settings.themeMode, AppThemeMode.system);
    });

    test('remaining fields survive a json round trip', () {
      final settings = const AppSettings().copyWith(
        pollIntervalSec: 6,
        themeMode: AppThemeMode.dark,
      );
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.pollIntervalSec, 6);
      expect(restored.themeMode, AppThemeMode.dark);
    });

    test('legacy blob with band-scoped keys decodes, extras ignored', () {
      // Pre-refactor settings_v1 blobs carried qrMode/lastGoalMinor/poster.
      // Those now live in BandSettings; decoding must not choke on them.
      final restored = AppSettings.fromJson({
        'pollIntervalSec': 6,
        'qrMode': 'stripe',
        'lastGoalMinor': 5000,
        'poster': {'theme': 'ticket-stub'},
        'themeMode': 'dark',
      });
      expect(restored.pollIntervalSec, 6);
      expect(restored.themeMode, AppThemeMode.dark);
      // Re-serializing drops the legacy keys — they are ignored, not kept.
      final reserialized = restored.toJson();
      expect(reserialized, isNot(contains('qrMode')));
      expect(reserialized, isNot(contains('lastGoalMinor')));
      expect(reserialized, isNot(contains('poster')));
    });

    test('unknown qrMode wire value falls back', () {
      expect(QrMode.fromWire('holograms'), QrMode.connected);
      expect(QrMode.fromWire(null, fallback: QrMode.stripe), QrMode.stripe);
      for (final mode in QrMode.values) {
        expect(QrMode.fromWire(mode.wire), mode);
      }
    });
  });

  group('BandSettings', () {
    test('qrMode defaults to connected', () {
      expect(const BandSettings().qrMode, QrMode.connected);
    });

    test('lastGoalMinor defaults to 5000', () {
      expect(const BandSettings().lastGoalMinor, 5000);
      expect(const BandSettings().poster, const PosterSettings());
    });

    test('fields survive a json round trip', () {
      final band = const BandSettings().copyWith(
        qrMode: QrMode.stripe,
        lastGoalMinor: 5000,
        poster: const PosterSettings(theme: PosterTheme.goldOnBlack),
      );
      final restored = BandSettings.fromJson(band.toJson());
      expect(restored.qrMode, QrMode.stripe);
      expect(restored.lastGoalMinor, 5000);
      expect(restored.poster.theme, PosterTheme.goldOnBlack);
    });

    test('json without qrMode falls back to connected', () {
      final restored = BandSettings.fromJson({'lastGoalMinor': 5000});
      expect(restored.qrMode, QrMode.connected);
      expect(restored.lastGoalMinor, 5000);
    });
  });
}
