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
