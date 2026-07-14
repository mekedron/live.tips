import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/data/stripe/stripe_client.dart';
import 'package:live_tips/data/stripe/stripe_requests.dart';

Map<String, dynamic> paidSession(String id, {String link = 'plink_ours'}) => {
      'id': id,
      'amount_total': 500,
      'currency': 'usd',
      'created': 1751500000,
      'livemode': false,
      'payment_link': link,
      'payment_status': 'paid',
      'payment_intent': 'pi_$id',
      'custom_fields': const [],
    };

/// A Charge as `/v1/events` delivers it. [type] is the
/// `payment_method_details.type` discriminator: `card_present` for a tap on a
/// reader / Tap to Pay, `card` for the charge that Stripe creates behind an
/// online Checkout Session.
Map<String, dynamic> charge(
  String id, {
  String type = 'card_present',
  String? paymentIntent,
  int amount = 700,
  String status = 'succeeded',
  bool paid = true,
}) =>
    {
      'id': id,
      'object': 'charge',
      'amount': amount,
      'currency': 'usd',
      'created': 1751500000,
      'livemode': false,
      'status': status,
      'paid': paid,
      'payment_intent': paymentIntent ?? 'pi_$id',
      'payment_method_details': {
        'type': type,
        type: const {'brand': 'visa', 'last4': '4242'},
      },
    };

TipEvent sessionEvent(
  String eventId, {
  required int created,
  required Map<String, dynamic> session,
  String type = 'checkout.session.completed',
}) =>
    TipEvent(
        id: eventId, created: created, type: type, object: session);

TipEvent chargeEvent(
  String eventId, {
  required int created,
  required Map<String, dynamic> object,
}) =>
    TipEvent(
        id: eventId,
        created: created,
        type: 'charge.succeeded',
        object: object);

class FakeRequests extends StripeRequests {
  FakeRequests(this.pages) : super(StripeClient('rk_test_fake'));

  final List<TipEventsPage> pages;
  final List<String?> endingBeforeCalls = [];
  final List<int?> createdGteCalls = [];
  int _next = 0;

  @override
  Future<TipEventsPage> listTipEvents({
    String? endingBefore,
    int? createdGte,
    int limit = 100,
  }) async {
    endingBeforeCalls.add(endingBefore);
    createdGteCalls.add(createdGte);
    if (_next >= pages.length) {
      return const TipEventsPage(events: [], hasMore: false);
    }
    return pages[_next++];
  }
}

