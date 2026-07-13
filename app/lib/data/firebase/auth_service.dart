import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/app_account.dart';

/// Thrown when a sign-in cannot proceed for a reason worth telling the
/// user (as opposed to a silent cancellation, which returns null).
class AuthUnavailableException implements Exception {
  const AuthUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The federated providers the app offers. Named rather than passed as a
/// Firebase [AuthProvider] because a redirect sign-in has to name its provider
/// in local storage and rebuild it after a page reload.
enum OAuthProviderKind {
  google,
  apple;

  static OAuthProviderKind fromName(String name) =>
      values.where((v) => v.name == name).firstOrNull ?? OAuthProviderKind.google;
}

/// A signed-in Firebase user reduced to what the app actually shows.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.kind,
    this.displayName,
    this.email,
  });

  final String uid;
  final AccountKind kind;
  final String? displayName;
  final String? email;
}

AccountKind _kindOf(User user) {
  if (user.isAnonymous) return AccountKind.anonymous;
  for (final info in user.providerData) {
    if (info.providerId == 'apple.com') return AccountKind.apple;
    if (info.providerId == 'google.com') return AccountKind.google;
  }
  return AccountKind.anonymous;
}

AuthUser toAuthUser(User user) => AuthUser(
      uid: user.uid,
      kind: _kindOf(user),
      displayName: user.displayName,
      email: user.email,
    );

