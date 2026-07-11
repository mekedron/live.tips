import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/fx_source.dart';
import 'package:live_tips/domain/fx_rates.dart';

/// Real response bodies, captured from each provider on 2026-07-11 and trimmed
/// to a few currencies. Pinning the parsers to what the services actually
/// return — not to a shape we imagined — is the point of this file.
const _frankfurter =
    '{"amount":1.0,"base":"EUR","date":"2026-07-10",'
    '"rates":{"AUD":1.6447,"GBP":0.85155,"JPY":185.02,"USD":1.143}}';

const _erApi =
    '{"result":"success","base_code":"EUR","time_last_update_unix":1783728152,'
    '"rates":{"EUR":1,"GBP":0.852035,"JPY":184.784375,"USD":1.142111}}';

/// Note the crypto and the metals — this provider mixes them in with the fiat.
const _currencyApi =
    '{"date":"2026-07-11","eur":{"1inch":15.77,"ada":6.86,"btc":0.0000098,'
    '"gbp":0.85162803,"jpy":184.53184107,"usd":1.14094265,"xau":0.00029}}';

MockClient _always(String body, {int status = 200}) =>
    MockClient((_) async => http.Response(body, status));

void main() {
  group('each provider parses its own live payload', () {
    test('frankfurter.dev — uppercase codes under "rates"', () async {
      final rates = await FxSource(
        client: _always(_frankfurter),
        providers: const [FrankfurterProvider()],
      ).fetch();
      expect(rates.source, 'frankfurter.dev');
      expect(rates.origin, FxOrigin.live);
      expect(rates.rates['gbp'], 0.85155);
    });

    test('open.er-api.com — checks the "result" field', () async {
      final rates = await FxSource(
        client: _always(_erApi),
        providers: const [ErApiProvider()],
      ).fetch();
      expect(rates.source, 'open.er-api.com');
      expect(rates.rates['gbp'], 0.852035);
    });

    test('currency-api — lowercase codes, and the crypto is filtered out', () async {
      final rates = await FxSource(
        client: _always(_currencyApi),
        providers: const [CurrencyApiProvider()],
      ).fetch();
      expect(rates.source, 'currency-api.pages.dev');
      expect(rates.rates['gbp'], 0.85162803);
      // 3-letter-alpha only: btc/xau slip through that net, "1inch"/"ada" don't.
      expect(rates.rates.containsKey('1inch'), isFalse);
      // A jar is never denominated in these, so their presence is harmless —
      // what matters is that the fiat codes we do offer are all present.
      expect(rates.rates['usd'], 1.14094265);
    });

    test('a provider reporting failure in a 200 body is still a failure', () {
      final source = FxSource(
        client: _always('{"result":"error","error-type":"invalid-key"}'),
        providers: const [ErApiProvider()],
      );
      expect(source.fetch(), throwsA(isA<FxException>()));
    });
  });

  group('the provider chain', () {
    test('falls through a dead provider to a live one', () async {
      var calls = <String>[];
      final client = MockClient((req) async {
        calls.add(req.url.host);
        // The first provider is down; the second answers.
        if (req.url.host == 'api.frankfurter.dev') {
          return http.Response('gateway timeout', 504);
        }
        return http.Response(_erApi, 200);
      });

      final rates = await FxSource(client: client).fetch();
      expect(rates.source, 'open.er-api.com', reason: 'the fallback served it');
      expect(calls.first, 'api.frankfurter.dev', reason: 'it tried the ECB first');
      expect(rates.rates['gbp'], 0.852035);
    });

    test('walks all the way to the last provider', () async {
      final client = MockClient((req) async {
        if (req.url.host == 'latest.currency-api.pages.dev') {
          return http.Response(_currencyApi, 200);
        }
        return http.Response('nope', 503);
      });

      final rates = await FxSource(client: client).fetch();
      expect(rates.source, 'currency-api.pages.dev');
    });

    test('throws only when every provider is down, naming them all', () async {
      final source = FxSource(client: _always('down', status: 500));
      await expectLater(
        source.fetch(),
        throwsA(
          isA<FxException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('frankfurter.dev'),
              contains('open.er-api.com'),
              contains('currency-api.pages.dev'),
            ),
          ),
        ),
      );
    });
  });

  group('the built-in floor', () {
    test('converts with no network and no cache, and says it is built-in', () {
      final builtin = FxRates.builtin();
      expect(builtin.origin, FxOrigin.builtin);
      // £8.52 ≈ €10 at the baked-in 0.8516 — right to the percent, which is all
      // a goal bar needs.
      final euros = builtin.convertMinor(852, 'gbp', 'eur')!;
      expect(euros, closeTo(1000, 5));
      expect(builtin.supports('jpy'), isTrue);
    });

    test('covers every currency the jar picker offers', () {
      // A currency an artist can pick but we cannot convert would be a tip
      // silently missing from their total.
      const supported = [
        'usd', 'gbp', 'cad', 'aud', 'nzd', 'chf', 'sek', 'nok', 'dkk', 'pln',
        'czk', 'ron', 'huf', 'jpy', 'mxn', 'brl', 'sgd', 'hkd', 'ils', 'aed',
        'inr',
      ];
      for (final c in supported) {
        expect(kBuiltinEurRates.containsKey(c), isTrue, reason: 'no built-in rate for $c');
      }
      expect(FxRates.builtin().supports('eur'), isTrue, reason: 'the base itself');
    });

    test('fills a hole in an otherwise live table', () {
      // The ECB publishes ~30 currencies. A tip in one of the other 140 must
      // not vanish from the total just because the live table is short.
      final sparse = FxRates(
        base: 'eur',
        rates: const {'gbp': 0.85},
        fetchedAt: DateTime(2026, 7, 11),
        source: 'frankfurter.dev',
      );
      expect(sparse.usesBuiltinFor('gbp'), isFalse, reason: 'live rate wins');
      expect(sparse.usesBuiltinFor('inr'), isTrue, reason: 'absent → built-in');
      expect(sparse.convertMinor(10900, 'inr', 'eur'), isNotNull);
      // Still nothing for a currency nobody has a rate for.
      expect(sparse.convertMinor(100, 'xyz', 'eur'), isNull);
    });

    test('is dated when it was captured, so it still counts as stale', () {
      final builtin = FxRates.builtin();
      expect(
        builtin.isStaleAt(DateTime.parse(kBuiltinRatesAsOf).add(const Duration(days: 30))),
        isTrue,
        reason: 'a stale built-in table must keep prompting a real refresh',
      );
    });
  });
}
