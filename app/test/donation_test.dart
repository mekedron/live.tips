import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/tip_method.dart';

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

/// A Charge object as `/v1/events` delivers it. [methodType] is the
/// `payment_method_details.type` discriminator — `card_present` for a tap on a
/// reader or Tap to Pay, `card` for the charge behind an online Checkout
/// Session.
Map<String, dynamic> cardPresentCharge({
  String id = 'ch_tap',
  int amount = 700,
  String methodType = 'card_present',
  String status = 'succeeded',
  bool paid = true,
  bool livemode = true,
}) =>
    {
      'id': id,
      'object': 'charge',
      'amount': amount,
      'currency': 'eur',
      'created': 1751500000,
      'livemode': livemode,
      'status': status,
      'paid': paid,
      'payment_intent': 'pi_tap',
      'payment_method_details': {
        'type': methodType,
        methodType: const {'brand': 'visa', 'last4': '4242'},
      },
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

  test('method and verified survive a json round trip when non-default', () {
    final relayed = Donation.relayTip(
      amountMinor: 700,
      currency: 'dkk',
      method: TipMethod.mobilepay,
      name: 'Ida',
      message: 'Skål!',
      ts: 1751500000000,
      serial: 3,
    );
    final restored = Donation.fromJson(relayed.toJson());
    expect(restored.method, TipMethod.mobilepay);
    expect(restored.verified, isFalse);
    expect(restored.id, relayed.id);
    expect(restored.createdAt, relayed.createdAt);
  });

  test('legacy json without method/verified keys gets the defaults', () {
    final legacy = Donation.fromJson({
      'id': 'cs_old',
      'amountMinor': 500,
      'currency': 'eur',
      'createdAt': 1751500000000,
    });
    expect(legacy.method, TipMethod.stripe);
    expect(legacy.verified, isTrue);
  });

  test('toJson omits method/verified/inPerson when default — stored history '
      'stays byte-identical', () {
    final stripe = Donation.fromCheckoutSession(checkoutSession());
    expect(stripe.method, TipMethod.stripe);
    expect(stripe.verified, isTrue);
    expect(stripe.inPerson, isFalse);
    final json = stripe.toJson();
    expect(json.containsKey('method'), isFalse);
    expect(json.containsKey('verified'), isFalse);
    expect(json.containsKey('inPerson'), isFalse);
  });

  // ------------------------------------------------- in-person tap tips ---

  test('Donation.fromCardPresentCharge builds a verified, nameless tip', () {
    final tip = Donation.fromCardPresentCharge(cardPresentCharge());
    expect(tip.id, 'ch_tap');
    expect(tip.amountMinor, 700);
    expect(tip.currency, 'eur');
    expect(tip.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1751500000 * 1000));
    expect(tip.inPerson, isTrue);
    expect(tip.verified, isTrue, reason: 'Stripe saw the card — not a claim');
    expect(tip.name, isNull, reason: 'the tap flow collects no name');
    expect(tip.message, isNull);
    expect(tip.hasMessage, isFalse);
    expect(tip.displayName, 'Anonymous');
    expect(tip.method, TipMethod.stripe, reason: 'it is a Stripe card payment');
    expect(tip.viaService, isTrue);
    expect(tip.paymentIntentId, 'pi_tap');
    expect(tip.stripeDashboardUrl,
        'https://dashboard.stripe.com/payments/pi_tap');
  });

  test('the cardholder name off the chip is never used as a donor name', () {
    final tip = Donation.fromCardPresentCharge(
      cardPresentCharge()..['billing_details'] = {'name': 'MS J SMITH'},
    );
    expect(tip.name, isNull);
    expect(tip.displayName, 'Anonymous');
  });

  test('isCardPresentCharge accepts only successful in-person payments', () {
    expect(Donation.isCardPresentCharge(cardPresentCharge()), isTrue);
    // The charge Stripe creates behind every online Checkout Session — the one
    // that would double-count every QR tip if it slipped through.
    expect(
        Donation.isCardPresentCharge(cardPresentCharge(methodType: 'card')),
        isFalse);
    expect(
        Donation.isCardPresentCharge(
            cardPresentCharge(methodType: 'sepa_debit')),
        isFalse);
    expect(
        Donation.isCardPresentCharge(cardPresentCharge(status: 'failed')),
        isFalse);
    expect(Donation.isCardPresentCharge(cardPresentCharge(paid: false)),
        isFalse);
    // A charge with no payment_method_details at all (nothing to prove it was
    // in person) is not one of ours either.
    expect(
        Donation.isCardPresentCharge(
            cardPresentCharge()..remove('payment_method_details')),
        isFalse);
  });

  test('inPerson survives a json round trip', () {
    final tip = Donation.fromCardPresentCharge(cardPresentCharge());
    final json = tip.toJson();
    expect(json['inPerson'], isTrue);
    final restored = Donation.fromJson(json);
    expect(restored.inPerson, isTrue);
    expect(restored.verified, isTrue);
    expect(restored.id, tip.id);
    expect(restored.amountMinor, tip.amountMinor);
    expect(restored.createdAt, tip.createdAt);
  });

  test('Donation.relayTip builds an unverified live relay tip', () {
    final tip = Donation.relayTip(
      amountMinor: 1200,
      currency: 'eur',
      method: TipMethod.revolut,
      ts: 1751500123456,
      serial: 7,
    );
    expect(tip.id, 'relay_1751500123456_7');
    expect(tip.verified, isFalse);
    expect(tip.livemode, isTrue);
    expect(tip.viaService, isTrue);
    expect(tip.method, TipMethod.revolut);
    expect(tip.createdAt.millisecondsSinceEpoch, 1751500123456);
    expect(tip.displayName, 'Anonymous');
    expect(tip.stripeDashboardUrl, isNull);
  });
}
