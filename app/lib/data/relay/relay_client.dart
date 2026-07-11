import 'dart:async';
import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:http/http.dart' as http;

import '../../domain/relay_jar.dart';
import 'relay_config.dart';

/// Error returned by the live.tips relay API, mapped to something we can
/// show artists.
class RelayApiException implements Exception {
  const RelayApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  bool get isAuthError => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  String get friendlyMessage {
    if (isAuthError) {
      return 'The relay rejected this jar\'s secret — it may have been '
          'rotated on another device. Recreate the jar to reconnect.';
    }
    if (isNotFound) {
      return 'This jar no longer exists on the relay — it may have expired '
          'or been deleted. Recreate it to reconnect.';
    }
    if (statusCode == 429) {
      return 'The relay is rate-limiting requests — wait a minute and '
          'try again.';
    }
    return message;
  }

  @override
  String toString() => 'RelayApiException($statusCode): $message';
}

/// Thrown when the network itself failed (offline, timeout, DNS…).
class RelayNetworkException implements Exception {
  const RelayNetworkException(this.message);
  final String message;

  @override
  String toString() => 'RelayNetworkException: $message';
}

/// Minimal client for the live.tips relay worker (connected mode). It only
/// manages the jar's registration — the tip feed itself arrives over a
/// WebSocket wired elsewhere.
class RelayClient {
  RelayClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  /// The relay enforces these caps (worker `validate.ts`); mirror them here so
  /// a long Stripe display name can never 422 an otherwise-valid update — it's
  /// clamped rather than rejected, since the relay artist name is cosmetic.
  static const _maxArtistName = 50;
  static const _maxMessage = 200;

  static String _clampName(String s) {
    final chars = s.characters;
    return chars.length <= _maxArtistName
        ? s
        : chars.take(_maxArtistName).toString();
  }

  static String? _clampMessage(String? s) {
    if (s == null) return null;
    final chars = s.characters;
    return chars.length <= _maxMessage
        ? s
        : chars.take(_maxMessage).toString();
  }

  /// Registers a new jar. The returned secret is the only credential for
  /// this jar — persist it in the secure store, never alongside the jar.
  Future<({RelayJar jar, String secret})> createJar({
    required String artistName,
    String? message,
    required String currency,
    String? stripeUrl,
    String? revolutUsername,
    String? mobilepayBoxId,
    String? monzoUsername,
  }) async {
    artistName = _clampName(artistName);
    message = _clampMessage(message);
    final json = await _send(
      'POST',
      '/v1/jars',
      body: {
        'artistName': artistName,
        'message': ?message,
        'currency': currency,
        'methods': {
          'stripeUrl': ?stripeUrl,
          'revolutUsername': ?revolutUsername,
          'mobilepayBoxId': ?mobilepayBoxId,
          'monzoUsername': ?monzoUsername,
        },
      },
    );
    return (
      jar: RelayJar(
        jarId: json['jarId'] as String,
        donateUrl: json['donateUrl'] as String,
        artistName: artistName,
        currency: currency,
        message: (message?.trim().isEmpty ?? true) ? null : message!.trim(),
        revolutUsername: revolutUsername,
        mobilepayBoxId: mobilepayBoxId,
        monzoUsername: monzoUsername,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
      secret: json['secret'] as String,
    );
  }

  /// Updates the jar's public details. The relay wants the full body back,
  /// so the untouched methods are re-sent from [jar]; only the Stripe URL is
  /// supplied fresh (it changes when the payment link is regenerated).
  Future<void> updateJar({
    required RelayJar jar,
    required String secret,
    required String artistName,
    String? message,
    String? stripeUrl,
  }) async {
    artistName = _clampName(artistName);
    message = _clampMessage(message);
    await _send(
      'PUT',
      '/v1/jars/${jar.jarId}',
      secret: secret,
      body: {
        'artistName': artistName,
        'message': ?message,
        'currency': jar.currency,
        'methods': {
          'stripeUrl': ?stripeUrl,
          if (jar.revolutUsername != null)
            'revolutUsername': jar.revolutUsername,
          if (jar.mobilepayBoxId != null) 'mobilepayBoxId': jar.mobilepayBoxId,
          if (jar.monzoUsername != null) 'monzoUsername': jar.monzoUsername,
        },
      },
    );
  }

  Future<void> deleteJar({
    required String jarId,
    required String secret,
  }) async {
    await _send('DELETE', '/v1/jars/$jarId', secret: secret);
  }

  /// Tells the relay the artist has seen everything so far — keeps the jar
  /// alive and resets the unseen-tips marker.
  Future<void> markSeen({
    required String jarId,
    required String secret,
  }) async {
    await _send('POST', '/v1/jars/$jarId/seen', secret: secret);
  }

  /// Invalidates the old secret and returns the replacement.
  Future<String> rotateSecret({
    required String jarId,
    required String secret,
  }) async {
    final json = await _send(
      'POST',
      '/v1/jars/$jarId/rotate-secret',
      secret: secret,
    );
    return json['secret'] as String;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? secret,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, relayApi(path));
    if (secret != null) {
      request.headers['Authorization'] = 'Bearer $secret';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final streamed =
          await _http.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } on RelayApiException {
      rethrow;
    } on TimeoutException {
      throw const RelayNetworkException('Request to the relay timed out.');
    } on http.ClientException catch (e) {
      // package:http wraps SocketException & friends into ClientException,
      // so this covers offline/DNS failures on every platform, web included.
      throw RelayNetworkException(e.message);
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
      if (response.bodyBytes.isEmpty) return const {}; // 204 No Content
      throw RelayApiException(
        statusCode: response.statusCode,
        message: 'Unexpected response from the relay.',
      );
    }
    final error = json is Map<String, dynamic> ? json['error'] : null;
    throw RelayApiException(
      statusCode: response.statusCode,
      message: error is String
          ? error
          : 'The relay returned HTTP ${response.statusCode}.',
    );
  }

  void close() => _http.close();
}
