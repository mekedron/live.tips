import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/stripe/stripe_client.dart';
import 'package:live_tips/data/stripe/stripe_requests.dart';
import 'package:live_tips/data/stripe/stripe_song_link_sync.dart';
import 'package:live_tips/domain/song_request_settings.dart';

import 'helpers.dart';

// Assembled, never literal — see stripe_requests_test.dart.
final _apiKey = ['rk', 'test', 'sync_fake'].join('_');

/// Scripted minter: records every call, mints predictable ids, and fails
/// exactly the songs the test names.
class _FakeMinter extends StripeRequests {
  _FakeMinter({
    this.failCreates = const {},
    this.failDeactivations = const {},
    this.capAfter,
  }) : super(StripeClient(_apiKey));

  /// Song ids whose create must throw (a generic Stripe error).
  final Set<String> failCreates;

  /// Payment link ids whose deactivate must throw.
  final Set<String> failDeactivations;

  /// After this many successful creates, every further create throws the
  /// server proxy's lifetime-cap refusal.
  final int? capAfter;

  final List<({String songId, String title, int priceMinor, String currency})>
      created = [];
  final List<String> deactivated = [];

  @override
  Future<StripeSongLink> createSongLink({
    required String songId,
    required String title,
    required int priceMinor,
    required String currency,
  }) async {
    if (failCreates.contains(songId)) {
      throw const StripeApiException(statusCode: 402, message: 'no');
    }
    if (capAfter != null && created.length >= capAfter!) {
      throw FakeFunctionsException(
          'failed-precondition', 'this connection already tracks 200 links');
    }
    created.add(
        (songId: songId, title: title, priceMinor: priceMinor, currency: currency));
    final n = created.length;
    return StripeSongLink(
      productId: 'prod_$n',
      priceId: 'price_$n',
      paymentLinkId: 'plink_$n',
      url: 'https://buy.stripe.com/test_$n',
      priceMinor: priceMinor,
      title: title,
    );
  }

  @override
  Future<void> deactivateSongLink(String paymentLinkId) async {
    if (failDeactivations.contains(paymentLinkId)) {
      throw const StripeNetworkException('offline');
    }
    deactivated.add(paymentLinkId);
  }
}

SongEntry _song(String id, String title, {int? priceMinor, StripeSongLink? stripe}) =>
    SongEntry(id: id, title: title, priceMinor: priceMinor, stripe: stripe);

StripeSongLink _record(String plink,
        {required int priceMinor, required String title}) =>
    StripeSongLink(
      productId: 'prod_$plink',
      priceId: 'price_$plink',
      paymentLinkId: plink,
      url: 'https://buy.stripe.com/$plink',
      priceMinor: priceMinor,
      title: title,
    );

