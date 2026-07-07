import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/seen_ping.dart';

import 'helpers.dart';

const _jar = RelayJar(
  jarId: 'jar_ping',
  donateUrl: 'https://live.tips/t/jar_ping',
  artistName: 'Maya',
  currency: 'eur',
  createdAtMs: 0,
);

/// A relay client whose /seen endpoint counts calls and answers [status].
(RelayClient, List<http.Request>) _client({int status = 204}) {
  final requests = <http.Request>[];
  final client = RelayClient(
    client: MockClient((request) async {
      requests.add(request);
      return http.Response('', status);
    }),
  );
  return (client, requests);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime(2026, 7, 7, 12);
  final service = SeenPingService();

  test('never pinged → pings and stores the timestamp', () async {
    final store = await seededStore();
    final (client, requests) = _client();

    await service.maybePing(
        store: store,
        accountId: kTestAccountId,
        jar: _jar,
        secret: 's',
        client: client,
        now: () => t0);

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/v1/jars/jar_ping/seen');
    expect(requests.single.headers['Authorization'], 'Bearer s');
    expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
  });

  test('within 24 h of the last ping → stays quiet', () async {
    final store = await seededStore();
    await store.writeRelaySeenAt(kTestAccountId, t0.millisecondsSinceEpoch);
    final (client, requests) = _client();

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      now: () => t0.add(const Duration(hours: 23, minutes: 59)),
    );

    expect(requests, isEmpty);
    expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch,
        reason: 'the stored timestamp is untouched');
  });

  test('24 h or more since the last ping → pings again', () async {
    final store = await seededStore();
    await store.writeRelaySeenAt(kTestAccountId, t0.millisecondsSinceEpoch);
    final (client, requests) = _client();
    final later = t0.add(const Duration(hours: 24, minutes: 1));

    await service.maybePing(
        store: store,
        accountId: kTestAccountId,
        jar: _jar,
        secret: 's',
        client: client,
        now: () => later);

    expect(requests, hasLength(1));
    expect(store.readRelaySeenAt(kTestAccountId),
        later.millisecondsSinceEpoch);
  });

  test('API failure is swallowed and writes no timestamp', () async {
    final store = await seededStore();
    final (client, requests) = _client(status: 401);

    await service.maybePing(
        store: store,
        accountId: kTestAccountId,
        jar: _jar,
        secret: 's',
        client: client,
        now: () => t0);

    expect(requests, hasLength(1), reason: 'the attempt was made');
    expect(store.readRelaySeenAt(kTestAccountId), isNull,
        reason: 'a failed ping must be retried on the next resume');
  });

  test('network failure is swallowed and writes no timestamp', () async {
    final store = await seededStore();
    final client = RelayClient(
      client: MockClient(
          (request) async => throw http.ClientException('offline')),
    );

    await service.maybePing(
        store: store,
        accountId: kTestAccountId,
        jar: _jar,
        secret: 's',
        client: client,
        now: () => t0);

    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  test('a stale timestamp survives a failed retry', () async {
    final store = await seededStore();
    final stale =
        t0.subtract(const Duration(days: 3)).millisecondsSinceEpoch;
    await store.writeRelaySeenAt(kTestAccountId, stale);
    final (client, requests) = _client(status: 500);

    await service.maybePing(
        store: store,
        accountId: kTestAccountId,
        jar: _jar,
        secret: 's',
        client: client,
        now: () => t0);

    expect(requests, hasLength(1));
    expect(store.readRelaySeenAt(kTestAccountId), stale);
  });

  test('two accounts: only the stale one is pinged, markers independent',
      () async {
    final store = await seededStore();
    const staleId = 'acc_stale';
    const freshId = 'acc_fresh';
    const staleJar = RelayJar(
      jarId: 'jar_stale',
      donateUrl: 'https://live.tips/t/jar_stale',
      artistName: 'Maya',
      currency: 'eur',
      createdAtMs: 0,
    );
    const freshJar = RelayJar(
      jarId: 'jar_fresh',
      donateUrl: 'https://live.tips/t/jar_fresh',
      artistName: 'Noa',
      currency: 'eur',
      createdAtMs: 0,
    );
    final staleMs =
        t0.subtract(const Duration(days: 3)).millisecondsSinceEpoch;
    final freshMs =
        t0.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
    await store.writeRelaySeenAt(staleId, staleMs);
    await store.writeRelaySeenAt(freshId, freshMs);
    final (client, requests) = _client();

    expect(service.isDue(store: store, accountId: staleId, now: () => t0),
        isTrue);
    expect(service.isDue(store: store, accountId: freshId, now: () => t0),
        isFalse);

    // The keepalive loop: gate on isDue, then ping each due band.
    for (final (id, jar) in [(staleId, staleJar), (freshId, freshJar)]) {
      if (!service.isDue(store: store, accountId: id, now: () => t0)) {
        continue;
      }
      await service.maybePing(
          store: store,
          accountId: id,
          jar: jar,
          secret: 's',
          client: client,
          now: () => t0);
    }

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/v1/jars/jar_stale/seen');
    expect(store.readRelaySeenAt(staleId), t0.millisecondsSinceEpoch,
        reason: 'the stale band advances to now');
    expect(store.readRelaySeenAt(freshId), freshMs,
        reason: 'the fresh band marker is untouched by the other ping');
  });
}
