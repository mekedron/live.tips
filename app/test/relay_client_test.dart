import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/domain/relay_jar.dart';

import 'helpers.dart';

const _jar = RelayJar(
  jarId: 'jar_abc',
  tipUrl: 'https://tip.live.tips/t/jar_abc',
  artistName: 'Maya',
  currency: 'eur',
  revolutUsername: 'mayamusic',
  createdAtMs: 0,
);

Map<String, dynamic> _created(Map<String, dynamic> _) => {
      'jarId': 'jar_abc',
      'secret': 's3cret',
      'tipUrl': 'https://tip.live.tips/t/jar_abc',
    };

void main() {
  test('createJar sends the profile and parses the jar + secret back',
      () async {
    final backend = FakeCallables({'createJar': _created});
    final client = fakeRelayClient(backend);

    final result = await client.createJar(
      artistName: 'Maya',
      message: 'Tips welcome!',
      currency: 'eur',
      stripeUrl: 'https://buy.stripe.com/x',
      revolutUsername: 'mayamusic',
    );

    expect(backend.names, ['createJar']);
    final profile = backend.argsFor('createJar')['profile'] as Map;
    expect(profile['artistName'], 'Maya');
    expect(profile['message'], 'Tips welcome!');
    expect(profile['currency'], 'eur');
    final methods = profile['methods'] as Map;
    expect(methods['stripeUrl'], 'https://buy.stripe.com/x');
    expect(methods['revolutUsername'], 'mayamusic');
    expect(methods.containsKey('mobilepayBoxId'), isFalse);

    expect(result.jar.jarId, 'jar_abc');
    expect(result.jar.tipUrl, 'https://tip.live.tips/t/jar_abc');
    expect(result.jar.revolutUsername, 'mayamusic');
    expect(result.jar.createdAtMs, greaterThan(0));
    expect(result.secret, 's3cret');
  });

  test('only a real account owns its jar — a transport-anonymous uid does not',
      () async {
    final transport = FakeCallables({'createJar': _created});
    await fakeRelayClient(transport)
        .createJar(artistName: 'M', currency: 'eur');
    expect(transport.argsFor('createJar').containsKey('owned'), isFalse,
        reason: 'a throwaway transport uid must never be pinned as ownerUid');

    final account = FakeCallables({'createJar': _created});
    await fakeRelayClient(account, auth: FakeRelayAuth(owned: true))
        .createJar(artistName: 'M', currency: 'eur');
    expect(account.argsFor('createJar')['owned'], isTrue);
  });

  test('artistName is clamped to the relay limit (50 code points) so a long '
      'Stripe display name is never rejected', () async {
    final backend = FakeCallables({'createJar': _created});

    await fakeRelayClient(backend)
        .createJar(artistName: 'A' * 80, currency: 'eur', revolutUsername: 'x');

    final profile = backend.argsFor('createJar')['profile'] as Map;
    expect((profile['artistName'] as String).length, 50);
  });

  test('an emoji-heavy name is clamped in the SERVER\'s units — code points '
      'and UTF-8 bytes, not grapheme clusters', () async {
    final backend = FakeCallables({'createJar': _created});
    // 40 flags: 40 graphemes but 80 code points and 320 UTF-8 bytes. The old
    // grapheme clamp sent this out untouched, and production refused it with
    // `invalid-argument` — the artist could not onboard at all (issue #20).
    // The enforcing FakeCallables now models that refusal, so this createJar
    // completing IS the assertion that the clamped output passes validate.ts.
    final flags = '🇫🇮' * 40;

    await fakeRelayClient(backend)
        .createJar(artistName: flags, currency: 'eur', revolutUsername: 'x');

    final sent = (backend.argsFor('createJar')['profile'] as Map)['artistName']
        as String;
    expect(sent.runes.length, lessThanOrEqualTo(50));
    expect(utf8.encode(sent).length, lessThanOrEqualTo(200));
    // Whole graphemes only: 25 flags are exactly 50 code points — the clamp
    // must never ship half a flag.
    expect(sent, '🇫🇮' * 25);
  });

  test('the message is clamped the same way, ZWJ sequences kept whole',
      () async {
    final backend = FakeCallables({'createJar': _created});
    // A family emoji is ONE grapheme but SEVEN code points (four people,
    // three zero-width joiners): 60 of them are 420 code points against the
    // relay's 200-code-point message cap.
    final families = '👨‍👩‍👧‍👦' * 60;

    await fakeRelayClient(backend).createJar(
      artistName: 'Maya',
      message: families,
      currency: 'eur',
      revolutUsername: 'x',
    );

    final sent =
        (backend.argsFor('createJar')['profile'] as Map)['message'] as String;
    expect(sent.runes.length, lessThanOrEqualTo(200));
    expect(utf8.encode(sent).length, lessThanOrEqualTo(800));
    // 28 × 7 = 196 code points fit; a 29th family would not — and no family
    // is ever cut in the middle of a joiner.
    expect(sent, '👨‍👩‍👧‍👦' * 28);
  });

  test('FakeCallables itself refuses an over-limit profile like production '
      'does — the guard the suite was missing', () async {
    final backend = FakeCallables({'createJar': _created});
    // Bypass the client's clamp by calling the fake directly: 26 flags are
    // only 26 graphemes but 52 code points — over the relay's 50.
    expect(
      () => backend.call('createJar', {
        'profile': {'artistName': '🇫🇮' * 26},
      }),
      throwsA(isA<FakeFunctionsException>()
          .having((e) => e.code, 'code', 'invalid-argument')),
    );
  });

  test('the authenticated calls carry the jar id and the secret', () async {
    final backend = FakeCallables({
      'rotateJarSecret': (_) => {'secret': 'new_secret'},
    });
    final client = fakeRelayClient(backend);

    await client.updateJar(
      jar: _jar,
      secret: 'old_secret',
      artistName: 'Maya',
      stripeUrl: 'https://buy.stripe.com/y',
    );
    await client.claimJar(jarId: 'jar_abc', secret: 'old_secret');
    await client.deleteJar(jarId: 'jar_abc', secret: 'old_secret');
    await client.markSeen(jarId: 'jar_abc', secret: 'old_secret');
    final rotated =
        await client.rotateSecret(jarId: 'jar_abc', secret: 'old_secret');

    expect(rotated, 'new_secret');
    expect(backend.names, [
      'updateJarProfile',
      'claimJar',
      'deleteJar',
      'jarSeen',
      'rotateJarSecret',
    ]);
    for (final call in backend.calls) {
      expect(call.args['jarId'], 'jar_abc', reason: call.name);
      expect(call.args['secret'], 'old_secret', reason: call.name);
    }
    // The update re-sends the jar's untouched methods alongside the new URL.
    final methods =
        (backend.argsFor('updateJarProfile')['profile'] as Map)['methods']
            as Map;
    expect(methods['revolutUsername'], 'mayamusic');
    expect(methods['stripeUrl'], 'https://buy.stripe.com/y');
  });

  test('unauthenticated and permission-denied are auth errors', () async {
    for (final code in ['unauthenticated', 'permission-denied']) {
      final client = fakeRelayClient(FakeCallables({
        'jarSeen': (_) => throw FakeFunctionsException(code, 'bad secret'),
      }));
      try {
        await client.markSeen(jarId: 'jar_abc', secret: 'stale');
        fail('expected RelayApiException for $code');
      } on RelayApiException catch (e) {
        expect(e.isAuthError, isTrue, reason: code);
        expect(e.isNotFound, isFalse, reason: code);
        expect(e.message, 'bad secret');
        expect(e.friendlyMessage, isNot('bad secret'),
            reason: 'auth errors get a human explanation');
      }
    }
  });

  test('not-found maps to RelayApiException.isNotFound', () async {
    final client = fakeRelayClient(FakeCallables({
      'deleteJar': (_) => throw FakeFunctionsException('not-found', 'gone'),
    }));
    expect(
      () => client.deleteJar(jarId: 'gone', secret: 's'),
      throwsA(isA<RelayApiException>()
          .having((e) => e.isNotFound, 'isNotFound', isTrue)
          .having((e) => e.isAuthError, 'isAuthError', isFalse)
          .having((e) => e.code, 'code', 'not-found')),
    );
  });

  test('a rate limit is neither an auth error nor a missing jar — it must '
      'never trigger a relink', () async {
    final client = fakeRelayClient(FakeCallables({
      'createJar': (_) => throw FakeFunctionsException('resource-exhausted'),
    }));
    expect(
      () => client.createJar(artistName: 'Maya', currency: 'eur'),
      throwsA(isA<RelayApiException>()
          .having((e) => e.isAuthError, 'isAuthError', isFalse)
          .having((e) => e.isNotFound, 'isNotFound', isFalse)
          .having((e) => e.friendlyMessage, 'friendlyMessage',
              contains('rate-limiting'))),
    );
  });

  test('a rejected profile surfaces the server sentence, unmapped', () async {
    final client = fakeRelayClient(FakeCallables({
      'updateJarProfile': (_) => throw FakeFunctionsException(
          'invalid-argument', 'artistName too long'),
    }));
    expect(
      () => client.updateJar(jar: _jar, secret: 's', artistName: 'Maya'),
      throwsA(isA<RelayApiException>()
          .having((e) => e.isAuthError, 'isAuthError', isFalse)
          .having((e) => e.isNotFound, 'isNotFound', isFalse)
          .having((e) => e.friendlyMessage, 'friendlyMessage',
              'artistName too long')),
    );
  });

  test('a call that never landed is a network failure, not a verdict',
      () async {
    for (final code in ['unavailable', 'deadline-exceeded']) {
      final client = fakeRelayClient(FakeCallables({
        'jarSeen': (_) => throw FakeFunctionsException(code),
      }));
      await expectLater(
        () => client.markSeen(jarId: 'jar_abc', secret: 's'),
        throwsA(isA<RelayNetworkException>()),
        reason: code,
      );
    }
  });

  test('any other failure is a network failure', () async {
    final client = fakeRelayClient(FakeCallables({
      'createJar': (_) => throw StateError('socket died'),
    }));
    expect(
      () => client.createJar(artistName: 'Maya', currency: 'eur'),
      throwsA(isA<RelayNetworkException>()),
    );
  });

  test('no transport identity → the call is never made, and it is NOT an auth '
      'error (a relay-less device must not churn its jar)', () async {
    final backend = FakeCallables({'jarSeen': _created});
    final client = fakeRelayClient(backend, auth: FakeRelayAuth(uid: null));

    await expectLater(
      () => client.markSeen(jarId: 'jar_abc', secret: 's'),
      throwsA(isA<RelayNetworkException>()),
    );
    expect(backend.calls, isEmpty);
  });
}
