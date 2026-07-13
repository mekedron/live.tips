import 'dart:async';

import '../../domain/app_account.dart';
import '../firebase/auth_service.dart';

/// The relay's transport credential.
///
/// Every jar callable requires a signed-in caller, and the Firestore rules
/// authorize the tip listener by uid — but a LOCAL-profile artist has no
/// account and must never be given one. So the relay signs in anonymously
/// *purely as a transport identity*: it is created out of band, through
/// [AuthService] directly, and never travels through [AuthController._run],
/// which is the only place that adopts a user into the accounts directory or
/// flips the active profile. A transport uid therefore never becomes a
/// "cloud profile": it doesn't appear in the switcher, doesn't change the
/// repository selection, and survives exactly as long as the Firebase Auth
/// session on this device.
///
/// Null uid means "no relay on this device" (Firebase absent, or the
/// anonymous sign-in failed). Every caller already tolerates that — the app
/// runs relay-less, as it does today on Windows/Linux.
class RelayAuth {
  RelayAuth(this._auth);

  final AuthService _auth;

  /// De-dupes concurrent sign-ins: the keepalive, a jar create and the tip
  /// channel can all ask at once on a cold start, and each anonymous sign-in
  /// would otherwise mint (and strand) its own uid.
  Future<String?>? _signIn;

  bool get available => _auth.available;

  /// The uid to use for the relay: the signed-in user's if there is one,
  /// otherwise a fresh anonymous transport identity. Null when Firebase is
  /// unavailable or the sign-in failed.
  Future<String?> ensureRelayUid() async {
    if (!_auth.available) return null;
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    return _signIn ??= _signInAnonymously();
  }

  Future<String?> _signInAnonymously() async {
    try {
      final user = await _auth.signInAnonymously();
      return user?.uid;
    } catch (_) {
      // Offline, or anonymous auth disabled on the project. The relay is
      // simply unavailable this launch; the next call retries.
      return null;
    } finally {
      _signIn = null;
    }
  }

  /// Whether a jar created now should be pinned to the caller's uid
  /// (`ownerUid`). Only a REAL account may own a jar: pinning one to a
  /// throwaway transport uid would tie the artist's public page to an
  /// identity nothing else in the app remembers. For everyone else the jar
  /// secret stays the sole root credential — exactly the worker's model.
  bool get ownsJars {
    final user = _auth.currentUser;
    return user != null && user.kind != AccountKind.anonymous;
  }
}
