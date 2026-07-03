import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';

Map<String, dynamic> checkoutSession({
  String id = 'cs_test_1',
  int amount = 500,
  List<Map<String, dynamic>>? customFields,
  Map<String, dynamic>? customerDetails,
}) =>
    {
      'id': id,
      'object': 'checkout.session',
      'amount_total': amount,
      'currency': 'eur',
      'created': 1751500000,
      'livemode': false,
      'payment_link': 'plink_1',
      'payment_status': 'paid',
      'custom_fields': customFields ?? [],
      'customer_details': customerDetails,
    };

void main() {
  test('parses amount, currency, and custom fields', () {
    final donation = Donation.fromCheckoutSession(checkoutSession(
      customFields: [
        {
          'key': 'nickname',
          'type': 'text',
          'text': {'value': 'Maya'},
        },
        {
          'key': 'message',
          'type': 'text',
          'text': {'value': 'Great set!'},
        },
      ],
    ));
    expect(donation.id, 'cs_test_1');
    expect(donation.amountMinor, 500);
    expect(donation.currency, 'eur');
    expect(donation.displayName, 'Maya');
    expect(donation.message, 'Great set!');
    expect(donation.livemode, isFalse);
  });

  test('falls back to customer_details.name, then Anonymous', () {
    final named = Donation.fromCheckoutSession(
      checkoutSession(customerDetails: {'name': 'Tom H'}),
    );
    expect(named.displayName, 'Tom H');

    final anon = Donation.fromCheckoutSession(checkoutSession());
    expect(anon.displayName, 'Anonymous');
    expect(anon.hasMessage, isFalse);
  });

  test('unfilled custom fields (null value) are ignored', () {
    final donation = Donation.fromCheckoutSession(checkoutSession(
      customFields: [
        {
          'key': 'nickname',
          'type': 'text',
          'text': {'value': null},
        },
      ],
    ));
    expect(donation.displayName, 'Anonymous');
  });

  test('json round trip', () {
    final original = Donation.fromCheckoutSession(checkoutSession(
      customFields: [
        {
          'key': 'message',
          'type': 'text',
          'text': {'value': 'Encore! 🎸'},
        },
      ],
    ));
    final restored = Donation.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.amountMinor, original.amountMinor);
    expect(restored.message, original.message);
    expect(restored.createdAt, original.createdAt);
    expect(restored.livemode, original.livemode);
  });
}
