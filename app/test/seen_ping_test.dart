import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/seen_ping.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _jar = RelayJar(
  jarId: 'jar_ping',
  donateUrl: 'https://live.tips/t/jar_ping',
  artistName: 'Maya',
  currency: 'eur',
  createdAtMs: 0,
);

Future<LocalStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

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
    final store = await _freshStore();
    final (client, requests) = _client();

    await service.maybePing(
        store: store, jar: _jar, secret: 's', client: client, now: () => t0);

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/v1/jars/jar_ping/seen');
    expect(requests.single.headers['Authorization'], 'Bearer s');
    expect(store.readRelaySeenAt(), t0.millisecondsSinceEpoch);
  });

  test('within 24 h of the last ping → stays quiet', () async {
    final store = await _freshStore();
    await store.writeRelaySeenAt(t0.millisecondsSinceEpoch);
    final (client, requests) = _client();

    await service.maybePing(
      store: store,
      jar: _jar,
      secret: 's',
      client: client,
      now: () => t0.add(const Duration(hours: 23, minutes: 59)),
    );

    expect(requests, isEmpty);
    expect(store.readRelaySeenAt(), t0.millisecondsSinceEpoch,
        reason: 'the stored timestamp is untouched');
  });

  test('24 h or more since the last ping → pings again', () async {
    final store = await _freshStore();
    await store.writeRelaySeenAt(t0.millisecondsSinceEpoch);
    final (client, requests) = _client();
    final later = t0.add(const Duration(hours: 24, minutes: 1));

    await service.maybePing(
        store: store, jar: _jar, secret: 's', client: client, now: () => later);

    expect(requests, hasLength(1));
    expect(store.readRelaySeenAt(), later.millisecondsSinceEpoch);
  });

  test('API failure is swallowed and writes no timestamp', () async {
    final store = await _freshStore();
    final (client, requests) = _client(status: 401);

    await service.maybePing(
        store: store, jar: _jar, secret: 's', client: client, now: () => t0);

    expect(requests, hasLength(1), reason: 'the attempt was made');
    expect(store.readRelaySeenAt(), isNull,
        reason: 'a failed ping must be retried on the next resume');
  });

  test('network failure is swallowed and writes no timestamp', () async {
    final store = await _freshStore();
    final client = RelayClient(
      client: MockClient(
          (request) async => throw http.ClientException('offline')),
    );

    await service.maybePing(
        store: store, jar: _jar, secret: 's', client: client, now: () => t0);

    expect(store.readRelaySeenAt(), isNull);
  });

  test('a stale timestamp survives a failed retry', () async {
    final store = await _freshStore();
    final stale =
        t0.subtract(const Duration(days: 3)).millisecondsSinceEpoch;
    await store.writeRelaySeenAt(stale);
    final (client, requests) = _client(status: 500);

    await service.maybePing(
        store: store, jar: _jar, secret: 's', client: client, now: () => t0);

    expect(requests, hasLength(1));
    expect(store.readRelaySeenAt(), stale);
  });
}
