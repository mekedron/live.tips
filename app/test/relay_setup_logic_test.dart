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

  group('extractMonzoUsername', () {
    test('pulls the handle out of a pasted monzo.me link', () {
      expect(extractMonzoUsername('https://monzo.me/daniel'), 'daniel');
      expect(extractMonzoUsername('monzo.me/daniel'), 'daniel');
    });

    test('ignores an amount and description already on the link', () {
      expect(extractMonzoUsername('https://monzo.me/daniel/5?d=test'), 'daniel');
    });

    test('accepts a bare handle, with @ or whitespace', () {
      expect(extractMonzoUsername('daniel'), 'daniel');
      expect(extractMonzoUsername('@daniel'), 'daniel');
      expect(extractMonzoUsername('  Daniel \n'), 'daniel');
    });

    test('garbage → null', () {
      expect(extractMonzoUsername(''), isNull);
      expect(extractMonzoUsername('not a handle'), isNull);
      expect(extractMonzoUsername('https://monzo.me/'), isNull);
    });

    test('a handle that could escape the URL path is refused', () {
      // The handle is interpolated into monzo.me/<handle>/<amount>, so a
      // surviving slash or query char would rewrite the payment target.
      expect(extractMonzoUsername('dan/../evil'), isNull);
      expect(extractMonzoUsername('dan?d=x'), isNull);
      expect(extractMonzoUsername('-dan'), isNull);
    });
  });

  group('monzoCurrencyError', () {
    test('gbp is fine, case-insensitively', () {
      expect(monzoCurrencyError('gbp'), isNull);
      expect(monzoCurrencyError('GBP'), isNull);
    });

    test('any other currency is rejected with a readable message', () {
      final error = monzoCurrencyError('eur');
      expect(error, isNotNull);
      expect(error, contains('GBP'));
      expect(error, contains('EUR'));
    });
  });
}
