import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/song_request_settings.dart';

const _link = StripeSongLink(
  productId: 'prod_1',
  priceId: 'price_1',
  paymentLinkId: 'plink_1',
  url: 'https://buy.stripe.com/song_1',
  priceMinor: 750,
  title: 'Wonderwall',
);

void main() {
  group('SongRequestSettings', () {
    test('defaults: disabled, empty, 5.00 default price', () {
      const settings = SongRequestSettings();
      expect(settings.enabled, isFalse);
      expect(settings.defaultPriceMinor, 500);
      expect(settings.methods, isEmpty);
      expect(settings.songs, isEmpty);
    });

    test('everything survives a json round trip', () {
      const settings = SongRequestSettings(
        enabled: true,
        defaultPriceMinor: 700,
        methods: ['stripe', 'revolut'],
        songs: [
          SongEntry(id: 'sng_a1', title: 'Wonderwall', artist: 'Oasis'),
          SongEntry(id: 'sng_b2', title: 'Yesterday', priceMinor: 1000),
          SongEntry(id: 'sng_c3', title: 'Linked song', stripe: _link),
        ],
      );
      final restored = SongRequestSettings.fromJson(settings.toJson());
      expect(restored, settings);
      expect(restored.songs[0].artist, 'Oasis');
      expect(restored.songs[0].priceMinor, isNull);
      expect(restored.songs[1].priceMinor, 1000);
      expect(restored.songs[2].stripe, _link);
    });

    test('copyWith replaces only what it names', () {
      const settings = SongRequestSettings(enabled: true, methods: ['stripe']);
      final next = settings.copyWith(defaultPriceMinor: 900);
      expect(next.enabled, isTrue);
      expect(next.methods, ['stripe']);
      expect(next.defaultPriceMinor, 900);
    });

    test('garbage decodes to the defaults — every field independently', () {
      final restored = SongRequestSettings.fromJson({
        'enabled': 'yes',
        'defaultPriceMinor': 'a lot',
        'methods': 'stripe',
        'songs': {'not': 'a list'},
        'somethingNew': true,
      });
      expect(restored, const SongRequestSettings());
    });

    test('malformed songs and non-string methods are dropped one by one, '
        'good ones kept', () {
      final restored = SongRequestSettings.fromJson({
        'enabled': true,
        'methods': ['revolut', 42, null, 'monzo'],
        'songs': [
          {'id': 'sng_good', 'title': 'Kept'},
          {'id': 'sng_good2', 'title': ''}, // empty title → not a song
          {'id': 'not a valid id!', 'title': 'Bad id'},
          {'title': 'No id at all'},
          'not even a map',
          // A broken price or link record degrades alone; the song stays.
          {
            'id': 'sng_good3',
            'title': 'Half broken',
            'priceMinor': 'seven',
            'stripe': {'url': 'https://x', 'productId': 42},
          },
        ],
      });
      expect(restored.methods, ['revolut', 'monzo']);
      expect(restored.songs.map((s) => s.id), ['sng_good', 'sng_good3']);
      expect(restored.songs[1].priceMinor, isNull);
      expect(restored.songs[1].stripe, isNull);
    });
  });

  group('SongEntry', () {
    test('mintId is id-shaped and unique-ish', () {
      final seen = <String>{};
      final rng = Random(7);
      for (var i = 0; i < 200; i++) {
        final id = SongEntry.mintId(random: rng);
        expect(SongEntry.idPattern.hasMatch(id), isTrue, reason: id);
        expect(id, startsWith('sng_'));
        expect(id.length, lessThanOrEqualTo(32));
        seen.add(id);
      }
      expect(seen, hasLength(200));
    });

    test('copyWith can null the optional fields', () {
      const song = SongEntry(
        id: 'sng_a1',
        title: 'Wonderwall',
        artist: 'Oasis',
        priceMinor: 700,
        stripe: _link,
      );
      final cleared =
          song.copyWith(artist: null, priceMinor: null, stripe: null);
      expect(cleared.artist, isNull);
      expect(cleared.priceMinor, isNull);
      expect(cleared.stripe, isNull);
      expect(cleared.title, 'Wonderwall');
      // And an unrelated copy leaves them alone.
      expect(song.copyWith(title: 'Wonderwall II').stripe, _link);
    });

    test('json omits absent optionals', () {
      const song = SongEntry(id: 'sng_a1', title: 'Wonderwall');
      expect(song.toJson(), {'id': 'sng_a1', 'title': 'Wonderwall'});
    });
  });

  group('StripeSongLink', () {
    test('round trips', () {
      expect(StripeSongLink.fromJson(_link.toJson()), _link);
    });

    test('an incomplete record is null — never a half-trusted link', () {
      final full = _link.toJson();
      for (final key in full.keys) {
        final broken = Map<String, dynamic>.from(full)..remove(key);
        expect(StripeSongLink.fromJson(broken), isNull, reason: key);
      }
      expect(StripeSongLink.fromJson('nope'), isNull);
      expect(StripeSongLink.fromJson(null), isNull);
    });
  });

  group('requestMethodEligible', () {
    test('stripe and revolut take any currency', () {
      for (final currency in ['eur', 'gbp', 'usd', 'dkk']) {
        expect(requestMethodEligible('stripe', currency), isTrue);
        expect(requestMethodEligible('revolut', currency), isTrue);
      }
    });

    test('mobilepay is EUR-only, monzo GBP-only, case-insensitive', () {
      expect(requestMethodEligible('mobilepay', 'eur'), isTrue);
      expect(requestMethodEligible('mobilepay', 'EUR'), isTrue);
      expect(requestMethodEligible('mobilepay', 'dkk'), isFalse);
      expect(requestMethodEligible('monzo', 'gbp'), isTrue);
      expect(requestMethodEligible('monzo', 'eur'), isFalse);
    });

    test('an unknown method is never eligible', () {
      expect(requestMethodEligible('paypal', 'eur'), isFalse);
    });
  });

  group('stripeLinkTargets', () {
    test('maps only linked songs, keyed by payment link, titled as minted',
        () {
      const linked = SongEntry(
        id: 'sng_a',
        title: 'Wonderwall (live)',
        stripe: StripeSongLink(
          productId: 'prod_1',
          priceId: 'price_1',
          paymentLinkId: 'plink_1',
          url: 'https://buy.stripe.com/x',
          priceMinor: 500,
          title: 'Wonderwall',
        ),
      );
      const bare = SongEntry(id: 'sng_b', title: 'Yesterday');
      const settings = SongRequestSettings(songs: [linked, bare]);

      expect(settings.stripeLinkTargets, {
        // The record's title — what the link was minted FOR — not the
        // song's current one: a rename must not rewrite attribution.
        'plink_1': (songId: 'sng_a', title: 'Wonderwall'),
      });
    });
  });
}
