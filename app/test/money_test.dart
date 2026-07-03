import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/money.dart';

void main() {
  group('formatAmount', () {
    test('drops decimals for whole amounts', () {
      expect(formatAmount(5000, 'usd'), r'$50');
      expect(formatAmount(100, 'eur'), '€1');
    });

    test('keeps two decimals for fractional amounts', () {
      expect(formatAmount(1250, 'usd'), r'$12.50');
      expect(formatAmount(1299, 'eur'), '€12.99');
    });

    test('zero-decimal currencies are not divided by 100', () {
      expect(formatAmount(500, 'jpy'), contains('500'));
      expect(formatAmount(500, 'jpy'), isNot(contains('.')));
    });

    test('alwaysShowDecimals forces cents', () {
      expect(formatAmount(5000, 'usd', alwaysShowDecimals: true), r'$50.00');
    });
  });

  group('parseMajorToMinor', () {
    test('parses whole and fractional input', () {
      expect(parseMajorToMinor('50', 'usd'), 5000);
      expect(parseMajorToMinor('12.50', 'usd'), 1250);
      expect(parseMajorToMinor('12,50', 'eur'), 1250);
      expect(parseMajorToMinor(' 5 ', 'usd'), 500);
    });

    test('zero-decimal currencies stay whole', () {
      expect(parseMajorToMinor('500', 'jpy'), 500);
    });

    test('rejects junk and non-positive values', () {
      expect(parseMajorToMinor('', 'usd'), isNull);
      expect(parseMajorToMinor('abc', 'usd'), isNull);
      expect(parseMajorToMinor('0', 'usd'), isNull);
      expect(parseMajorToMinor('-5', 'usd'), isNull);
    });
  });

  group('formatMajorPlain', () {
    test('round-trips with parseMajorToMinor', () {
      for (final minor in [5000, 1250, 999, 100]) {
        final plain = formatMajorPlain(minor, 'usd');
        expect(parseMajorToMinor(plain, 'usd'), minor);
      }
    });
  });
}
