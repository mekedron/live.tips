import '../../domain/song_request_settings.dart';
import '../../domain/tip.dart';
import '../../domain/tip_jar.dart';
import 'stripe_client.dart';

/// One `/v1/events` entry we care about, with its embedded `data.object`.
///
/// Two shapes ride this class, told apart by [type]: a Checkout Session (a tip
/// paid online through the QR link) and a Charge (a tip tapped in person). The
/// reader — [StripeTipSource] — must branch on [type] before touching
/// [object]; their fields overlap by name (`created`, `currency`, `livemode`)
/// but not by meaning, and the amount lives in different keys entirely.
class TipEvent {
  const TipEvent({
    required this.id,
    required this.created,
    required this.type,
    required this.object,
  });

  final String id;
  final int created;

  /// The Stripe event type, e.g. `checkout.session.completed`, `charge.succeeded`.
  final String type;

  /// `data.object`: a Checkout Session or a Charge, per [type].
  final Map<String, dynamic> object;

  /// True for the checkout.session.* family — an online tip through the link.
  bool get isCheckoutSession => type.startsWith('checkout.session.');
}

class TipEventsPage {
  const TipEventsPage({required this.events, required this.hasMore});

  /// Newest first, exactly as Stripe returns them.
  final List<TipEvent> events;
  final bool hasMore;
}

class TipsPage {
  const TipsPage({required this.tips, required this.hasMore});

  /// Newest first.
  final List<Tip> tips;
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

