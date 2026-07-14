import 'dart:math';

import '../domain/tip.dart';
import '../domain/tip_method.dart';
import 'stripe/stripe_requests.dart';

/// Feeds a live session with newly arrived tips. The session controller
/// calls [pollNew] on a timer; the source keeps its own cursor.
abstract class TipSource {
  /// Prepares the cursor. [resumeCursor] restores a session after an app
  /// restart so tips made in between are still picked up. [backfill]
  /// (resumed sessions only) means: even without a cursor, everything since
  /// [sessionStart] must be re-fetched — tips that arrived while the app was
  /// dead or the machine slept belong to the session; the caller dedupes.
  Future<void> prime(DateTime sessionStart,
      {String? resumeCursor, bool backfill = false});

  /// Returns only tips not seen before (chronological order).
  Future<List<Tip>> pollNew();

  /// Opaque cursor to persist for crash/restart recovery.
  String? get cursor;

  void dispose() {}
}

/// Polls the artist's own Stripe account via `/v1/events`, which is what lets
/// this app run on a tablet on a stage with no server anywhere. Stripe
/// recommends webhooks; a stage device has no public HTTPS endpoint to receive
/// one, so we poll a documented endpoint deliberately. Stripe's read allocation
/// (~500 reads/transaction, 10k/month floor) is why the default tick is 4 s.
class StripeTipSource extends TipSource {
  StripeTipSource(this._requests,
      {required this.paymentLinkId,
      this.songLinks = const {},
      this.onDispose});

  final StripeRequests _requests;
  final String paymentLinkId;

  /// Payment-link id → the song its checkout sessions request (#64) — the
  /// device-side twin of the webhook's `requestLinks` gate, fed from the
  /// band's `SongEntry.stripe` records at session start. App-minted song
  /// links exist ONLY here: the server's connection doc is server-custody,
  /// so the poller is what recognizes them. Snapshot semantics, like
  /// [paymentLinkId]: a song minted mid-session is picked up next session.
  final Map<String, ({String songId, String title})> songLinks;

  /// Owns-its-client hook: the session source must NEVER share an HTTP
  /// client with rebuildable providers (a provider rebuild used to close
  /// the client mid-session → every poll failed with "Client is already
  /// closed" until the session ended).
  final void Function()? onDispose;

  @override
  void dispose() => onDispose?.call();

