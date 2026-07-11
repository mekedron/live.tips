import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/fx_rates.dart';

/// Fetches reference exchange rates, so tips paid in different currencies can be
/// added into one stage total. See [FxRates] for why the converted figure is an
/// approximation and the stored tips never are.
///
/// Three independent, key-less providers, tried in order until one answers. No
/// single service gets to take the feature down: any of them may 500, get
/// blocked on a venue's wifi, rebrand, or simply disappear, and the artist on
/// stage would never know why the goal bar stopped moving. Below all three sits
/// [FxRates.builtin] — rates compiled into the binary — so there is a floor even
/// with no network at all.
///
/// None of them is told anything: the requests carry no artist, no jar, no
/// amount, no tip — just "what are today's rates against EUR". They are the only
/// third parties the app talks to besides Stripe and our own relay.
class FxSource {
  FxSource({http.Client? client, List<FxProvider>? providers})
    : _client = client ?? http.Client(),
      providers = providers ?? kFxProviders;

  final http.Client _client;

  /// Tried in order. First one to answer wins.
  final List<FxProvider> providers;

  /// Walks the chain. Throws [FxException] only when every provider failed —
  /// the caller then keeps its cached table, or falls back to the built-in one.
  Future<FxRates> fetch() async {
    final failures = <String>[];
    for (final provider in providers) {
      try {
        return await provider.fetch(_client);
      } catch (e) {
        // Try the next one. A provider being down is expected, not exceptional.
        failures.add('${provider.id}: $e');
      }
    }
    throw FxException('every rate provider failed — ${failures.join('; ')}');
  }

  void close() => _client.close();
}

/// One rate service. Each publishes a different shape, so each parses its own.
abstract class FxProvider {
  const FxProvider();

  /// Stable id, stored alongside the rates so we can say where they came from.
  String get id;

  Future<FxRates> fetch(http.Client client);

  static const timeout = Duration(seconds: 8);

  /// Shared plumbing: GET, check the status, decode, hand the body to [parse].
  Future<FxRates> get(http.Client client, String url, Map<String, double> Function(Map<String, dynamic>) parse) async {
    final res = await client.get(Uri.parse(url)).timeout(timeout);
    if (res.statusCode != 200) {
      throw FxException('HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) throw const FxException('not a JSON object');

    final rates = parse(body);
    if (rates.isEmpty) throw const FxException('no rates in the response');
    return FxRates(
      base: 'eur',
      rates: rates,
      fetchedAt: DateTime.now(),
      origin: FxOrigin.live,
      source: id,
    );
  }
}

/// Only keep plain 3-letter fiat codes: one provider quotes crypto and metals
/// in the same table, and a jar is never denominated in ADA.
Map<String, double> _fiatOnly(Map source) {
  final out = <String, double>{};
  for (final entry in source.entries) {
    final code = entry.key;
    final value = entry.value;
    if (code is String &&
        code.length == 3 &&
        RegExp(r'^[A-Za-z]{3}$').hasMatch(code) &&
        value is num &&
        value > 0) {
      out[code.toLowerCase()] = value.toDouble();
    }
  }
  return out;
}

/// ECB daily reference rates. Fewest currencies (~30), most authoritative.
class FrankfurterProvider extends FxProvider {
  const FrankfurterProvider();

  @override
  String get id => 'frankfurter.dev';

  @override
  Future<FxRates> fetch(http.Client client) => get(
    client,
    'https://api.frankfurter.dev/v1/latest?base=EUR',
    (body) => _fiatOnly(body['rates'] as Map? ?? const {}),
  );
}

/// exchangerate-api's open endpoint. ~160 currencies.
class ErApiProvider extends FxProvider {
  const ErApiProvider();

  @override
  String get id => 'open.er-api.com';

  @override
  Future<FxRates> fetch(http.Client client) => get(
    client,
    'https://open.er-api.com/v6/latest/EUR',
    (body) {
      if (body['result'] != 'success') {
        throw FxException('result was "${body['result']}"');
      }
      return _fiatOnly(body['rates'] as Map? ?? const {});
    },
  );
}

/// The currency-api dataset, served from Cloudflare Pages. Widest coverage
/// (~290 fiat currencies) and a different host and CDN from the other two, so
/// an outage that takes them down is unlikely to take this with it.
class CurrencyApiProvider extends FxProvider {
  const CurrencyApiProvider();

  @override
  String get id => 'currency-api.pages.dev';

  @override
  Future<FxRates> fetch(http.Client client) => get(
    client,
    'https://latest.currency-api.pages.dev/v1/currencies/eur.json',
    (body) => _fiatOnly(body['eur'] as Map? ?? const {}),
  );
}

/// Order matters: the ECB's own numbers first, then breadth, then the widest
/// (and least official) dataset.
const List<FxProvider> kFxProviders = [
  FrankfurterProvider(),
  ErApiProvider(),
  CurrencyApiProvider(),
];

class FxException implements Exception {
  const FxException(this.message);
  final String message;
  @override
  String toString() => message;
}