  /// The event types the live feed polls.
  ///
  /// The checkout.session.* pair covers tips paid online through the QR link.
  /// `charge.succeeded` covers the other observed path: a contactless tap the
  /// artist takes in person (Terminal reader, or Tap to Pay in Stripe's own
  /// Dashboard app). We watch the *Charge*, not the PaymentIntent, because the
  /// Charge is the object that carries `payment_method_details` — the
  /// `card_present` discriminator that tells a tap apart from a QR checkout —
  /// alongside the settled `amount` and `currency`. A PaymentIntent has
  /// neither: its payment-method detail sits on its `latest_charge`, which the
  /// event payload leaves unexpanded, so `payment_intent.succeeded` would force
  /// a second API call per tip *and* a second read permission. One event type,
  /// one object, everything we need.
  ///
  /// The catch, and the reason [StripeTipSource] is careful: a Checkout
  /// Session payment ALSO emits `charge.succeeded`. See the filter there — the
  /// card-present check is what keeps every QR tip counted exactly once.
  static const _tipEventTypes = [
    'checkout.session.completed',
    'checkout.session.async_payment_succeeded',
    'charge.succeeded',
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
      probe('Checkout Sessions — Read (see tips)',
          () => client.get('checkout/sessions', query: {'limit': '1'})),
      probe('Events — polling (live feed)',
          () => client.get('events', query: {'limit': '1'})),
      // A restricted key sees an event only if it may also read the object
      // inside it, so the in-person tap feed (charge.succeeded) needs Charges
      // read on top of Events read — otherwise taps would silently never
      // arrive, which is exactly the failure this screen exists to prevent.
      probe('Charges — Read (in-person tap tips)',
          () => client.get('charges', query: {'limit': '1'})),
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
      'description':
          'Tips for a live performance, collected with the open-source '
          'live.tips app.',
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
      // `pay`, never `donate`. submit_type also picks the checkout hostname:
      // `donate` would put every artist's QR on donate.stripe.com behind a
      // "Donate" button. These are tips for a performance — a service — not
      // charitable donations, and Stripe treats those as different businesses
      // (charitable fundraising is approval-gated, and prohibited outside
      // AU/CA/GB/US). Priming an artist to describe their own account as
      // "donations" is how they get refused. See docs/onboarding/tips-not-donations.md.
      'submit_type': 'pay',
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

  /// Creates one song's request objects (issue #64): Product → fixed Price →
  /// Payment Link with adjustable quantity 1–50 ("votes": `amount_total`
  /// arrives pre-multiplied, so no reader ever parses quantities). Parameter
  /// for parameter the call the server's stripeProxy `createSongLink` op
  /// makes with a cloud-custody key — including `pay`, never `donate` (see
  /// [createTipJar]) and the tip jar's nickname/message fields: a request is
  /// a tip with a song attached, and the stage shows the same name + message.
  ///
  /// Recognition asymmetry, stated honestly: the server-minted twin also
  /// stamps the link onto the band's `stripeConnections` doc, which is what
  /// lets the WEBHOOK attribute payments. That doc is server-custody
  /// (firestore.rules: `allow read, write: if false`) and no callable
  /// registers an app-minted mapping — so a link minted HERE is recognized
  /// only by the device poller (`StripeTipSource.songLinks`, fed from the
  /// band doc's [SongEntry.stripe] records). For a local-key band that is
  /// the whole story anyway: no connection doc means no webhook watches the
  /// account at all.
  Future<StripeSongLink> createSongLink({
    required String songId,
    required String title,
    required int priceMinor,
    required String currency,
  }) async {
    final product = await client.post('products', {
      'name': 'Request — $title',
      'metadata[managed_by]': 'live.tips',
      'metadata[song_id]': songId,
    });

    final price = await client.post('prices', {
      'product': product['id'] as String,
      'currency': currency,
      'unit_amount': '$priceMinor',
      'metadata[managed_by]': 'live.tips',
    });

    final link = await client.post('payment_links', {
      'line_items[0][price]': price['id'] as String,
      'line_items[0][quantity]': '1',
      'line_items[0][adjustable_quantity][enabled]': 'true',
      'line_items[0][adjustable_quantity][minimum]': '1',
      'line_items[0][adjustable_quantity][maximum]': '50',
      'submit_type': 'pay',
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
      'metadata[managed_by]': 'live.tips',
      'metadata[song_id]': songId,
    });

    return StripeSongLink(
      productId: product['id'] as String,
      priceId: price['id'] as String,
      paymentLinkId: link['id'] as String,
      url: link['url'] as String,
      priceMinor: priceMinor,
      title: title,
    );
  }

  /// Retires one song's link — it stops selling, its QR dies. The Product
  /// and Price stay behind (prices are immutable and products with payments
  /// can't be deleted anyway); the song's record is simply replaced or
  /// dropped by the caller.
  Future<void> deactivateSongLink(String paymentLinkId) =>
      deactivatePaymentLink(paymentLinkId);

  /// Renames a song link's product in place — the checkout page follows, the
  /// link and its QR keep working. Parity with the proxy's `updateSongLink`,
  /// and deliberately NOT what the editor sync uses for a title change: the
  /// stored record title is what attribution was minted for, so a rename
  /// that should reach the stage is deactivate + create, same as a price
  /// change.
  Future<void> renameSongProduct({
    required String productId,
    required String title,
  }) async {
    await client.post('products/$productId', {'name': 'Request — $title'});
  }

  /// Lists the [_tipEventTypes] success events, newest first.
  ///
  /// Pass [endingBefore] (an event id) to get only events newer than it, or
  /// [createdGte] for the first poll of a session.
  Future<TipEventsPage> listTipEvents({
    String? endingBefore,
    int? createdGte,
    int limit = 100,
  }) async {
    final response = await client.get('events', query: {
      'types[]': _tipEventTypes,
      'limit': '$limit',
      'ending_before': ?endingBefore,
      if (createdGte != null) 'created[gte]': '$createdGte',
    });

    final events = <TipEvent>[];
    for (final item in (response['data'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      final object = (item['data'] as Map<String, dynamic>?)?['object'];
      if (object is! Map<String, dynamic>) continue;
      final type = item['type'];
      if (type is! String) continue;
      events.add(TipEvent(
        id: item['id'] as String,
        created: (item['created'] as num?)?.toInt() ?? 0,
        type: type,
        object: object,
      ));
    }
    return TipEventsPage(
      events: events,
      hasMore: response['has_more'] as bool? ?? false,
    );
  }

  /// Every completed tip in the account, newest first — the full history
  /// across *all* of the artist's payment links, not just the current one, so
  /// regenerating the link no longer wipes the history. Each session's
  /// `payment_link` is expanded so [Tip.viaService] can flag which
  /// payments actually came in through live.tips.
  Future<TipsPage> listTips({
    String? startingAfter,
    int limit = 25,
  }) async {
    final response = await client.get('checkout/sessions', query: {
      'status': 'complete',
      'expand[]': 'data.payment_link',
      'limit': '$limit',
      'starting_after': ?startingAfter,
    });

    final tips = <Tip>[];
    for (final item in (response['data'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      if (item['payment_status'] != 'paid') continue;
      tips.add(Tip.fromCheckoutSession(item));
    }
    return TipsPage(
      tips: tips,
      hasMore: response['has_more'] as bool? ?? false,
    );
  }
}