/// Everything Firebase Auth, behind one seam. Constructed with a null
/// [FirebaseAuth] on platforms/builds without Firebase — then [userChanges]
/// is a steady null and every sign-in throws [AuthUnavailableException].
///
/// Sign-in methods return the signed-in [AuthUser], or null when the user
/// cancelled the provider's own UI (not an error, nothing to show).
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth? _auth;
  bool _googleInitialized = false;

  bool get available => _auth != null;

  Stream<AuthUser?> userChanges() {
    final auth = _auth;
    if (auth == null) return Stream<AuthUser?>.value(null);
    return auth
        .userChanges()
        .map((user) => user == null ? null : toAuthUser(user));
  }

  AuthUser? get currentUser {
    final user = _auth?.currentUser;
    return user == null ? null : toAuthUser(user);
  }

  FirebaseAuth get _required =>
      _auth ??
      (throw const AuthUnavailableException(
          'Cloud accounts are not available on this platform.'));

  Future<AuthUser?> signInAnonymously() async {
    final credential = await _required.signInAnonymously();
    final user = credential.user;
    return user == null ? null : toAuthUser(user);
  }

  Future<AuthUser?> signInWithCustomToken(String token) async {
    final credential = await _required.signInWithCustomToken(token);
    final user = credential.user;
    return user == null ? null : toAuthUser(user);
  }

  /// The provider flows that hand the browser away and come back through a
  /// page reload live in [beginRedirectSignIn] / [completeRedirectSignIn].
  /// There is deliberately NO popup path any more: popups are blocked on iOS
  /// Safari, and inside an installed PWA the popup cannot post its result back
  /// to the app at all — it hangs, forever, which is exactly the failure this
  /// seam exists to make impossible.
  static const _noWebProviderFlow = AuthUnavailableException(
      'Web sign-in runs through a redirect — see beginRedirectSignIn.');

  /// [link] upgrades the CURRENT (anonymous) user instead of switching users.
  Future<AuthUser?> signInWithGoogle({bool link = false}) async {
    final auth = _required;
    if (kIsWeb) throw _noWebProviderFlow;
    final credential = await _googleCredential();
    if (credential == null) return null; // user closed the account picker
    final result = link && auth.currentUser != null
        ? await auth.currentUser!.linkWithCredential(credential)
        : await auth.signInWithCredential(credential);
    final user = result.user;
    return user == null ? null : toAuthUser(user);
  }

  Future<AuthUser?> signInWithApple({bool link = false}) async {
    final auth = _required;
    if (kIsWeb) throw _noWebProviderFlow;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // No native Apple flow on Android — Firebase drives the web flow.
      final provider = AppleAuthProvider()..addScope('email');
      final result = link && auth.currentUser != null
          ? await auth.currentUser!.linkWithProvider(provider)
          : await auth.signInWithProvider(provider);
      final user = result.user;
      return user == null ? null : toAuthUser(user);
    }
    // iOS/macOS: the native Sign in with Apple sheet, replay-protected by
    // a nonce (Apple signs the hash; Firebase checks it against the raw).
    final rawNonce = _randomNonce();
    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    final result = link && auth.currentUser != null
        ? await auth.currentUser!.linkWithCredential(oauth)
        : await auth.signInWithCredential(oauth);
    final user = result.user;
    // Apple hands the name over exactly once, on first authorization —
    // keep it on the Firebase profile or it's gone for good.
    final givenName = appleCredential.givenName;
    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty) &&
        givenName != null) {
      final fullName = [givenName, appleCredential.familyName]
          .whereType<String>()
          .join(' ')
          .trim();
      if (fullName.isNotEmpty) await user.updateDisplayName(fullName);
    }
    return user == null ? null : toAuthUser(user);
  }

  /// WEB: hands the browser to the provider's own page. This does not return a
  /// user — the app is torn down by the navigation and the result is picked up
  /// by [completeRedirectSignIn] on the next boot. Callers must have persisted
  /// everything they need to resume BEFORE awaiting this.
  ///
  /// [link] upgrades the CURRENT (anonymous) user in place (`linkWithRedirect`)
  /// rather than signing a new one in.
  Future<void> beginRedirectSignIn(
    OAuthProviderKind kind, {
    bool link = false,
  }) async {
    final auth = _required;
    final AuthProvider provider = switch (kind) {
      OAuthProviderKind.google => GoogleAuthProvider(),
      OAuthProviderKind.apple => AppleAuthProvider()..addScope('email'),
    };
    if (link) {
      final user = auth.currentUser;
      if (user == null) {
        throw const AuthUnavailableException(
            'There is no account to link this provider to.');
      }
      await user.linkWithRedirect(provider);
      return;
    }
    await auth.signInWithRedirect(provider);
  }

  /// WEB: the result of a redirect started before the page reload — for a
  /// sign-in AND for a link, which resolve through the same door. Null when no
  /// redirect was pending (a normal boot, or the user backed out of the
  /// provider's page): that is not an error, it is "nothing happened".
  ///
  /// EXCEPT that `getRedirectResult` lies by omission. The web SDK files the
  /// "a redirect is in flight" marker in sessionStorage, and WebKit does not
  /// always hand that storage back to the page it returns to — so the sign-in
  /// COMPLETES (the SDK has the user, persisted), while the result comes back
  /// empty. Believing it verbatim is what made a successful Google sign-in end
  /// with no account on the phone at all: no error, no spinner, nothing.
  ///
  /// So an empty result is not taken as "nothing happened" until the instance
  /// itself agrees it has nobody. Restoring a persisted user is asynchronous,
  /// hence the short wait on [authStateChanges] rather than a bare read.
  ///
  /// [kind] and [link] exist for the honesty of the link path: upgrading a
  /// guest leaves `currentUser` non-null WHETHER OR NOT the provider attached,
  /// so a link may only be called successful when the provider is actually on
  /// the account. Reporting otherwise would tell someone their guest account
  /// was upgraded when it was not.
  Future<AuthUser?> completeRedirectSignIn({
    OAuthProviderKind? kind,
    bool link = false,
  }) async {
    final auth = _required;
    final result = await auth.getRedirectResult();
    var user = result.user;

    if (user == null) {
      final restored = auth.currentUser ??
          await auth
              .authStateChanges()
              .where((u) => u != null)
              .first
              .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (restored != null) {
        if (!link) {
          user = restored;
        } else if (kind != null && _hasProvider(restored, kind)) {
          // The link really did land; only the result went missing.
          user = restored;
        }
      }
    }
    return user == null ? null : toAuthUser(user);
  }

  static bool _hasProvider(User user, OAuthProviderKind kind) {
    final id = switch (kind) {
      OAuthProviderKind.google => 'google.com',
      OAuthProviderKind.apple => 'apple.com',
    };
    return user.providerData.any((p) => p.providerId == id);
  }

  Future<void> updateDisplayName(String name) async {
    await _required.currentUser?.updateDisplayName(name.trim());
  }

  Future<void> signOut() async {
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google's local session is best-effort cleanup.
      }
    }
    await _required.signOut();
  }

  Future<OAuthCredential?> _googleCredential() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize();
      _googleInitialized = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthUnavailableException(
          'Google sign-in returned no identity token.');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}
