import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/auth_service.dart';
import '../domain/app_account.dart';
import 'providers.dart';

/// Live Firebase handles, overridden in main() on platforms that have them.
/// Null everywhere else (Windows/Linux, tests, a failed Firebase boot) —
/// the app then runs local-only and every cloud surface hides itself.
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) => null);
final firestoreProvider = Provider<FirebaseFirestore?>((ref) => null);

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(firebaseAuthProvider)));

/// Every profile this device knows (the local one plus signed-in Firebase
/// accounts) and which is active. Persisted device-wide in prefs.
class AccountsDirectoryNotifier extends Notifier<AccountsDirectory> {
  @override
  AccountsDirectory build() =>
      ref.read(localStoreProvider).readAccountsDirectory() ??
      AccountsDirectory.initial();

  Future<void> _commit(AccountsDirectory next) async {
    state = next;
    await ref.read(localStoreProvider).saveAccountsDirectory(next);
  }

  Future<void> upsert(AppAccount account) => _commit(state.withAccount(account));

  Future<void> setActive(String id) async {
    if (!state.contains(id)) return;
    await _commit(state.withActive(id));
  }

  Future<void> remove(String id) => _commit(state.withoutAccount(id));

  Future<void> rename(String id, String name) async {
    final entry = state.accounts.where((a) => a.id == id).firstOrNull;
    if (entry == null) return;
    await _commit(state.withAccount(entry.copyWith(name: name.trim())));
  }
}

final accountsDirectoryProvider =
    NotifierProvider<AccountsDirectoryNotifier, AccountsDirectory>(
        AccountsDirectoryNotifier.new);

class AuthState {
  const AuthState({this.user, this.busy = false, this.error});

  /// The signed-in Firebase user, or null (local mode / signed out).
  final AuthUser? user;

  /// A sign-in/out is in flight — buttons disable, spinners spin.
  final bool busy;

  /// The last sign-in failure, user-facing. Cleared on the next attempt.
  final String? error;

  AuthState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? busy,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Owns the Firebase Auth session: sign-in (Apple/Google/anonymous), account
/// linking, the account name, and sign-out. Mirrors every signed-in user
/// into the accounts directory so the switcher can list it, and keeps a
/// users/{uid} profile doc in Firestore (best effort — offline sign-ins
/// catch up through Firestore's write queue).
class AuthController extends Notifier<AuthState> {
  StreamSubscription<AuthUser?>? _sub;

  @override
  AuthState build() {
    ref.onDispose(() => _sub?.cancel());
    final service = ref.watch(authServiceProvider);
    _sub?.cancel();
    _sub = service.userChanges().listen((user) {
      state = state.copyWith(user: user, clearUser: user == null);
    });
    return AuthState(user: service.currentUser);
  }

  bool get available => ref.read(authServiceProvider).available;

  Future<AuthUser?> signInWithApple({bool link = false}) =>
      _run((s) => s.signInWithApple(link: link));

  Future<AuthUser?> signInWithGoogle({bool link = false}) =>
      _run((s) => s.signInWithGoogle(link: link));

  Future<AuthUser?> signInAnonymously() =>
      _run((s) => s.signInAnonymously());

  Future<AuthUser?> signInWithCustomToken(String token) =>
      _run((s) => s.signInWithCustomToken(token));

  Future<AuthUser?> _run(
      Future<AuthUser?> Function(AuthService) attempt) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final user = await attempt(ref.read(authServiceProvider));
      // Publish the user BEFORE flipping the directory: the repository
      // provider selects on (active profile, signed-in uid), and adopting
      // first would rebuild it against a stale null user.
      state = state.copyWith(user: user, busy: false);
      if (user != null) await _adopt(user);
      return user;
    } catch (e) {
      debugPrint('sign-in failed: $e');
      state = state.copyWith(busy: false, error: friendlyAuthError(e));
      return null;
    }
  }

  /// Records [user] in the directory, makes it active, and freshens its
  /// users/{uid} profile doc.
  Future<void> _adopt(AuthUser user) async {
    final directory = ref.read(accountsDirectoryProvider.notifier);
    final existing = ref
        .read(accountsDirectoryProvider)
        .accounts
        .where((a) => a.id == user.uid)
        .firstOrNull;
    final entry = AppAccount(
      id: user.uid,
      // A name chosen in the app wins over the provider's; a fresh account
      // starts with whatever the provider knows.
      name: existing != null && existing.name.isNotEmpty
          ? existing.name
          : (user.displayName ?? ''),
      kind: user.kind,
      email: user.email,
      lastUsedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await directory.upsert(entry);
    await directory.setActive(user.uid);
    unawaited(_writeProfileDoc(entry));
  }

  /// Names the ACCOUNT (not a band): Firebase profile + directory + doc.
  Future<void> setAccountName(String name) async {
    final user = state.user;
    if (user == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await ref.read(authServiceProvider).updateDisplayName(trimmed);
    } catch (_) {
      // The profile name is cosmetic; the directory + doc still update.
    }
    await ref.read(accountsDirectoryProvider.notifier).rename(user.uid, trimmed);
    final entry = ref
        .read(accountsDirectoryProvider)
        .accounts
        .where((a) => a.id == user.uid)
        .firstOrNull;
    if (entry != null) unawaited(_writeProfileDoc(entry));
  }

  Future<void> _writeProfileDoc(AppAccount entry) async {
    final db = ref.read(firestoreProvider);
    if (db == null) return;
    try {
      await db.doc('users/${entry.id}').set({
        'name': entry.name,
        'authProvider': entry.kind.name,
        'createdAtMs': FieldValue.serverTimestamp(),
      }, SetOptions(mergeFields: ['name', 'authProvider']));
    } catch (e) {
      debugPrint('profile doc write failed: $e');
    }
  }

  /// Signs out of Firebase and lands on the local profile. The directory
  /// keeps the entry (collapsed switcher row); Phase 6 adds the keychain
  /// scrub of that account's cached secrets.
  Future<void> signOut() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      debugPrint('sign-out failed: $e');
    }
    await ref
        .read(accountsDirectoryProvider.notifier)
        .setActive(kLocalAccountId);
    state = state.copyWith(clearUser: true, busy: false);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Reduces provider/SDK exceptions to something worth showing on a button.
String friendlyAuthError(Object e) {
  if (e is AuthUnavailableException) return e.message;
  final text = e.toString();
  // FirebaseAuthException.toString() leads with the bracketed code — keep
  // the human sentence after it when there is one.
  final match = RegExp(r'\]\s*(.+)$').firstMatch(text);
  return match?.group(1) ?? text;
}