void main() {
  test('songs without a record get one minted at their effective price',
      () async {
    final minter = _FakeMinter();
    final next = SongRequestSettings(
      enabled: true,
      defaultPriceMinor: 500,
      methods: const ['stripe'],
      songs: [
        _song('sng_a', 'Wonderwall'), // default price
        _song('sng_b', 'Yesterday', priceMinor: 900), // override
      ],
    );

    final outcome = await StripeSongLinkSync(minter).sync(
        previousSongs: next.songs, next: next, currency: 'eur');

    expect(minter.created, [
      (songId: 'sng_a', title: 'Wonderwall', priceMinor: 500, currency: 'eur'),
      (songId: 'sng_b', title: 'Yesterday', priceMinor: 900, currency: 'eur'),
    ]);
    expect(minter.deactivated, isEmpty);
    expect(outcome.failures, 0);
    expect(outcome.capReached, isFalse);
    expect(outcome.songs.map((s) => s.stripe?.paymentLinkId).toList(),
        ['plink_1', 'plink_2']);
    expect(outcome.songs.first.stripe!.priceMinor, 500);
  });

  test('a fresh record is left completely alone', () async {
    final minter = _FakeMinter();
    final song = _song('sng_a', 'Wonderwall',
        stripe: _record('plink_old', priceMinor: 500, title: 'Wonderwall'));
    final next = SongRequestSettings(
        enabled: true, defaultPriceMinor: 500, songs: [song]);

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: [song], next: next, currency: 'eur');

    expect(minter.created, isEmpty);
    expect(minter.deactivated, isEmpty);
    expect(outcome.songs.single, same(song));
  });

  test(
      'price drift — including a DEFAULT price change under a song with no '
      'override — retires the old link and mints a replacement', () async {
    final minter = _FakeMinter();
    final song = _song('sng_a', 'Wonderwall',
        stripe: _record('plink_old', priceMinor: 500, title: 'Wonderwall'));
    // The artist raised the default; the song has no override, so its
    // effective price moved even though the song itself was not touched.
    final next = SongRequestSettings(
        enabled: true, defaultPriceMinor: 700, songs: [song]);

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: [song], next: next, currency: 'eur');

    expect(minter.deactivated, ['plink_old']);
    expect(minter.created.single.priceMinor, 700);
    expect(outcome.songs.single.stripe!.paymentLinkId, 'plink_1');
    expect(outcome.failures, 0);
  });

  test('a title change is the same surgery — deactivate + create, never a '
      'rename (the record title is what attribution was minted for)',
      () async {
    final minter = _FakeMinter();
    final song = _song('sng_a', 'Wonderwal (fixed)',
        stripe: _record('plink_old', priceMinor: 500, title: 'Wonderwal'));
    final next = SongRequestSettings(
        enabled: true, defaultPriceMinor: 500, songs: [song]);

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: [song], next: next, currency: 'eur');

    expect(minter.deactivated, ['plink_old']);
    expect(minter.created.single.title, 'Wonderwal (fixed)');
    expect(outcome.songs.single.stripe!.title, 'Wonderwal (fixed)');
  });

  test('a deleted song has its link retired', () async {
    final minter = _FakeMinter();
    final gone = _song('sng_gone', 'Freebird',
        stripe: _record('plink_gone', priceMinor: 500, title: 'Freebird'));
    final kept = _song('sng_kept', 'Wonderwall',
        stripe: _record('plink_kept', priceMinor: 500, title: 'Wonderwall'));
    final next = SongRequestSettings(
        enabled: true, defaultPriceMinor: 500, songs: [kept]);

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: [gone, kept], next: next, currency: 'eur');

    expect(minter.deactivated, ['plink_gone']);
    expect(minter.created, isEmpty);
    expect(outcome.failures, 0);
    expect(outcome.songs.single.stripe!.paymentLinkId, 'plink_kept');
  });

  test('one song failing never stops the others; the failure is counted and '
      'the song keeps no record, so the next save retries it', () async {
    final minter = _FakeMinter(failCreates: {'sng_b'});
    final next = SongRequestSettings(
      enabled: true,
      defaultPriceMinor: 500,
      songs: [
        _song('sng_a', 'First'),
        _song('sng_b', 'Cursed'),
        _song('sng_c', 'Third'),
      ],
    );

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: next.songs, next: next, currency: 'eur');

    expect(minter.created.map((c) => c.songId).toList(), ['sng_a', 'sng_c']);
    expect(outcome.failures, 1);
    expect(outcome.capReached, isFalse);
    expect(outcome.songs.map((s) => s.stripe?.paymentLinkId).toList(),
        ['plink_1', null, 'plink_2']);
  });

  test('the lifetime cap stops further creates — but deactivations still '
      'run, and the stale record is cleared rather than left selling wrong',
      () async {
    final minter = _FakeMinter(capAfter: 1);
    final stale = _song('sng_b', 'Stale',
        stripe: _record('plink_stale', priceMinor: 300, title: 'Stale'));
    final next = SongRequestSettings(
      enabled: true,
      defaultPriceMinor: 500,
      songs: [
        _song('sng_a', 'First'), // gets the last create under the cap
        stale, // price drifted: retire, then hit the cap
        _song('sng_c', 'Third'), // no create even attempted
      ],
    );

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: next.songs, next: next, currency: 'eur');

    expect(minter.created.map((c) => c.songId).toList(), ['sng_a']);
    expect(minter.deactivated, ['plink_stale'],
        reason: 'the wrong-price link must not stay live');
    expect(outcome.capReached, isTrue);
    expect(outcome.failures, 0,
        reason: 'the cap is its own verdict, not a per-song failure');
    expect(outcome.songs.map((s) => s.stripe?.paymentLinkId).toList(),
        ['plink_1', null, null]);
  });

  test('a failed deactivate of a stale link keeps the record — the link is '
      'still live, and forgetting it would orphan it', () async {
    final minter = _FakeMinter(failDeactivations: {'plink_stale'});
    final stale = _song('sng_a', 'Stale',
        stripe: _record('plink_stale', priceMinor: 300, title: 'Stale'));
    final next = SongRequestSettings(
        enabled: true, defaultPriceMinor: 500, songs: [stale]);

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: [stale], next: next, currency: 'eur');

    expect(minter.created, isEmpty,
        reason: 'no replacement while the old link still sells');
    expect(outcome.failures, 1);
    expect(outcome.songs.single.stripe!.paymentLinkId, 'plink_stale');
  });

  test('a failed deactivate of a DELETED song is a counted failure', () async {
    final minter = _FakeMinter(failDeactivations: {'plink_gone'});
    final gone = _song('sng_gone', 'Freebird',
        stripe: _record('plink_gone', priceMinor: 500, title: 'Freebird'));
    final next = SongRequestSettings(
        enabled: true, defaultPriceMinor: 500, songs: const []);

    final outcome = await StripeSongLinkSync(minter)
        .sync(previousSongs: [gone], next: next, currency: 'eur');

    expect(outcome.failures, 1);
    expect(outcome.songs, isEmpty);
  });
}