void main() {
  test('prime anchors on the newest existing event', () async {
    final requests = FakeRequests([
      TipEventsPage(
        events: [
          sessionEvent('evt_anchor', created: 1, session: paidSession('cs_old')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());
    expect(source.cursor, 'evt_anchor');

    // Nothing new yet → no tips, cursor unchanged.
    final none = await source.pollNew();
    expect(none, isEmpty);
    expect(source.cursor, 'evt_anchor');
    expect(requests.endingBeforeCalls.last, 'evt_anchor');
  });

  test(
      'prime with backfill re-reads the whole session window instead of '
      'anchoring on the newest event (tips from while the app was dead)',
      () async {
    final requests = FakeRequests([
      TipEventsPage(
        events: [
          sessionEvent('evt_missed',
              created: 1751500100, session: paidSession('cs_missed')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeTipSource(requests, paymentLinkId: 'plink_ours');
    final startedAt =
        DateTime.fromMillisecondsSinceEpoch(1751500000 * 1000, isUtc: true);
    await source.prime(startedAt, backfill: true);
    // no anchor request was made — the single fake page is still unread
    expect(requests.endingBeforeCalls, isEmpty);

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id), ['cs_missed'],
        reason: 'the tip that arrived while the app was dead is recovered');
    // the window starts a safety margin before the session start
    expect(requests.createdGteCalls.first, 1751500000 - 60);
    expect(source.cursor, 'evt_missed');
  });

  test('pollNew returns fresh tips chronologically and advances cursor',
      () async {
    final requests = FakeRequests([
      // prime call
      const TipEventsPage(events: [], hasMore: false),
      // first poll: two new events, newest first (Stripe order)
      TipEventsPage(
        events: [
          sessionEvent('evt_2', created: 20, session: paidSession('cs_b')),
          sessionEvent('evt_1', created: 10, session: paidSession('cs_a')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['cs_a', 'cs_b']);
    expect(source.cursor, 'evt_2');
  });

  test('filters other links, unpaid sessions, and duplicate tips',
      () async {
    final unpaid = paidSession('cs_unpaid')..['payment_status'] = 'unpaid';
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [
          // duplicate pair: completed + async_payment_succeeded for cs_dup
          sessionEvent('evt_5',
              created: 50,
              session: paidSession('cs_dup'),
              type: 'checkout.session.async_payment_succeeded'),
          sessionEvent('evt_4', created: 40, session: paidSession('cs_dup')),
          sessionEvent('evt_3', created: 30, session: unpaid),
          sessionEvent('evt_2',
              created: 20,
              session: paidSession('cs_other', link: 'plink_theirs')),
          sessionEvent('evt_1', created: 10, session: paidSession('cs_ok')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['cs_ok', 'cs_dup']);
    expect(source.cursor, 'evt_5');
  });

  test('resume cursor is used verbatim', () async {
    final requests = FakeRequests([
      TipEventsPage(
        events: [
          sessionEvent('evt_9', created: 90, session: paidSession('cs_missed')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now(), resumeCursor: 'evt_stored');

    final fresh = await source.pollNew();
    expect(requests.endingBeforeCalls.first, 'evt_stored');
    expect(fresh.single.id, 'cs_missed');
  });

  // ------------------------------------------------- in-person tap tips ---

  test(
      'a QR tip is counted exactly once even though its Checkout Session and '
      'its Charge both arrive in the stream', () async {
    // This is the whole point of watching charge.succeeded carefully. One
    // payment through the QR link produces BOTH a checkout.session.completed
    // (cs_qr) and a charge.succeeded (ch_qr, card-NOT-present) — two events,
    // two different ids, one payment. Counting the charge as well would
    // silently double every tip on the stage, and no id-based de-duplication
    // could ever catch it.
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [
          chargeEvent('evt_2',
              created: 20,
              object: charge('ch_qr', type: 'card', paymentIntent: 'pi_qr')),
          sessionEvent('evt_1',
              created: 10,
              session: paidSession('cs_qr')..['payment_intent'] = 'pi_qr'),
        ],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['cs_qr'],
        reason: 'the online tip counts once — as its Checkout Session');
    expect(fresh.single.amountMinor, 500);
    expect(fresh.single.inPerson, isFalse);
  });

  test('a card-present charge becomes an anonymous, verified in-person tip',
      () async {
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [
          chargeEvent('evt_1',
              created: 10,
              object: charge('ch_tap', amount: 700, paymentIntent: 'pi_tap')),
        ],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final tip = (await source.pollNew()).single;
    expect(tip.id, 'ch_tap');
    expect(tip.amountMinor, 700);
    expect(tip.currency, 'usd');
    expect(tip.inPerson, isTrue);
    expect(tip.verified, isTrue, reason: 'Stripe saw the card');
    expect(tip.name, isNull, reason: 'a tap collects an amount, nothing else');
    expect(tip.message, isNull);
    expect(tip.displayName, 'Anonymous');
    expect(tip.paymentIntentId, 'pi_tap');
    expect(tip.livemode, isFalse);
  });

  test('in-person taps and QR tips arrive together, each counted once',
      () async {
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [
          // A tap. Emits only a charge — no session exists for it.
          chargeEvent('evt_4', created: 40, object: charge('ch_tap')),
          // A QR tip, both of its events, in Stripe's newest-first order.
          chargeEvent('evt_3',
              created: 30, object: charge('ch_qr', type: 'card')),
          sessionEvent('evt_2', created: 20, session: paidSession('cs_qr')),
          // The same tap redelivered (Stripe events are at-least-once).
          chargeEvent('evt_1', created: 10, object: charge('ch_tap')),
        ],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['ch_tap', 'cs_qr'],
        reason: 'one tap + one QR tip, chronological, no doubles');
    expect(fresh.map((d) => d.amountMinor).toList(), [700, 500]);
  });

  test('a tap already seen in an earlier poll is never counted twice',
      () async {
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [chargeEvent('evt_1', created: 10, object: charge('ch_tap'))],
        hasMore: false,
      ),
      // The backfill window (resume after a restart) re-reads the same charge.
      TipEventsPage(
        events: [chargeEvent('evt_1', created: 10, object: charge('ch_tap'))],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    expect((await source.pollNew()).single.id, 'ch_tap');
    expect(await source.pollNew(), isEmpty);
  });

  test('failed, unpaid and non-card-present charges never reach the jar',
      () async {
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [
          // A bank transfer / wallet payment in the account — not a tap.
          chargeEvent('evt_4',
              created: 40, object: charge('ch_bank', type: 'sepa_debit')),
          // Card-present, but the money didn't move.
          chargeEvent('evt_3',
              created: 30,
              object: charge('ch_failed', status: 'failed', paid: false)),
          chargeEvent('evt_2',
              created: 20, object: charge('ch_unpaid', paid: false)),
          // Someone typed a card into a Checkout page: card-not-present.
          chargeEvent('evt_1',
              created: 10, object: charge('ch_online', type: 'card')),
        ],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    expect(await source.pollNew(), isEmpty);
    expect(source.cursor, 'evt_4', reason: 'the cursor still advances');
  });

  // ------------------------------------------------- song request links ---

  test(
      'the two-way match: donation link → plain tip, mapped song link → '
      'request tip with the song stamped on, unmapped link → dropped',
      () async {
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [
          sessionEvent('evt_3',
              created: 30,
              session: paidSession('cs_stranger', link: 'plink_theirs')),
          sessionEvent('evt_2',
              created: 20, session: paidSession('cs_request', link: 'plink_song')),
          sessionEvent('evt_1', created: 10, session: paidSession('cs_plain')),
        ],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(
      requests,
      paymentLinkId: 'plink_ours',
      songLinks: {'plink_song': (songId: 'sng_1', title: 'Wonderwall')},
    );
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['cs_plain', 'cs_request'],
        reason: 'the stranger link is not ours and never reaches the stage');

    final plain = fresh[0];
    expect(plain.songId, isNull);
    expect(plain.songTitle, isNull);

    final request = fresh[1];
    expect(request.songId, 'sng_1');
    expect(request.songTitle, 'Wonderwall',
        reason: 'the title comes from the map — what the link was minted for');
    expect(request.amountMinor, 500);
    expect(request.verified, isTrue, reason: 'Stripe saw the money move');
  });

  test('an unpaid session through a mapped song link is still not a tip',
      () async {
    final unpaid = paidSession('cs_pending', link: 'plink_song')
      ..['payment_status'] = 'unpaid';
    final requests = FakeRequests([
      const TipEventsPage(events: [], hasMore: false),
      TipEventsPage(
        events: [sessionEvent('evt_1', created: 10, session: unpaid)],
        hasMore: false,
      ),
    ]);
    final source = StripeTipSource(
      requests,
      paymentLinkId: 'plink_ours',
      songLinks: {'plink_song': (songId: 'sng_1', title: 'Wonderwall')},
    );
    await source.prime(DateTime.now());

    expect(await source.pollNew(), isEmpty);
  });

  test('demo source produces tips', () async {
    final source = DemoTipSource();
    await source.prime(DateTime.now());
    final first = await source.pollNew();
    expect(first, hasLength(1)); // first tick always tips
    expect(first.single.amountMinor, greaterThan(0));
    expect(first.single.livemode, isFalse);
  });

  test('null source never produces tips (relay-only sessions)', () async {
    final source = NullTipSource();
    await source.prime(DateTime.now());
    expect(await source.pollNew(), isEmpty);
    expect(await source.pollNew(), isEmpty, reason: 'stays empty forever');
    expect(source.cursor, isNull);

    // Resume paths must be no-ops too, and dispose must not throw.
    await source.prime(DateTime.now(),
        resumeCursor: 'evt_stored', backfill: true);
    expect(await source.pollNew(), isEmpty);
    source.dispose();
  });
}
