import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error returned by the Stripe API, mapped to something we can show artists.
class StripeApiException implements Exception {
  const StripeApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.type,
    this.param,
  });

  final int statusCode;
  final String message;
  final String? code;
  final String? type;
  final String? param;

  bool get isAuthError => statusCode == 401;
  bool get isPermissionError =>
      statusCode == 403 || (message.contains('does not have the required permissions'));
  bool get isRateLimited => statusCode == 429;

  String get friendlyMessage {
    if (isAuthError) {
      return 'Stripe rejected this API key. It may have been revoked or '
          'mistyped — reconnect with a fresh key.';
    }
    if (isPermissionError) {
      return 'The API key is missing a permission. $message';
    }
    if (isRateLimited) {
      return 'Stripe is rate-limiting requests — retrying more slowly.';
    }
    return message;
  }

  @override
  String toString() => 'StripeApiException($statusCode, $code): $message';
}

/// Thrown when the network itself failed (offline, timeout, DNS…).
class StripeNetworkException implements Exception {
  const StripeNetworkException(this.message);
  final String message;

  @override
  String toString() => 'StripeNetworkException: $message';
}

/// Minimal Stripe REST client.
///
/// The artist's restricted key talks directly to api.stripe.com from the
/// device — there is deliberately no backend in between.
class StripeClient {
  StripeClient(this._apiKey, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  /// Pinned so response shapes stay stable regardless of the account's
  /// default API version.
  static const apiVersion = '2024-06-20';

  final String _apiKey;
  final http.Client _http;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Stripe-Version': apiVersion,
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.https('api.stripe.com', '/v1/$path', query);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _http
          .get(_uri(path, query), headers: _headers)
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } on StripeApiException {
      rethrow;
    } on TimeoutException {
      throw const StripeNetworkException('Request to Stripe timed out.');
    } on http.ClientException catch (e) {
      throw StripeNetworkException(e.message);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final response = await _http
          .post(_uri(path), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));
      return _decode(response);
    } on StripeApiException {
      rethrow;
    } on TimeoutException {
      throw const StripeNetworkException('Request to Stripe timed out.');
    } on http.ClientException catch (e) {
      throw StripeNetworkException(e.message);
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      json = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json is Map<String, dynamic>) return json;
      throw StripeApiException(
        statusCode: response.statusCode,
        message: 'Unexpected response from Stripe.',
      );
    }
    final error = json is Map<String, dynamic>
        ? (json['error'] as Map<String, dynamic>? ?? const {})
        : const <String, dynamic>{};
    throw StripeApiException(
      statusCode: response.statusCode,
      message: error['message'] as String? ??
          'Stripe returned HTTP ${response.statusCode}.',
      code: error['code'] as String?,
      type: error['type'] as String?,
      param: error['param'] as String?,
    );
  }

  void close() => _http.close();
}
