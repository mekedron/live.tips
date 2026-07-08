import '../../domain/donation.dart';
import '../../domain/tip_jar.dart';
import 'stripe_client.dart';

/// One `/v1/events` entry we care about (checkout.session.*), with the
/// embedded Checkout Session payload.
class DonationEvent {
  const DonationEvent({
    required this.id,
    required this.created,
    required this.session,
  });

  final String id;
  final int created;
  final Map<String, dynamic> session;
}

class DonationEventsPage {
  const DonationEventsPage({required this.events, required this.hasMore});

  /// Newest first, exactly as Stripe returns them.
  final List<DonationEvent> events;
  final bool hasMore;
}

class DonationsPage {
  const DonationsPage({required this.donations, required this.hasMore});

  /// Newest first.
  final List<Donation> donations;
  final bool hasMore;
}

class PermissionCheck {
  const PermissionCheck({
    required this.label,
    required this.ok,
    this.detail,
  });

  final String label;
  final bool ok;
  final String? detail;
}

class KeyCheckResult {
  const KeyCheckResult(this.checks);
  final List<PermissionCheck> checks;
  bool get allOk => checks.every((c) => c.ok);
}

/// Typed Stripe operations used by the app. Everything runs against the
/// artist's own account with their restricted key.
class StripeRequests {
  StripeRequests(this.client);

  final StripeClient client;

  static const _donationEventTypes = [
    'checkout.session.completed',
    'checkout.session.async_payment_succeeded',
  ];

  /// Verifies the key can do everything the app needs, without creating any
  /// objects. Write permissions are exercised for real on first jar creation,
  /// where errors are surfaced with the missing permission spelled out.
  Future<KeyCheckResult> checkKeyPermissions() async {
    Future<PermissionCheck> probe(
      String label,
      Future<void> Function() call,
    ) async {
      try {
        await call();
        return PermissionCheck(label: label, ok: true);
      } on StripeApiException catch (e) {
        return PermissionCheck(label: label, ok: false, detail: e.friendlyMessage);
      }
    }

    final checks = await Future.wait([
      probe('Checkout Sessions — Read (see donations)',
          () => client.get('checkout/sessions', query: {'limit': '1'})),
      probe('Events — polling (live feed)',
          () => client.get('events', query: {'limit': '1'})),
      probe('Payment Links — access (your tip link)',
          () => client.get('payment_links', query: {'limit': '1'})),
      probe('Products & Prices — access (the “Tip” item)',
          () => client.get('products', query: {'limit': '1'})),
    ]);
    return KeyCheckResult(checks);
  }

  /// Creates Product → pay-what-you-want Price → Payment Link, all tagged
  /// with metadata so they're recognizable in the Stripe dashboard.
  Future<TipJar> createTipJar({
    required String currency,
    required String displayName,
    required String thankYouMessage,
  }) async {
    final product = await client.post('products', {
      'name': 'Tips — $displayName',
      'description': 'Live tips collected with the open-source live.tips app.',
      'metadata[managed_by]': 'live.tips',
    });

    final price = await client.post('prices', {
      'product': product['id'] as String,
      'currency': currency,
      'custom_unit_amount[enabled]': 'true',
      'metadata[managed_by]': 'live.tips',
    });

    final link = await client.post('payment_links', {
      'line_items[0][price]': price['id'] as String,
      'line_items[0][quantity]': '1',
      'submit_type': 'donate',
      'custom_fields[0][key]': 'nickname',
      'custom_fields[0][label][type]': 'custom',
      'custom_fields[0][label][custom]': 'Your name or nickname',
      'custom_fields[0][type]': 'text',
      'custom_fields[0][optional]': 'true',
      'custom_fields[1][key]': 'message',
      'custom_fields[1][label][type]': 'custom',
      'custom_fields[1][label][custom]': 'Leave a message',
      'custom_fields[1][type]': 'text',
      'custom_fields[1][optional]': 'true',
      'after_completion[type]': 'hosted_confirmation',
      'after_completion[hosted_confirmation][custom_message]': thankYouMessage,
      'metadata[managed_by]': 'live.tips',
    });

    return TipJar(
      productId: product['id'] as String,
      priceId: price['id'] as String,
      paymentLinkId: link['id'] as String,
      url: link['url'] as String,
      currency: currency,
      displayName: displayName,
      livemode: link['livemode'] as bool? ?? false,
      thankYouMessage: thankYouMessage,
    );
  }

  /// Edits an existing jar's display name and thank-you message in place —
  /// the product's name and the payment link's post-checkout message. Used
  /// when the currency is unchanged, so the link (and its QR) keep working;
  /// a currency change still needs a fresh price + link via [createTipJar].
  Future<void> updateTipJarDetails({
    required String productId,
    required String paymentLinkId,
    required String displayName,
    required String thankYouMessage,
  }) async {
    await client.post('products/$productId', {'name': 'Tips — $displayName'});
    await client.post('payment_links/$paymentLinkId', {
      'after_completion[type]': 'hosted_confirmation',
      'after_completion[hosted_confirmation][custom_message]': thankYouMessage,
    });
  }

  Future<void> deactivatePaymentLink(String paymentLinkId) async {
    await client.post('payment_links/$paymentLinkId', {'active': 'false'});
  }

  /// Lists checkout.session.* success events, newest first.
  ///
  /// Pass [endingBefore] (an event id) to get only events newer than it, or
  /// [createdGte] for the first poll of a session.
  Future<DonationEventsPage> listDonationEvents({
    String? endingBefore,
    int? createdGte,
    int limit = 100,
  }) async {
    final response = await client.get('events', query: {
      'types[]': _donationEventTypes,
      'limit': '$limit',
      'ending_before': ?endingBefore,
      if (createdGte != null) 'created[gte]': '$createdGte',
    });

    final events = <DonationEvent>[];
    for (final item in (response['data'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      final object = (item['data'] as Map<String, dynamic>?)?['object'];
      if (object is! Map<String, dynamic>) continue;
      events.add(DonationEvent(
        id: item['id'] as String,
        created: (item['created'] as num?)?.toInt() ?? 0,
        session: object,
      ));
    }
    return DonationEventsPage(
      events: events,
      hasMore: response['has_more'] as bool? ?? false,
    );
  }

  /// Every completed donation in the account, newest first — the full history
  /// across *all* of the artist's payment links, not just the current one, so
  /// regenerating the link no longer wipes the history. Each session's
  /// `payment_link` is expanded so [Donation.viaService] can flag which
  /// payments actually came in through live.tips.
  Future<DonationsPage> listDonations({
    String? startingAfter,
    int limit = 25,
  }) async {
    final response = await client.get('checkout/sessions', query: {
      'status': 'complete',
      'expand[]': 'data.payment_link',
      'limit': '$limit',
      'starting_after': ?startingAfter,
    });

    final donations = <Donation>[];
    for (final item in (response['data'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      if (item['payment_status'] != 'paid') continue;
      donations.add(Donation.fromCheckoutSession(item));
    }
    return DonationsPage(
      donations: donations,
      hasMore: response['has_more'] as bool? ?? false,
    );
  }
}
