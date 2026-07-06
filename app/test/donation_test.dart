import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';

Map<String, dynamic> checkoutSession({
  String id = 'cs_test_1',
  int amount = 500,
  List<Map<String, dynamic>>? customFields,
  Map<String, dynamic>? customerDetails,
  bool livemode = false,
  Object? paymentIntent = 'pi_1',
}) =>
    {
      'id': id,
      'object': 'checkout.session',
      'amount_total': amount,
      'currency': 'eur',
      'created': 1751500000,
      'livemode': livemode,
      'payment_link': 'plink_1',
      'payment_status': 'paid',
      'payment_intent': paymentIntent,
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
    expect(restored.paymentIntentId, original.paymentIntentId);
  });

  test('captures the payment_intent id and links test-mode payments', () {
    final donation = Donation.fromCheckoutSession(
      checkoutSession(paymentIntent: 'pi_test_123'),
    );
    expect(donation.paymentIntentId, 'pi_test_123');
    expect(donation.stripeDashboardUrl,
        'https://dashboard.stripe.com/test/payments/pi_test_123');
  });

  test('live-mode payments link without the /test/ segment', () {
    final donation = Donation.fromCheckoutSession(
      checkoutSession(livemode: true, paymentIntent: 'pi_live_456'),
    );
    expect(donation.stripeDashboardUrl,
        'https://dashboard.stripe.com/payments/pi_live_456');
  });

  test('unwraps an expanded payment_intent object', () {
    final donation = Donation.fromCheckoutSession(
      checkoutSession(paymentIntent: {'id': 'pi_expanded_789'}),
    );
    expect(donation.paymentIntentId, 'pi_expanded_789');
  });

  test('no dashboard link without a payment_intent (e.g. demo tips)', () {
    final donation = Donation.fromCheckoutSession(
      checkoutSession(paymentIntent: null),
    );
    expect(donation.paymentIntentId, isNull);
    expect(donation.stripeDashboardUrl, isNull);
  });
}