  String? _cursor;
  int? _createdGte;
  final Set<String> _seenTipIds = {};

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
      // Duplicates are cheap (the session dedupes by tip id); losing a
      // tip that arrived while the app was dead is not.
      _createdGte =
          sessionStart.toUtc().millisecondsSinceEpoch ~/ 1000 - 60;
      return;
    }
    // Fresh start: anchor on the newest existing event so we only see what
    // happens after "Start". Falls back to a server-time window when the
    // account has no recent events (device clocks can drift, hence the
    // safety margin).
    final page = await _requests.listTipEvents(limit: 1);
    if (page.events.isNotEmpty) {
      _cursor = page.events.first.id;
    } else {
      _createdGte =
          sessionStart.toUtc().millisecondsSinceEpoch ~/ 1000 - 60;
    }
  }

  @override
  Future<List<Tip>> pollNew() async {
    final fresh = <Tip>[];
    // With `ending_before`, Stripe returns the events immediately newer than
    // the cursor; keep advancing until has_more is false. Page cap is a
    // safety valve — 500 new tips per tick would be a great problem.
    for (var page = 0; page < 5; page++) {
      final result = await _requests.listTipEvents(
        endingBefore: _cursor,
        createdGte: _cursor == null ? _createdGte : null,
      );
      if (result.events.isEmpty) break;

      for (final event in result.events.reversed) {
        final tip = _tipOf(event);
        if (tip == null) continue;
        // completed + async_payment_succeeded can both fire for one payment.
        if (_seenTipIds.add(tip.id)) fresh.add(tip);
      }

      _cursor = result.events.first.id;
      if (!result.hasMore) break;
    }
    return fresh;
  }

  /// The tip an event represents, or null if it is not one of ours.
  ///
  /// Two paths, and the whole correctness of the jar lives in keeping them
  /// disjoint:
  ///
  /// * **Online (QR).** A Checkout Session against *our* payment link, paid.
  ///   Two-way now (#64): the tip jar's link is a plain tip, exactly as
  ///   before; a link in [songLinks] is the same tip plus the song it
  ///   requested. Any other link — the artist's unrelated business, or a
  ///   song link this device re-minted and no longer knows — is still null.
  /// * **In person (tap).** A Charge, but ONLY a card-present one. This is the
  ///   trap: a Checkout Session payment also emits `charge.succeeded`, so
  ///   accepting charges naively would count every QR tip twice — once as the
  ///   session, once as its own charge, under two different ids that no
  ///   de-duplication could ever tie together. The card the reader taps is
  ///   card-*present*; the card a fan types into a Checkout page is not. That
  ///   one field is the whole guard, so it is asserted on the discriminator
  ///   ([Tip.isCardPresentCharge]) rather than inferred.
  ///
  /// The in-person path can't be narrowed to our payment link — a tap has no
  /// link, no product, no Checkout Session, nothing of ours on it at all. So
  /// it rests on the documented assumption (docs/architecture.md,
  /// docs/onboarding/create-restricted-key.md) that the artist's Stripe account
  /// is dedicated to tips: any card-present payment in it is a tip. Sell merch
  /// through the same account and the merch sale lands in the jar.
  Tip? _tipOf(TipEvent event) {
    final object = event.object;
    if (event.isCheckoutSession) {
      if (object['payment_status'] != 'paid') return null;
      final link = object['payment_link'];
      if (link == paymentLinkId) return Tip.fromCheckoutSession(object);
      final song = link is String ? songLinks[link] : null;
      if (song == null) return null;
      // A request: the same verified tip, with the song stamped on. The
      // title comes from the map — what the link was minted FOR — so a
      // later library rename never rewrites what the fan paid for.
      return Tip.fromCheckoutSession(object)
          .copyWith(songId: song.songId, songTitle: song.title);
    }
    // charge.succeeded — the only other type we ask Stripe for.
    if (!Tip.isCardPresentCharge(object)) return null;
    return Tip.fromCardPresentCharge(object);
  }
}

/// A source that never produces anything — for live sessions with no Stripe
/// account to poll (relay-only installs). Deliberately NOT the demo source:
/// a real session must never be fed fake tips. Relay tips arrive over their
/// own channel, wired into the session separately.
class NullTipSource extends TipSource {
  @override
  String? get cursor => null;

  @override
  Future<void> prime(DateTime sessionStart,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async => const [];
}

/// Generates believable tips so the whole app can be experienced
/// without a Stripe account.
class DemoTipSource extends TipSource {
  DemoTipSource({Random? random}) : _random = random ?? Random();

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
  Future<List<Tip>> pollNew() async {
    // First tick always tips, so the demo feels alive immediately.
    final roll = _random.nextDouble();
    final count = _first ? 1 : (roll < 0.55 ? 0 : (roll > 0.92 ? 2 : 1));
    _first = false;
    return List.generate(count, (_) {
      _counter++;
      // ~25% of demo tips arrive "through the tip page" (Revolut/MobilePay,
      // unverified) so the badges and the QR toggle can be experienced too.
      final method = _random.nextDouble() < 0.25
          ? (_random.nextBool() ? TipMethod.revolut : TipMethod.mobilepay)
          : TipMethod.stripe;
      return Tip(
        id: 'demo_$_counter',
        amountMinor: _amounts[_random.nextInt(_amounts.length)],
        currency: 'usd',
        createdAt: DateTime.now(),
        name: _names[_random.nextInt(_names.length)],
        message: _messages[_random.nextInt(_messages.length)],
        livemode: false,
        method: method,
        verified: method == TipMethod.stripe,
      );
    });
  }
}
