import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/donation_source.dart';
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
      'custom_fields': const [],
    };

class FakeRequests extends StripeRequests {
  FakeRequests(this.pages) : super(StripeClient('rk_test_fake'));

  final List<DonationEventsPage> pages;
  final List<String?> endingBeforeCalls = [];
  int _next = 0;

  @override
  Future<DonationEventsPage> listDonationEvents({
    String? endingBefore,
    int? createdGte,
    int limit = 100,
  }) async {
    endingBeforeCalls.add(endingBefore);
    if (_next >= pages.length) {
      return const DonationEventsPage(events: [], hasMore: false);
    }
    return pages[_next++];
  }
}

void main() {
  test('prime anchors on the newest existing event', () async {
    final requests = FakeRequests([
      DonationEventsPage(
        events: [
          DonationEvent(
              id: 'evt_anchor', created: 1, session: paidSession('cs_old')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeDonationSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());
    expect(source.cursor, 'evt_anchor');

    // Nothing new yet → no donations, cursor unchanged.
    final none = await source.pollNew();
    expect(none, isEmpty);
    expect(source.cursor, 'evt_anchor');
    expect(requests.endingBeforeCalls.last, 'evt_anchor');
  });

  test('pollNew returns fresh donations chronologically and advances cursor',
      () async {
    final requests = FakeRequests([
      // prime call
      const DonationEventsPage(events: [], hasMore: false),
      // first poll: two new events, newest first (Stripe order)
      DonationEventsPage(
        events: [
          DonationEvent(
              id: 'evt_2', created: 20, session: paidSession('cs_b')),
          DonationEvent(
              id: 'evt_1', created: 10, session: paidSession('cs_a')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeDonationSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['cs_a', 'cs_b']);
    expect(source.cursor, 'evt_2');
  });

  test('filters other links, unpaid sessions, and duplicate donations',
      () async {
    final unpaid = paidSession('cs_unpaid')..['payment_status'] = 'unpaid';
    final requests = FakeRequests([
      const DonationEventsPage(events: [], hasMore: false),
      DonationEventsPage(
        events: [
          // duplicate pair: completed + async_payment_succeeded for cs_dup
          DonationEvent(
              id: 'evt_5', created: 50, session: paidSession('cs_dup')),
          DonationEvent(
              id: 'evt_4', created: 40, session: paidSession('cs_dup')),
          DonationEvent(id: 'evt_3', created: 30, session: unpaid),
          DonationEvent(
              id: 'evt_2',
              created: 20,
              session: paidSession('cs_other', link: 'plink_theirs')),
          DonationEvent(
              id: 'evt_1', created: 10, session: paidSession('cs_ok')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeDonationSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now());

    final fresh = await source.pollNew();
    expect(fresh.map((d) => d.id).toList(), ['cs_ok', 'cs_dup']);
    expect(source.cursor, 'evt_5');
  });

  test('resume cursor is used verbatim', () async {
    final requests = FakeRequests([
      DonationEventsPage(
        events: [
          DonationEvent(
              id: 'evt_9', created: 90, session: paidSession('cs_missed')),
        ],
        hasMore: false,
      ),
    ]);
    final source =
        StripeDonationSource(requests, paymentLinkId: 'plink_ours');
    await source.prime(DateTime.now(), resumeCursor: 'evt_stored');

    final fresh = await source.pollNew();
    expect(requests.endingBeforeCalls.first, 'evt_stored');
    expect(fresh.single.id, 'cs_missed');
  });

  test('demo source produces donations', () async {
    final source = DemoDonationSource();
    await source.prime(DateTime.now());
    final first = await source.pollNew();
    expect(first, hasLength(1)); // first tick always tips
    expect(first.single.amountMinor, greaterThan(0));
    expect(first.single.livemode, isFalse);
  });
}
