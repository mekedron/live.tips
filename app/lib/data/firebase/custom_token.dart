import 'dart:convert';

/// Reads the `uid` claim out of a Firebase custom token WITHOUT verifying it.
///
/// Good enough for exactly one job: the venue re-approval check compares this
/// uid against the account already on the tablet before deciding whether the
/// approval came from the same artist. Nothing is granted on the claim alone
/// — a forged token would fail the actual sign-in, which is where Firebase
/// verifies the signature. Returns null for anything that doesn't parse.
String? uidOfCustomToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload) as Map<String, dynamic>;
    final uid = claims['uid'];
    return uid is String && uid.isNotEmpty ? uid : null;
  } catch (_) {
    return null;
  }
}
