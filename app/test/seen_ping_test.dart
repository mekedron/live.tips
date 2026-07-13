import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/seen_ping.dart';

import 'helpers.dart';

const _jar = RelayJar(
  jarId: 'jar_ping',
  tipUrl: 'https://tip.live.tips/t/jar_ping',
  artistName: 'Maya',
  currency: 'eur',
  revolutUsername: 'maya',
  createdAtMs: 0,
);

Map<String, dynamic> _createdJar(Map<String, dynamic> _) => {
      'jarId': 'jar_new',
      'secret': 'newsecret',
      'tipUrl': 'https://tip.live.tips/t/jar_new',
    };

/// A relay client that records every callable and answers each from [routes];
/// anything unrouted succeeds silently.
(RelayClient, FakeCallables) _client([
  Map<String, Map<String, dynamic> Function(Map<String, dynamic>)> routes =
      const {},
]) {
  final backend = FakeCallables(routes);
  return (fakeRelayClient(backend), backend);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime(2026, 7, 7, 12);
  final service = SeenPingService();

  test('never synced → pushes the full profile (incl. stripeUrl) and stores '
      'the timestamp', () async {
    final store = await seededStore();
    final (client, backend) = _client();

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      stripeUrl: 'https://buy.stripe.com/test_abc',
      now: () => t0,
    );

    expect(backend.names, ['updateJarProfile']);
    final args = backend.argsFor('updateJarProfile');
    expect(args['jarId'], 'jar_ping');
    expect(args['secret'], 's');
    final methods = (args['profile'] as Map)['methods'] as Map;
    expect(methods['stripeUrl'], 'https://buy.stripe.com/test_abc');
    expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
  });

  test('within 24 h → stays quiet, timestamp untouched', () async {
    final store = await seededStore();
    await store.writeRelaySeenAt(kTestAccountId, t0.millisecondsSinceEpoch);
    final (client, backend) = _client();

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      now: () => t0.add(const Duration(hours: 23, minutes: 59)),
    );

    expect(backend.calls, isEmpty);
    expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
  });

  test('a rejected profile (invalid-argument) never recreates and writes no '
      'timestamp', () async {
    final store = await seededStore();
    final (client, backend) = _client({
      'updateJarProfile': (_) =>
          throw FakeFunctionsException('invalid-argument', 'bad'),
    });
    var relinked = false;

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      onRelinked: (a, b, cc) async => relinked = true,
      now: () => t0,
    );

    expect(backend.names, ['updateJarProfile'], reason: 'no recreate');
    expect(relinked, isFalse);
    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  test('network failure is swallowed and writes no timestamp', () async {
    final store = await seededStore();
    final (client, _) = _client({
      'updateJarProfile': (_) => throw FakeFunctionsException('unavailable'),
    });

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      now: () => t0,
    );

    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  for (final code in ['not-found', 'unauthenticated', 'permission-denied']) {
    test('a dead jar ($code) is recreated with the same profile and the old '
        'URL is reported', () async {
      final store = await seededStore();
      final (client, backend) = _client({
        'updateJarProfile': (_) => throw FakeFunctionsException(code, 'gone'),
        'createJar': _createdJar,
      });
      RelayJar? newJar;
      String? newSecret;
      String? oldUrl;

      await service.maybePing(
        store: store,
        accountId: kTestAccountId,
        jar: _jar,
        secret: 's',
        client: client,
        stripeUrl: 'https://buy.stripe.com/test_abc',
        onRelinked: (j, s, old) async {
          newJar = j;
          newSecret = s;
          oldUrl = old;
        },
        now: () => t0,
      );

      expect(backend.names, ['updateJarProfile', 'createJar']);
      // Recreated with the SAME profile atoms.
      final methods =
          (backend.argsFor('createJar')['profile'] as Map)['methods'] as Map;
      expect(methods['revolutUsername'], 'maya');
      expect(methods['stripeUrl'], 'https://buy.stripe.com/test_abc');
      expect(newJar?.jarId, 'jar_new');
      expect(newSecret, 'newsecret');
      expect(oldUrl, 'https://tip.live.tips/t/jar_ping');
      expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
    });
  }

  test('a gone jar without onRelinked is left alone (no recreate)', () async {
    final store = await seededStore();
    final (client, backend) = _client({
      'updateJarProfile': (_) => throw FakeFunctionsException('not-found'),
    });

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      now: () => t0,
    );

    expect(backend.names, ['updateJarProfile']);
    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  test('a failed recreate leaves no timestamp (retries next launch)', () async {
    final store = await seededStore();
    final (client, backend) = _client({
      'updateJarProfile': (_) => throw FakeFunctionsException('not-found'),
      'createJar': (_) => throw FakeFunctionsException('resource-exhausted'),
    });
    var relinked = false;

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      onRelinked: (a, b, cc) async => relinked = true,
      now: () => t0,
    );

    expect(backend.names, ['updateJarProfile', 'createJar']);
    expect(relinked, isFalse);
    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  test('a relay-less device (no transport identity) never recreates the jar',
      () async {
    final store = await seededStore();
    final backend = FakeCallables({'createJar': _createdJar});
    final client = fakeRelayClient(backend, auth: FakeRelayAuth(uid: null));
    var relinked = false;

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      onRelinked: (a, b, cc) async => relinked = true,
      now: () => t0,
    );

    expect(backend.calls, isEmpty);
    expect(relinked, isFalse);
    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  test('isDue: independent per-band markers', () async {
    final store = await seededStore();
    const staleId = 'acc_stale';
    const freshId = 'acc_fresh';
    await store.writeRelaySeenAt(
        staleId, t0.subtract(const Duration(days: 3)).millisecondsSinceEpoch);
    await store.writeRelaySeenAt(
        freshId, t0.subtract(const Duration(hours: 1)).millisecondsSinceEpoch);

    expect(service.isDue(store: store, accountId: staleId, now: () => t0),
        isTrue);
    expect(service.isDue(store: store, accountId: freshId, now: () => t0),
        isFalse);
  });
}
