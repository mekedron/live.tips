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
    this.providers = const [],
  });

  final String uid;
  final AccountKind kind;
  final String? displayName;
  final String? email;

  /// Every PERMANENT sign-in method attached to this account. Empty for a
  /// guest — and that emptiness is the whole of what "Link Apple or Google
  /// first" is about: nothing can sign the account back in, and unlinking the
  /// last one would put it back there (see AuthController.unlinkProvider).
  /// [kind] is simply the first of these; it says which icon to draw, not how
  /// many ways back in the account has.
  final List<AccountKind> providers;

  bool get isGuest => providers.isEmpty;
}

/// The permanent methods on [user], in Firebase's own order.
List<AccountKind> _providersOf(User user) {
  final kinds = <AccountKind>[];
  for (final info in user.providerData) {
    final kind = switch (info.providerId) {
      'apple.com' => AccountKind.apple,
      'google.com' => AccountKind.google,
      _ => null,
    };
    if (kind != null && !kinds.contains(kind)) kinds.add(kind);
  }
  return kinds;
}

AuthUser toAuthUser(User user) {
  final providers = _providersOf(user);
  return AuthUser(
    uid: user.uid,
    // A linked account is no longer isAnonymous, and an account with no
    // provider left is a guest again — so the list IS the answer.
    kind: providers.isEmpty ? AccountKind.anonymous : providers.first,
    displayName: user.displayName,
    email: user.email,
    providers: providers,
  );
}

/// The Firebase provider id for a linkable method, or null for a kind that is
/// not one (local, anonymous — the absence of a method).
String? providerIdOf(AccountKind kind) => switch (kind) {
      AccountKind.apple => 'apple.com',
      AccountKind.google => 'google.com',
      _ => null,
    };

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

  /// On the web the provider flows leave the page for the auth bridge and the
  /// result comes back as a custom token (see auth_bridge.dart and
  /// AuthController). There is deliberately NO popup path (blocked on iOS
  /// Safari, hangs forever inside an installed PWA) and NO in-app
  /// signInWithRedirect either — Safari partitions the cross-origin iframe
  /// storage that flow needs, so it completes on Google's side and delivers
  /// nothing. Both failure modes end here, at this seam.
  static const _noWebProviderFlow = AuthUnavailableException(
      'Web sign-in runs through the auth bridge — see AuthController.');

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

  /// Detaches [kind] from the CURRENT user and returns what is left of it.
  ///
  /// Firebase will happily unlink the LAST method and hand back an account
  /// nobody — the owner included — can ever sign into again. It does not
  /// refuse; [AuthController.unlinkProvider] does, before this is ever called.
  Future<AuthUser?> unlinkProvider(AccountKind kind) async {
    final auth = _required;
    final user = auth.currentUser;
    final providerId = providerIdOf(kind);
    if (user == null || providerId == null) return null;
    return toAuthUser(await user.unlink(providerId));
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
