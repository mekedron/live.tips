import 'dart:async';
import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/relay_jar.dart';
import 'relay_auth.dart';

/// Error returned by a live.tips relay callable, mapped to something we can
/// show artists. [code] is the function's `HttpsError` code verbatim (see
/// firebase/functions/src/jars.ts).
class RelayApiException implements Exception {
  const RelayApiException({required this.code, required this.message});

  final String code;
  final String message;

  /// The jar rejected our credential. `permission-denied` counts: the
  /// update/delete/seen callables answer with it when neither the caller's
  /// uid nor the presented secret authorizes the jar.
  bool get isAuthError =>
      code == 'unauthenticated' || code == 'permission-denied';

  /// The jar is gone (or its id is malformed — the server deliberately
  /// answers both the same way, so ids can't be enumerated).
  bool get isNotFound => code == 'not-found';

  String get friendlyMessage {
    if (isAuthError) {
      return 'The relay rejected this jar\'s secret — it may have been '
          'rotated on another device. Recreate the jar to reconnect.';
    }
    if (isNotFound) {
      return 'This jar no longer exists on the relay — it may have expired '
          'or been deleted. Recreate it to reconnect.';
    }
    if (code == 'resource-exhausted') {
      // Honest only where this message is shown — the create/update flows,
      // where the code IS a transient rate limit. The claim path never
      // surfaces it: there the same code means the jar's reader list is
      // full, a PERMANENT verdict the tip channel maps to
      // [RelayHealth.deviceLimit] instead, because "try again" would be
      // a lie.
      return 'The relay is rate-limiting requests — wait a minute and '
          'try again.';
    }
    return message;
  }

  @override
  String toString() => 'RelayApiException($code): $message';
}

/// Thrown when the call never landed (offline, timeout, DNS…) or when this
/// device has no relay at all — no Firebase, or no transport identity to
/// sign the call with. Deliberately NOT an auth error: a relay we cannot
/// reach must never be mistaken for a relay that rejected us, or the seen
/// ping would recreate everyone's jar the first time they open the app in
/// a tunnel.
class RelayNetworkException implements Exception {
  const RelayNetworkException(this.message);
  final String message;

  @override
  String toString() => 'RelayNetworkException: $message';
}

/// One call to a jar callable: name in, decoded payload out. The seam the
/// tests fake — everything above it is pure request/response shaping.
typedef CallableInvoker = Future<Map<String, dynamic>> Function(
  String name,
  Map<String, dynamic> args,
);

/// Client for the live.tips relay's jar callables (connected mode). It only
/// manages the jar's registration — the tip feed itself arrives over the
/// Firestore listener in [FirestoreTipChannel].
class RelayClient {
  RelayClient({
    required RelayAuth auth,
    FirebaseFunctions? functions,
    CallableInvoker? invoke,
  })  : _auth = auth,
        _invoke = invoke ?? _callables(functions);

  final RelayAuth _auth;
  final CallableInvoker _invoke;

  /// The relay enforces these caps (functions `validate.ts`); mirror them here
  /// so a long Stripe display name can never be rejected on an otherwise-valid
  /// update — it's clamped rather than refused, since the relay artist name is
  /// cosmetic. The relay counts Unicode CODE POINTS and separately caps the
  /// UTF-8 BYTE length; there is no contract file shared between the Dart app
  /// and the TypeScript functions, so the numbers are duplicated verbatim
  /// (and pinned on both sides by tests).
  static const _maxArtistName = 50;
  static const _maxArtistNameBytes = 200;
  static const _maxMessage = 200;
  static const _maxMessageBytes = 800;

  static CallableInvoker _callables(FirebaseFunctions? functions) =>
      (name, args) async {
        if (functions == null) {
          throw const RelayNetworkException(
              'The relay is not available on this device.');
        }
        final result = await functions.httpsCallable(name).call<dynamic>(args);
        final data = result.data;
        if (data is Map) return data.cast<String, dynamic>();
        return const {};
      };

  /// Clamps [s] to at most [maxCodePoints] code points and [maxBytes] UTF-8
  /// bytes — the units `validate.ts` rejects in. Clamping by grapheme cluster
  /// (what `characters.take` counts) broke the promise above: a flag emoji is
  /// one grapheme but 2 code points, a skin-toned or ZWJ emoji up to 7, so an
  /// emoji-heavy name well under 50 graphemes was still refused with
  /// `invalid-argument` — only in production, where the real validator runs.
  /// Whole graphemes are kept while both budgets hold, so an emoji is never
  /// cut in half. The relay scrubs before counting (NFC, then ZWJ and other
  /// invisibles stripped, controls collapsed, trimmed), which for anything a
  /// keyboard produces only shrinks the string — counting the raw input here
  /// can only over-clamp, never under.
  static String _clampText(String s, int maxCodePoints, int maxBytes) {
    if (s.runes.length <= maxCodePoints && utf8.encode(s).length <= maxBytes) {
      return s;
    }
    final out = StringBuffer();
    var codePoints = 0;
    var bytes = 0;
    for (final grapheme in s.characters) {
      codePoints += grapheme.runes.length;
      bytes += utf8.encode(grapheme).length;
      if (codePoints > maxCodePoints || bytes > maxBytes) break;
      out.write(grapheme);
    }
    return out.toString();
  }

