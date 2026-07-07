import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/features/onboarding/relay_setup_screen.dart';

void main() {
  group('extractMobilePayBoxId', () {
    const uuid = '01234567-89ab-cdef-0123-456789abcdef';

    test('pulls the uuid out of a full pasted share link', () {
      expect(
        extractMobilePayBoxId('https://qr.mobilepay.fi/box/$uuid/pay-in'),
        uuid,
      );
    });

    test('accepts a bare uuid, with surrounding whitespace', () {
      expect(extractMobilePayBoxId(uuid), uuid);
      expect(extractMobilePayBoxId('  $uuid \n'), uuid);
    });

    test('normalizes uppercase hex to lowercase', () {
      expect(
        extractMobilePayBoxId(uuid.toUpperCase()),
        uuid,
      );
    });

    test('finds the uuid in unfamiliar link shapes too', () {
      expect(
        extractMobilePayBoxId(
            'https://mobilepay.example/whatever?box=$uuid&x=1'),
        uuid,
      );
    });

    test('garbage → null', () {
      expect(extractMobilePayBoxId(''), isNull);
      expect(extractMobilePayBoxId('not a box id'), isNull);
      expect(extractMobilePayBoxId('https://qr.mobilepay.fi/box/'), isNull);
      expect(extractMobilePayBoxId('01234567-89ab-cdef-0123'), isNull,
          reason: 'a truncated uuid is not a box id');
    });
  });

  group('mobilePayCurrencyError', () {
    test('eur is fine, case-insensitively', () {
      expect(mobilePayCurrencyError('eur'), isNull);
      expect(mobilePayCurrencyError('EUR'), isNull);
    });

    test('any other currency is rejected with a readable message', () {
      final error = mobilePayCurrencyError('usd');
      expect(error, isNotNull);
      expect(error, contains('EUR'));
      expect(error, contains('USD'));
      expect(mobilePayCurrencyError('dkk'), isNotNull);
    });
  });
}
