import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Where the app's Cloud Functions live (index.ts pins the region).
const kFunctionsRegion = 'europe-west1';

/// The functions SDK's own default deadline, kept so no call waits longer
/// under this transport than it did under that one.
const _kCallTimeout = Duration(seconds: 70);

/// One callable invocation over PLAIN HTTP — the app's only road to a Cloud
/// Function, deliberately not through the functions SDK's call().
///
/// On the web that SDK decorates EVERY callable with a fresh messaging token
/// minted from its own Firebase app the moment notification permission is
/// granted. Our callables ride the per-account slot apps, so each call
/// registered a SECOND FCM installation against the same browser push
/// subscription — which invalidates the token stored on this device's doc,
/// the next send prunes it, and the notifications toggle "turns itself off".
/// Found live on the test button (2026-07-15); mintSessionToken — fired on
/// every account switch — was doing the same thing all along. A bare POST
/// with the caller's ID token is the same authenticated call, minus the
/// assassination.
///
/// [functions] is the ADDRESS, never the transport: its app names the
/// project and, more importantly, the session whose user signs the call —
/// the ID token must come from the same slot the SDK call would have ridden,
/// not from whichever account happens to be active. An app with nobody
/// signed in (the venue tablet redeeming a link code) simply sends no
/// Authorization header, exactly as the SDK would.
///
/// Returns the callable's `result` object (an empty map when it isn't one).
/// A refusal throws [FirebaseFunctionsException] with the server's own code
/// (`failed-precondition`, `not-found`, …) so existing call sites keep
/// their verdicts; anything that keeps the call from landing at all
/// (offline, DNS, the timeout) propagates raw — every caller already reads
/// a non-functions exception as "network", and it must never be mistaken
/// for a server verdict.
Future<Map<String, dynamic>> callCallable(
  FirebaseFunctions functions,
  String name, [
  Map<String, dynamic> args = const {},
]) async {
  final user = FirebaseAuth.instanceFor(app: functions.app).currentUser;
  // getIdToken caches and refreshes on its own — no bookkeeping here.
  final idToken = user == null ? null : await user.getIdToken();
  final projectId = functions.app.options.projectId;
  final response = await http
      .post(
        Uri.https('$kFunctionsRegion-$projectId.cloudfunctions.net', '/$name'),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null && idToken.isNotEmpty)
            'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'data': args}),
      )
      .timeout(_kCallTimeout);
  if (response.statusCode != 200) throw _errorFrom(response);
  final body = jsonDecode(response.body);
  final result = body is Map ? body['result'] : null;
  return result is Map ? result.cast<String, dynamic>() : const {};
}

/// A refusal, decoded the way the SDK would have: the wire carries
/// `{"error": {"status": "NOT_FOUND", "message": …, "details"?: …}}` and the
/// canonical code is that status lowercased with hyphens. A body that isn't
/// the callable shape (a load balancer's error page for a name that doesn't
/// exist, a crash before the framework answered) falls back to the HTTP
/// status, mapped exactly as the SDK maps it.
FirebaseFunctionsException _errorFrom(http.Response response) {
  String? status;
  String? message;
  Object? details;
  try {
    final body = jsonDecode(response.body);
    final error = body is Map ? body['error'] : null;
    if (error is Map) {
      status = error['status'] as String?;
      message = error['message'] as String?;
      details = error['details'];
    }
  } catch (_) {
    // Not JSON — the HTTP status below carries what truth there is.
  }
  return _WireFunctionsException(
    code: status?.toLowerCase().replaceAll('_', '-') ??
        _codeForHttpStatus(response.statusCode),
    message: message ?? 'HTTP ${response.statusCode}',
    details: details,
  );
}

/// The SDK's HTTP-status fallback table, verbatim.
String _codeForHttpStatus(int status) => switch (status) {
      400 => 'invalid-argument',
      401 => 'unauthenticated',
      403 => 'permission-denied',
      404 => 'not-found',
      409 => 'aborted',
      429 => 'resource-exhausted',
      499 => 'cancelled',
      500 => 'internal',
      501 => 'unimplemented',
      503 => 'unavailable',
      504 => 'deadline-exceeded',
      _ => 'unknown',
    };

/// The plugin's exception, minted from the wire. Its constructor is
/// `@protected`, so a subclass is the sanctioned door (test/helpers.dart
/// does the same) — call sites keep catching FirebaseFunctionsException
/// with the codes they always caught.
class _WireFunctionsException extends FirebaseFunctionsException {
  _WireFunctionsException({
    required super.code,
    required super.message,
    super.details,
  });
}
