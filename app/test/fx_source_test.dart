import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/fx_source.dart';

/// A real response captured from api.frankfurter.dev (2026-07-10), trimmed to a
/// few currencies. Pinning the parser to the actual payload — not to a shape we
/// imagined — is the point of this file.
const _realBody =
    '{"amount":1.0,"base":"EUR","date":"2026-07-10",'
    '"rates":{"AUD":1.6447,"GBP":0.85155,"JPY":185.02,"USD":1.143}}';

void main() {
  test('parses the live rates payload, lowercasing the codes', () async {
    final source = FxSource(
      client: MockClient((req) async {
        expect(req.url.host, 'api.frankfurter.dev');
        expect(req.url.queryParameters['base'], 'EUR');
        return http.Response(_realBody, 200);
      }),
    );

    final rates = await source.fetch();
    expect(rates.base, 'eur');
    expect(rates.rates['gbp'], 0.85155);
    expect(rates.supports('GBP'), isTrue);
    // £10 ÷ 0.85155 = €11.7433 — the conversion the stage goal bar depends on.
    expect(rates.convertMinor(1000, 'gbp', 'eur'), 1174);
  });

  test('a non-200 is an exception, not a silently empty table', () async {
    final source = FxSource(
      client: MockClient((_) async => http.Response('nope', 503)),
    );
    expect(source.fetch(), throwsA(isA<FxException>()));
  });

  test('a malformed body is an exception too', () async {
    final source = FxSource(
      client: MockClient((_) async => http.Response('{"rates":{}}', 200)),
    );
    expect(source.fetch(), throwsA(isA<FxException>()));
  });
}
