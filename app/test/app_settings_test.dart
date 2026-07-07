import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/app_settings.dart';

void main() {
  test('qrMode defaults to connected', () {
    expect(const AppSettings().qrMode, QrMode.connected);
  });

  test('qrMode survives a json round trip', () {
    final settings = const AppSettings().copyWith(qrMode: QrMode.stripe);
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.qrMode, QrMode.stripe);
  });

  test('legacy settings json without qrMode falls back to connected', () {
    final restored = AppSettings.fromJson({
      'pollIntervalSec': 6,
      'lastGoalMinor': 5000,
      'themeMode': 'dark',
    });
    expect(restored.qrMode, QrMode.connected);
    expect(restored.pollIntervalSec, 6);
    expect(restored.themeMode, AppThemeMode.dark);
  });

  test('unknown qrMode wire value falls back', () {
    expect(QrMode.fromWire('holograms'), QrMode.connected);
    expect(QrMode.fromWire(null, fallback: QrMode.stripe), QrMode.stripe);
    for (final mode in QrMode.values) {
      expect(QrMode.fromWire(mode.wire), mode);
    }
  });
}
