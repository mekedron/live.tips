import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/domain/relay_jar.dart';

const _jar = RelayJar(
  jarId: 'jar_abc',
  donateUrl: 'https://live.tips/t/jar_abc',
  artistName: 'Maya',
  currency: 'eur',
  revolutUsername: 'mayamusic',
  createdAtMs: 0,
);

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test('createJar posts the jar body and parses the 201 response', () async {
    late http.Request seen;
    final client = RelayClient(
      client: MockClient((request) async {
        seen = request;
        return _json({
          'jarId': 'jar_abc',
          'secret': 's3cret',
          'donateUrl': 'https://live.tips/t/jar_abc',
        }, 201);
      }),
    );

    final result = await client.createJar(
      artistName: 'Maya',
      message: 'Tips welcome!',
      currency: 'eur',
      stripeUrl: 'https://buy.stripe.com/x',
      revolutUsername: 'mayamusic',
    );

    expect(seen.method, 'POST');
    expect(seen.url.toString(), 'https://api.live.tips/v1/jars');
    expect(seen.headers.containsKey('Authorization'), isFalse,
        reason: 'creation is the only unauthenticated call');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body['artistName'], 'Maya');
    expect(body['currency'], 'eur');
    expect((body['methods'] as Map)['stripeUrl'], 'https://buy.stripe.com/x');
    expect((body['methods'] as Map)['revolutUsername'], 'mayamusic');
    expect((body['methods'] as Map).containsKey('mobilepayBoxId'), isFalse);

    expect(result.jar.jarId, 'jar_abc');
    expect(result.jar.donateUrl, 'https://live.tips/t/jar_abc');
    expect(result.jar.revolutUsername, 'mayamusic');
    expect(result.jar.createdAtMs, greaterThan(0));
    expect(result.secret, 's3cret');
  });

  test('artistName is clamped to the relay limit (50 code points) so a long '
      'Stripe display name never 422s', () async {
    late http.Request seen;
    final client = RelayClient(
      client: MockClient((request) async {
        seen = request;
        return _json({
          'jarId': 'j',
          'secret': 's',
          'donateUrl': 'https://live.tips/t/j',
        }, 201);
      }),
    );

    final longName = 'A' * 80;
    await client.createJar(artistName: longName, currency: 'eur',
        revolutUsername: 'x');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect((body['artistName'] as String).length, 50);
  });

  test('authenticated calls carry the Bearer secret', () async {
    final requests = <http.Request>[];
    final client = RelayClient(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/rotate-secret')) {
          return _json({'secret': 'new_secret'}, 200);
        }
        if (request.method == 'PUT') return _json({'ok': true}, 200);
        return http.Response('', 204);
      }),
    );

    await client.updateJar(
      jar: _jar,
      secret: 'old_secret',
      artistName: 'Maya',
      stripeUrl: 'https://buy.stripe.com/y',
    );
    await client.deleteJar(jarId: 'jar_abc', secret: 'old_secret');
    await client.markSeen(jarId: 'jar_abc', secret: 'old_secret');
    final rotated =
        await client.rotateSecret(jarId: 'jar_abc', secret: 'old_secret');

    expect(rotated, 'new_secret');
    expect(requests, hasLength(4));
    for (final request in requests) {
      expect(request.headers['Authorization'], 'Bearer old_secret',
          reason: '${request.method} ${request.url.path}');
    }
    expect(requests[0].method, 'PUT');
    expect(requests[0].url.path, '/v1/jars/jar_abc');
    // The PUT re-sends the jar's untouched methods alongside the new URL.
    final putBody = jsonDecode(requests[0].body) as Map<String, dynamic>;
    expect((putBody['methods'] as Map)['revolutUsername'], 'mayamusic');
    expect((putBody['methods'] as Map)['stripeUrl'], 'https://buy.stripe.com/y');
    expect(requests[1].method, 'DELETE');
    expect(requests[2].url.path, '/v1/jars/jar_abc/seen');
    expect(requests[3].url.path, '/v1/jars/jar_abc/rotate-secret');
  });

  test('401 maps to RelayApiException.isAuthError with the server error',
      () async {
    final client = RelayClient(
      client: MockClient(
        (request) async => _json({'error': 'bad secret'}, 401),
      ),
    );
    try {
      await client.markSeen(jarId: 'jar_abc', secret: 'stale');
      fail('expected RelayApiException');
    } on RelayApiException catch (e) {
      expect(e.isAuthError, isTrue);
      expect(e.isNotFound, isFalse);
      expect(e.message, 'bad secret');
      expect(e.friendlyMessage, isNot('bad secret'),
          reason: 'auth errors get a human explanation');
    }
  });

  test('404 maps to RelayApiException.isNotFound', () async {
    final client = RelayClient(
      client: MockClient(
        (request) async => _json({'error': 'no such jar'}, 404),
      ),
    );
    expect(
      () => client.deleteJar(jarId: 'gone', secret: 's'),
      throwsA(isA<RelayApiException>()
          .having((e) => e.isNotFound, 'isNotFound', isTrue)
          .having((e) => e.statusCode, 'statusCode', 404)),
    );
  });

  test('a garbage error body still surfaces the status code', () async {
    final client = RelayClient(
      client: MockClient((request) async => http.Response('<html>', 500)),
    );
    expect(
      () => client.markSeen(jarId: 'jar_abc', secret: 's'),
      throwsA(isA<RelayApiException>()
          .having((e) => e.message, 'message', contains('500'))),
    );
  });

  test('network failure maps to RelayNetworkException', () async {
    final client = RelayClient(
      client: MockClient(
        (request) async => throw http.ClientException('Connection refused'),
      ),
    );
    expect(
      () => client.createJar(artistName: 'Maya', currency: 'eur'),
      throwsA(isA<RelayNetworkException>()),
    );
  });
}
