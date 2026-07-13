/// The web sign-in bridge — the app's half of firebase/hosting-public/signin.html.
///
/// A web sign-in cannot complete on the app's own origin: Firebase's redirect
/// flow delivers its result through an iframe on the authDomain origin, and
/// Safari (all of WebKit — macOS, iPhone, installed PWAs) hands a cross-origin
/// iframe partitioned, EMPTY storage, even for a same-site subdomain like
/// auth.live.tips under live.tips. The sign-in finishes on the provider's side
/// and the app never hears about it: no user, no error, nothing. That is the
/// bug this module exists to end.
///
/// So the app never calls signInWithRedirect at all. It navigates, top-level,
/// to the bridge page on auth.live.tips — where the whole redirect flow is
/// first-party and works in every browser — and the bridge brings the session
/// back as a Firebase custom token in a URL fragment:
///
///   out:  https://auth.live.tips/signin#req={provider, return, state, linkToken?}
///   back: `<return>`#signin={v, state, token?, error?}
///
/// `state` is a nonce written into the PendingRedirect record before leaving;
/// a response that does not echo it is not ours and is ignored. A fragment
/// never reaches a server, and the token grants only the uid that had just
/// signed in on the bridge.
library;

import 'dart:convert';
import 'dart:math';

import 'auth_bridge_stub.dart'
    if (dart.library.js_interop) 'auth_bridge_web.dart' as impl;

/// What the bridge sent back: exactly one of [token] (signed in) or [error]
/// (failed) — or neither, which is the user backing out on the provider's
/// page (not an error, nothing to show).
class BridgeResponse {
  const BridgeResponse({required this.nonce, this.token, this.error});

  /// The `state` the request carried, echoed verbatim.
  final String nonce;

  /// A Firebase custom token for the freshly signed-in (or freshly linked)
  /// account — the session, carried across origins.
  final String? token;

  /// A firebase error code (`auth/...`) when the bridge flow failed.
  final String? error;

  bool get cancelled => token == null && error == null;
}

/// The `#signin=` fragment out of a boot URL, or null when this boot did not
/// come back from the bridge. Garbled payloads are also null: a fragment we
/// cannot read is a fragment we cannot act on.
BridgeResponse? parseBridgeResponse(String url) {
  // Split by hand: Uri.fragment's percent-decoding is not guaranteed across
  // parse paths, and the payload must be decoded exactly once.
  final hash = url.indexOf('#');
  if (hash < 0) return null;
  final fragment = url.substring(hash + 1);
  if (!fragment.startsWith('signin=')) return null;
  try {
    final decoded =
        jsonDecode(Uri.decodeComponent(fragment.substring('signin='.length)))
            as Map<String, dynamic>;
    final nonce = decoded['state'] as String?;
    if (nonce == null || nonce.isEmpty) return null;
    return BridgeResponse(
      nonce: nonce,
      token: decoded['token'] as String?,
      error: decoded['error'] as String?,
    );
  } catch (_) {
    return null;
  }
}

/// The outbound bridge URL for one sign-in attempt.
Uri bridgeSignInUri({
  required String bridgeUrl,
  required String provider,
  required Uri returnUrl,
  required String nonce,
  String? linkToken,
}) {
  final req = jsonEncode({
    'provider': provider,
    'return': returnUrl.toString(),
    'state': nonce,
    'linkToken': ?linkToken,
  });
  return Uri.parse('$bridgeUrl#req=${Uri.encodeComponent(req)}');
}

/// A fresh `state` nonce. Not a secret — it only pairs a response with the
/// attempt that is actually pending — but unguessable anyway, so a stale or
/// foreign fragment can never match.
String newBridgeNonce() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
}

/// Hands the browser to the bridge. WEB ONLY: this navigates the page away
/// and the running app dies with it — everything the return leg needs must be
/// persisted before calling. Throws [UnsupportedError] elsewhere.
Future<void> launchAuthBridge(Uri uri) => impl.launchAuthBridge(uri);
