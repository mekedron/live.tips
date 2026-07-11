import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/fx_rates.dart';

/// Fetches ECB daily reference rates, so tips paid in different currencies can
/// be added into one stage total. See [FxRates] for why the converted figure is
/// an approximation and the stored tips never are.
///
/// Source: frankfurter.dev — a free, key-less, open-source front end to the
/// European Central Bank's published reference rates. It is the only third
/// party the app talks to besides Stripe and our own relay, and it is told
/// nothing: the request carries no artist, no jar, no amount, no tip — just
/// "what are today's rates against EUR". Nothing identifying leaves the device.
///
/// A failure here is never fatal. The caller keeps the last cached table, and
/// with no table at all the stage simply declines to count foreign-currency
/// tips rather than inventing a number.
class FxSource {
  FxSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://api.frankfurter.dev/v1/latest';

  /// ECB publishes against the euro, so that's our base.
  static const base = 'eur';

  Future<FxRates> fetch() async {
    final res = await _client
        .get(Uri.parse('$_endpoint?base=${base.toUpperCase()}'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw FxException('rates unavailable (HTTP ${res.statusCode})');
    }

    final body = jsonDecode(res.body);
    if (body is! Map || body['rates'] is! Map) {
      throw const FxException('rates response was not in the expected shape');
    }
    final rates = <String, double>{};
    for (final entry in (body['rates'] as Map).entries) {
      final code = entry.key;
      final value = entry.value;
      if (code is String && value is num) {
        rates[code.toLowerCase()] = value.toDouble();
      }
    }
    if (rates.isEmpty) throw const FxException('rates response was empty');

    return FxRates(base: base, rates: rates, fetchedAt: DateTime.now());
  }

  void close() => _client.close();
}

class FxException implements Exception {
  const FxException(this.message);
  final String message;
  @override
  String toString() => message;
}
