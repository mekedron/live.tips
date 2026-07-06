import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';

Map<String, dynamic> checkoutSession({
  String id = 'cs_test_1',
  int amount = 500,
  List<Map<String, dynamic>>? customFields,
  Map<String, dynamic>? customerDetails,
  bool livemode = false,
  Object? paymentIntent = 'pi_1',
  Object? paymentLink = 'plink_1',
}) =>
    {
      'id': id,
      'object': 'checkout.session',
      'amount_total': amount,
      'currency': 'eur',
      'created': 1751500000,
      'livemode': livemode,
      'payment_link': paymentLink,
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
    expect(restored.viaService, original.viaService);
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

  test('flags live.tips payments via the expanded payment_link metadata', () {
    final ours = Donation.fromCheckoutSession(checkoutSession(paymentLink: {
      'id': 'plink_ours',
      'metadata': {'managed_by': 'live.tips'},
    }));
    expect(ours.viaService, isTrue);
  });

  test('a payment link that is not ours does not count as via the service', () {
    final theirs = Donation.fromCheckoutSession(checkoutSession(paymentLink: {
      'id': 'plink_theirs',
      'metadata': {'managed_by': 'something_else'},
    }));
    expect(theirs.viaService, isFalse);

    final bare = Donation.fromCheckoutSession(checkoutSession(
      paymentLink: {'id': 'plink_bare'},
    ));
    expect(bare.viaService, isFalse);
  });

  test('a transaction with no payment link is not via the service', () {
    final direct =
        Donation.fromCheckoutSession(checkoutSession(paymentLink: null));
    expect(direct.viaService, isFalse);
  });

  test('the events feed (a bare plink id) counts as via the service', () {
    // The `/v1/events` poller only ever hands us our own link, unexpanded.
    final live = Donation.fromCheckoutSession(checkoutSession());
    expect(live.viaService, isTrue);
  });

  test('viaService survives a json round trip when false', () {
    final external =
        Donation.fromCheckoutSession(checkoutSession(paymentLink: null));
    expect(external.viaService, isFalse);
    expect(Donation.fromJson(external.toJson()).viaService, isFalse);
  });
}