  static String _clampName(String s) =>
      _clampText(s, _maxArtistName, _maxArtistNameBytes);

  static String? _clampMessage(String? s) =>
      s == null ? null : _clampText(s, _maxMessage, _maxMessageBytes);

  static Map<String, dynamic> _profile({
    required String artistName,
    String? message,
    required String currency,
    String? stripeUrl,
    String? revolutUsername,
    String? mobilepayBoxId,
    String? monzoUsername,
  }) =>
      {
        'artistName': artistName,
        'message': ?message,
        'currency': currency,
        'methods': {
          'stripeUrl': ?stripeUrl,
          'revolutUsername': ?revolutUsername,
          'mobilepayBoxId': ?mobilepayBoxId,
          'monzoUsername': ?monzoUsername,
        },
      };

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
    final json = await _send('createJar', {
      'profile': _profile(
        artistName: artistName,
        message: message,
        currency: currency,
        stripeUrl: stripeUrl,
        revolutUsername: revolutUsername,
        mobilepayBoxId: mobilepayBoxId,
        monzoUsername: monzoUsername,
      ),
      // Only a real account owns its jar; a transport-anonymous uid does not
      // (see [RelayAuth.ownsJars]).
      if (_auth.ownsJars) 'owned': true,
    });
    return (
      jar: RelayJar(
        jarId: json['jarId'] as String,
        tipUrl: json['tipUrl'] as String,
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

  /// Links this device's uid to [jarId] so the Firestore rules let it read
  /// (and ack) the jar's pending tips. Idempotent — the tip channel calls it
  /// once per attach, and re-calling it is how a device that was revoked by a
  /// secret rotation gets back in.
  Future<void> claimJar({
    required String jarId,
    required String secret,
  }) async {
    await _send('claimJar', {'jarId': jarId, 'secret': secret});
  }

  /// Updates the jar's public details. The relay wants the full profile back,
  /// so the untouched methods are re-sent from [jar]; only the Stripe URL is
  /// supplied fresh (it changes when the payment link is regenerated).
  Future<void> updateJar({
    required RelayJar jar,
    required String secret,
    required String artistName,
    String? message,
    String? stripeUrl,
  }) async {
    await _send('updateJarProfile', {
      'jarId': jar.jarId,
      'secret': secret,
      'profile': _profile(
        artistName: _clampName(artistName),
        message: _clampMessage(message),
        currency: jar.currency,
        stripeUrl: stripeUrl,
        revolutUsername: jar.revolutUsername,
        mobilepayBoxId: jar.mobilepayBoxId,
        monzoUsername: jar.monzoUsername,
      ),
    });
  }

  Future<void> deleteJar({
    required String jarId,
    required String secret,
  }) async {
    await _send('deleteJar', {'jarId': jarId, 'secret': secret});
  }

  /// Tells the relay the artist has seen everything so far — keeps the jar
  /// alive and resets the unseen-tips marker.
  Future<void> markSeen({
    required String jarId,
    required String secret,
  }) async {
    await _send('jarSeen', {'jarId': jarId, 'secret': secret});
  }

  /// Invalidates the old secret and returns the replacement. Also drops every
  /// OTHER device's read access to the jar — they re-claim with the new secret
  /// or stay out.
  Future<String> rotateSecret({
    required String jarId,
    required String secret,
  }) async {
    final json =
        await _send('rotateJarSecret', {'jarId': jarId, 'secret': secret});
    return json['secret'] as String;
  }

  Future<Map<String, dynamic>> _send(
    String name,
    Map<String, dynamic> args,
  ) async {
    // Every jar callable requires a signed-in caller. In local mode that is a
    // transport-only anonymous uid, minted here and nowhere else.
    final uid = await _auth.ensureRelayUid();
    if (uid == null) {
      throw const RelayNetworkException(
          'The relay is not available on this device.');
    }
    try {
      return await _invoke(name, args);
    } on FirebaseFunctionsException catch (e) {
      // A call that never landed is a network failure, not a verdict.
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw RelayNetworkException(e.message ?? 'The relay is unreachable.');
      }
      throw RelayApiException(
        code: e.code,
        message: e.message ?? 'The relay refused the request (${e.code}).',
      );
    } on RelayApiException {
      rethrow;
    } on RelayNetworkException {
      rethrow;
    } catch (e) {
      throw RelayNetworkException('$e');
    }
  }
}
