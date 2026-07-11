import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/seen_ping.dart';

import 'helpers.dart';

const _jar = RelayJar(
  jarId: 'jar_ping',
  tipUrl: 'https://live.tips/t/jar_ping',
  artistName: 'Maya',
  currency: 'eur',
  revolutUsername: 'maya',
  createdAtMs: 0,
);

/// A relay client that records every request and answers each (method, path)
/// from [routes]; anything unmatched returns 204.
(RelayClient, List<http.Request>) _client(
    [Map<String, http.Response> routes = const {}]) {
  final requests = <http.Request>[];
  final client = RelayClient(
    client: MockClient((request) async {
      requests.add(request);
      return routes['${request.method} ${request.url.path}'] ??
          http.Response('', 204);
    }),
  );
  return (client, requests);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime(2026, 7, 7, 12);
  final service = SeenPingService();

  test('never synced → PUTs the full profile (incl. stripeUrl) and stores the '
      'timestamp', () async {
    final store = await seededStore();
    final (client, requests) = _client();

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      stripeUrl: 'https://buy.stripe.com/test_abc',
      now: () => t0,
    );

    expect(requests, hasLength(1));
    expect(requests.single.method, 'PUT');
    expect(requests.single.url.path, '/v1/jars/jar_ping');
    expect(requests.single.headers['Authorization'], 'Bearer s');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect((body['methods'] as Map)['stripeUrl'], 'https://buy.stripe.com/test_abc');
    expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
  });

  test('within 24 h → stays quiet, timestamp untouched', () async {
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
    expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
  });

  test('a rejected profile (422) never recreates and writes no timestamp',
      () async {
    final store = await seededStore();
    final (client, requests) = _client({
      'PUT /v1/jars/jar_ping': http.Response('{"error":"bad"}', 422),
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

    expect(requests, hasLength(1), reason: 'only the PUT, no recreate');
    expect(relinked, isFalse);
    expect(store.readRelaySeenAt(kTestAccountId), isNull);
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
      now: () => t0,
    );

    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  for (final status in [404, 401]) {
    test('a gone jar ($status) is recreated with the same profile and the old '
        'URL is reported', () async {
      final store = await seededStore();
      final (client, requests) = _client({
        'PUT /v1/jars/jar_ping': http.Response('{"error":"gone"}', status),
        'POST /v1/jars': http.Response(
            jsonEncode({
              'jarId': 'jar_new',
              'secret': 'newsecret',
              'tipUrl': 'https://live.tips/t/jar_new',
            }),
            201),
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

      expect(requests.map((r) => '${r.method} ${r.url.path}'),
          ['PUT /v1/jars/jar_ping', 'POST /v1/jars']);
      // Recreated with the SAME profile atoms.
      final createBody = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect((createBody['methods'] as Map)['revolutUsername'], 'maya');
      expect((createBody['methods'] as Map)['stripeUrl'],
          'https://buy.stripe.com/test_abc');
      expect(newJar?.jarId, 'jar_new');
      expect(newSecret, 'newsecret');
      expect(oldUrl, 'https://live.tips/t/jar_ping');
      expect(store.readRelaySeenAt(kTestAccountId), t0.millisecondsSinceEpoch);
    });
  }

  test('a gone jar without onRelinked is left alone (no recreate)', () async {
    final store = await seededStore();
    final (client, requests) = _client({
      'PUT /v1/jars/jar_ping': http.Response('{"error":"gone"}', 404),
    });

    await service.maybePing(
      store: store,
      accountId: kTestAccountId,
      jar: _jar,
      secret: 's',
      client: client,
      now: () => t0,
    );

    expect(requests, hasLength(1));
    expect(store.readRelaySeenAt(kTestAccountId), isNull);
  });

  test('a failed recreate leaves no timestamp (retries next launch)', () async {
    final store = await seededStore();
    final (client, requests) = _client({
      'PUT /v1/jars/jar_ping': http.Response('{"error":"gone"}', 404),
      'POST /v1/jars': http.Response('{"error":"rate"}', 429),
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

    expect(requests, hasLength(2));
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
