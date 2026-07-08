import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/l10n/app_locale.dart';

void main() {
  group('localeCodeFromLandingParam', () {
    test('adopts a shipped ?lang= code', () {
      expect(localeCodeFromLandingParam(null, 'fi'), 'fi');
      expect(localeCodeFromLandingParam(null, 'de'), 'de');
    });

    test('a landing code overrides an earlier language', () {
      expect(localeCodeFromLandingParam('en', 'fi'), 'fi');
    });

    test('no-op when it already matches the active language', () {
      expect(localeCodeFromLandingParam('fi', 'fi'), isNull);
    });

    test('ignores an unknown or absent code', () {
      expect(localeCodeFromLandingParam(null, 'xx'), isNull);
      expect(localeCodeFromLandingParam('de', 'xx'), isNull);
      expect(localeCodeFromLandingParam(null, null), isNull);
      expect(localeCodeFromLandingParam(null, ''), isNull);
    });

    test('every shipped locale code is adoptable', () {
      for (final loc in kAppLocales) {
        expect(localeCodeFromLandingParam(null, loc.code), loc.code);
      }
    });
  });
}
