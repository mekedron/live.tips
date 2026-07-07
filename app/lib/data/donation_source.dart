import 'dart:math';

import '../domain/donation.dart';
import 'stripe/stripe_requests.dart';

/// Feeds a live session with newly arrived donations. The session controller
/// calls [pollNew] on a timer; the source keeps its own cursor.
abstract class DonationSource {
  /// Prepares the cursor. [resumeCursor] restores a session after an app
  /// restart so donations made in between are still picked up. [backfill]
  /// (resumed sessions only) means: even without a cursor, everything since
  /// [sessionStart] must be re-fetched — tips that arrived while the app was
  /// dead or the machine slept belong to the session; the caller dedupes.
  Future<void> prime(DateTime sessionStart,
      {String? resumeCursor, bool backfill = false});

  /// Returns only donations not seen before (chronological order).
  Future<List<Donation>> pollNew();

  /// Opaque cursor to persist for crash/restart recovery.
  String? get cursor;

  void dispose() {}
}

/// Polls the artist's own Stripe account via `/v1/events` — the documented
/// webhook alternative, which is what lets this app run on a tablet on a
/// stage with no server anywhere.
class StripeDonationSource extends DonationSource {
  StripeDonationSource(this._requests,
      {required this.paymentLinkId, this.onDispose});

  final StripeRequests _requests;
  final String paymentLinkId;

  /// Owns-its-client hook: the session source must NEVER share an HTTP
  /// client with rebuildable providers (a provider rebuild used to close
  /// the client mid-session → every poll failed with "Client is already
  /// closed" until the session ended).
  final void Function()? onDispose;

  @override
  void dispose() => onDispose?.call();

  String? _cursor;
  int? _createdGte;
  final Set<String> _seenDonationIds = {};

  @override
  String? get cursor => _cursor;

  @override
  Future<void> prime(DateTime sessionStart,
      {String? resumeCursor, bool backfill = false}) async {
    if (resumeCursor != null) {
      _cursor = resumeCursor;
      return;
    }
    if (backfill) {
      // Resumed session without a cursor: re-read the whole session window.
      // Duplicates are cheap (the session dedupes by donation id); losing a
      // tip that arrived while the app was dead is not.
      _createdGte =
          sessionStart.toUtc().millisecondsSinceEpoch ~/ 1000 - 60;
      return;
    }
    // Fresh start: anchor on the newest existing event so we only see what
    // happens after "Start". Falls back to a server-time window when the
    // account has no recent events (device clocks can drift, hence the
    // safety margin).
    final page = await _requests.listDonationEvents(limit: 1);
    if (page.events.isNotEmpty) {
      _cursor = page.events.first.id;
    } else {
      _createdGte =
          sessionStart.toUtc().millisecondsSinceEpoch ~/ 1000 - 60;
    }
  }

  @override
  Future<List<Donation>> pollNew() async {
    final fresh = <Donation>[];
    // With `ending_before`, Stripe returns the events immediately newer than
    // the cursor; keep advancing until has_more is false. Page cap is a
    // safety valve — 500 new donations per tick would be a great problem.
    for (var page = 0; page < 5; page++) {
      final result = await _requests.listDonationEvents(
        endingBefore: _cursor,
        createdGte: _cursor == null ? _createdGte : null,
      );
      if (result.events.isEmpty) break;

      for (final event in result.events.reversed) {
        final session = event.session;
        if (session['payment_link'] != paymentLinkId) continue;
        if (session['payment_status'] != 'paid') continue;
        final donation = Donation.fromCheckoutSession(session);
        // completed + async_payment_succeeded can both fire for one payment.
        if (_seenDonationIds.add(donation.id)) fresh.add(donation);
      }

      _cursor = result.events.first.id;
      if (!result.hasMore) break;
    }
    return fresh;
  }
}

/// A source that never produces anything — for live sessions with no Stripe
/// account to poll (relay-only installs). Deliberately NOT the demo source:
/// a real session must never be fed fake tips. Relay tips arrive over their
/// own channel, wired into the session separately.
class NullDonationSource extends DonationSource {
  @override
  String? get cursor => null;

  @override
  Future<void> prime(DateTime sessionStart,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Donation>> pollNew() async => const [];
}

/// Generates believable donations so the whole app can be experienced
/// without a Stripe account.
class DemoDonationSource extends DonationSource {
  DemoDonationSource({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _counter = 0;
  bool _first = true;

  static const _amounts = [200, 300, 500, 500, 500, 1000, 1000, 2000, 2500, 5000, 10000];
  static const _names = [
    'Maya', 'Tom', 'Anonymous fan', 'Sofia', 'Jules', 'Nick', 'Emma & Leo',
    'The couple at table 3', 'Marta', 'Sam', 'Oli', 'Kasia',
  ];
  static const _messages = [
    'You made my night! 🎶',
    'Play one more!',
    'Greetings from Lisbon 🌊',
    'That cover was unreal',
    'Keep the music alive ❤️',
    'For the encore!',
    null,
    null,
    'Best street act in town',
    'My kid is dancing, thank you!',
  ];

  @override
  String? get cursor => null;

  @override
  Future<void> prime(DateTime sessionStart,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Donation>> pollNew() async {
    // First tick always tips, so the demo feels alive immediately.
    final roll = _random.nextDouble();
    final count = _first ? 1 : (roll < 0.55 ? 0 : (roll > 0.92 ? 2 : 1));
    _first = false;
    return List.generate(count, (_) {
      _counter++;
      return Donation(
        id: 'demo_$_counter',
        amountMinor: _amounts[_random.nextInt(_amounts.length)],
        currency: 'usd',
        createdAt: DateTime.now(),
        name: _names[_random.nextInt(_names.length)],
        message: _messages[_random.nextInt(_messages.length)],
        livemode: false,
      );
    });
  }
}
