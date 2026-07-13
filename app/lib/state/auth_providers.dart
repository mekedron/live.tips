import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/account_sessions.dart';
import '../data/firebase/auth_service.dart';
import '../domain/app_account.dart';
import '../domain/pending_redirect.dart';
import 'onboarding_draft.dart';
import 'providers.dart';

/// The per-account Firebase stacks, overridden in main() on platforms that
/// have Firebase. The default refuses everything — tests and the platforms
/// without Firebase run local-only, exactly as before.
final accountSessionsProvider =
    Provider<AccountSessions>((ref) => AccountSessions.unavailable());

/// Ticks on every session add/remove so the handle providers below re-resolve
/// — a sign-out must not leave anyone holding the dead account's Firestore.
final accountSessionsChangesProvider = StreamProvider<int>((ref) {
  var n = 0;
  return ref.watch(accountSessionsProvider).changes.map((_) => ++n);
});

/// The ACTIVE profile's Firebase handles. A cloud profile with a live
/// session resolves to that account's own instances — which is what lets the
/// whole repository/session/device stack work unchanged across N signed-in
/// accounts. Everything else (the local profile, a profile whose session
/// died) falls back to the DEFAULT app: the relay's transport home. Null
/// only where Firebase isn't at all (Windows/Linux, tests, a failed boot).
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  final sessions = ref.watch(accountSessionsProvider);
  // No Firebase, no directory consultation: bare test containers (and the
  // platforms without Firebase) must resolve to null without needing a
  // LocalStore wired up.
  if (!sessions.available) return null;
  ref.watch(accountSessionsChangesProvider);
  final active =
      ref.watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
  if (active != kLocalAccountId) {
    final session = sessions.sessionFor(active);
    if (session != null) return session.auth;
  }
  return sessions.defaultAuth;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final sessions = ref.watch(accountSessionsProvider);
  if (!sessions.available) return null;
  ref.watch(accountSessionsChangesProvider);
  final active =
      ref.watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
  if (active != kLocalAccountId) {
    final db = sessions.sessionFor(active)?.firestore;
    if (db != null) return db;
  }
  return sessions.defaultFirestore;
});

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(firebaseAuthProvider)));

/// Builds the [AuthService] a slot sign-in runs on — a seam so tests can
/// script the provider flows without a Firebase app behind them.
final slotAuthServiceFactoryProvider =
    Provider<AuthService Function(FirebaseAuth)>((ref) => AuthService.new);

/// Whether an Apple/Google sign-in leaves the page (redirect) instead of
/// opening a popup. TRUE ON ALL OF THE WEB, and there is no popup path left at
/// all — see the note on [AuthController.signInWithGoogle]. A provider only so
/// tests can drive the redirect machinery without a browser under them.
final webRedirectSignInProvider = Provider<bool>((ref) => kIsWeb);

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

  /// True while [_run] owns [AuthState.user]. The userChanges stream fires in
  /// the middle of a sign-in, before [_adopt] has put the new account in the
  /// directory — and [_asAccount] would read that half-finished moment as
  /// "not an account" and wipe the user out from under us.
  bool _signingIn = false;

  @override
  AuthState build() {
    ref.onDispose(() => _sub?.cancel());
    final service = ref.watch(authServiceProvider);
    _sub?.cancel();
    _sub = service.userChanges().listen((user) {
      if (_signingIn) return;
      // A profile switch swaps the service out from under this listener:
      // its cancel comes with the REBUILD, but a queued event (the old
      // stream's replay) can still land first — and writing it would
      // clobber the new account's state right after the flush. Stale
      // generation, stale event: drop it.
      if (ref.read(authServiceProvider) != service) return;
      final account = _asAccount(user);
      state = state.copyWith(user: account, clearUser: account == null);
    });
    return AuthState(user: _asAccount(service.currentUser));
  }

  /// The Firebase user, IF it is an account this app should present as one.
  ///
  /// The relay signs in anonymously out of band, purely as a transport
  /// credential for the jar callables and the tip listener (see [RelayAuth]) —
  /// a local-profile artist has no account and must not acquire one by using
  /// the relay. That uid is a Firebase user like any other, so it surfaces on
  /// [AuthService.userChanges]; everything downstream of [AuthState.user] (the
  /// signed-in row in Settings, the switcher, the cloud-upload offer, the
  /// device registry) must not see it.
  ///
  /// The directory is the discriminator, not the kind: an *explicit*
  /// anonymous sign-in is a real account here (the "continue without an
  /// account" path), and [_adopt] records it. A transport uid never is.
  AuthUser? _asAccount(AuthUser? user) {
    if (user == null || user.kind != AccountKind.anonymous) return user;
    return ref.read(accountsDirectoryProvider).contains(user.uid) ? user : null;
  }

  bool get available => ref.read(authServiceProvider).available;

  /// On the WEB these do not return a user: they hand the browser to the
  /// provider ([_startRedirect]) and the app is torn down by the navigation.
  /// The result is claimed on the next boot by [consumePendingRedirect], which
  /// routes it through the very same slot/adopt path a native sign-in takes.
  ///
  /// There is no popup path any more, on any browser. Popups are blocked on
  /// iOS Safari unless they open inside a direct user gesture (the await before
  /// Firebase opens one is already enough to lose it), and inside an installed
  /// PWA the popup opens in a context that cannot post its result back — so it
  /// never errors, it just hangs. A "try popup, fall back on error" scheme
  /// cannot see that hang; the only way for a spinner to have no path to
  /// running forever is to not open a popup at all.
  ///
  /// [origin] is where the user was, so the return leg can put them back.
  Future<AuthUser?> signInWithApple({
    bool link = false,
    RedirectOrigin origin = RedirectOrigin.app,
  }) =>
      ref.read(webRedirectSignInProvider)
          ? _startRedirect(OAuthProviderKind.apple, link: link, origin: origin)
          : _run((s) => s.signInWithApple(link: link), link: link);

  Future<AuthUser?> signInWithGoogle({
    bool link = false,
    RedirectOrigin origin = RedirectOrigin.app,
  }) =>
      ref.read(webRedirectSignInProvider)
          ? _startRedirect(OAuthProviderKind.google, link: link, origin: origin)
          : _run((s) => s.signInWithGoogle(link: link), link: link);

  /// A guest account needs no provider page, so it never redirects — the same
  /// in-page sign-in on every platform.
  Future<AuthUser?> signInAnonymously() =>
      _run((s) => s.signInAnonymously());

  Future<AuthUser?> signInWithCustomToken(String token) =>
      _run((s) => s.signInWithCustomToken(token));

  /// The ONLY door into an account: every sign-in the artist actually asked
  /// for comes through here, and only what comes through here is adopted.
  ///
  /// A fresh sign-in runs on a NEW slot ([AccountSessions.begin]) so the
  /// accounts already signed in on this device are never disturbed; only a
  /// [link] (upgrading the CURRENT anonymous user in place) runs on the
  /// active account's own instance. Where slots don't exist (no Firebase,
  /// tests that stub [authServiceProvider]) the active service is the only
  /// door there is — today's single-session behavior, unchanged.
  Future<AuthUser?> _run(
    Future<AuthUser?> Function(AuthService) attempt, {
    bool link = false,
  }) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearError: true);
    _signingIn = true;
    final sessions = ref.read(accountSessionsProvider);
    PendingSession? pending;
    try {
      final AuthService service;
      if (!link && sessions.available) {
        pending = await sessions.begin();
        service = ref.read(slotAuthServiceFactoryProvider)(pending.auth);
      } else {
        service = ref.read(authServiceProvider);
      }
      final user = await attempt(service);
      if (user == null) {
        // Cancelled in the provider's own UI — the empty slot goes back.
        if (pending != null) await sessions.abandon(pending);
        state = state.copyWith(busy: false);
        return null;
      }
      if (pending != null) await sessions.commit(pending, user.uid);
      // Publish the user BEFORE flipping the directory: the repository
      // provider selects on (active profile, signed-in uid), and adopting
      // first would rebuild it against a stale null user.
      state = state.copyWith(user: user, busy: false);
      await _adopt(user);
      return user;
    } catch (e) {
      if (pending != null) unawaited(sessions.abandon(pending));
      debugPrint('sign-in failed: $e');
      state = state.copyWith(busy: false, error: friendlyAuthError(e));
      return null;
    } finally {
      _signingIn = false;
    }
  }

  /// The web half of [_run]: opens the slot, writes down everything the return
  /// leg will need, and hands the browser to the provider. Nothing after the
  /// navigation runs — this whole app instance is about to be destroyed — so
  /// the record MUST be persisted before the redirect starts, not after.
  ///
  /// Returns null: on the web a sign-in has no synchronous result. Callers
  /// treat that exactly as they treat a cancellation (stay put), and the page
  /// leaves under them.
  Future<AuthUser?> _startRedirect(
    OAuthProviderKind kind, {
    required bool link,
    required RedirectOrigin origin,
  }) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearError: true);
    _signingIn = true;
    final sessions = ref.read(accountSessionsProvider);
    final store = ref.read(localStoreProvider);
    PendingSession? pending;
    try {
      final AuthService service;
      final String appName;
      if (!link && sessions.available) {
        // A fresh sign-in gets its OWN app, same as the native path: the
        // accounts already signed in on this device must not be disturbed, and
        // the web SDK will file the redirect's result under this app's name.
        pending = await sessions.begin();
        service = ref.read(slotAuthServiceFactoryProvider)(pending.auth);
        appName = pending.appName;
      } else {
        // A link upgrades the CURRENT user, so it runs on that account's own
        // instance — the one authServiceProvider already fronts.
        service = ref.read(authServiceProvider);
        appName = (link ? sessions.appNameFor(state.user?.uid ?? '') : null) ??
            AccountSessions.defaultSlot;
      }
      await store.savePendingRedirect(PendingRedirect(
        appName: appName,
        provider: kind.name,
        link: link,
        uid: link ? state.user?.uid : null,
        origin: origin,
        prelude: ref.read(onboardingPreludeProvider),
        draft: ref.read(onboardingDraftProvider)?.toJson(),
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      await service.beginRedirectSignIn(kind, link: link);
      // The page is on its way out; the spinner rides along with it. If the
      // navigation somehow never happens, the record is still on disk and the
      // next boot clears it (a redirect with no result is "nothing happened").
      return null;
    } catch (e) {
      if (pending != null) unawaited(sessions.abandon(pending));
      await store.clearPendingRedirect();
      debugPrint('redirect sign-in failed to start: $e');
      state = state.copyWith(busy: false, error: friendlyAuthError(e));
      return null;
    } finally {
      _signingIn = false;
    }
  }

  /// The return leg of a web sign-in, consumed ONCE, early in startup (see
  /// RedirectSignInGate). Everything a popup sign-in does — slot commit,
  /// directory adopt, profile doc, the cloud-upload offer downstream of
  /// [AuthState.user] — happens here too, from the other side of a page reload.
  ///
  /// Null when there was nothing pending: the overwhelmingly common boot.
  Future<RedirectResume?> consumePendingRedirect() async {
    final store = ref.read(localStoreProvider);
    final record = store.readPendingRedirect();
    if (record == null) return null;
    // A record left behind by a build that could still redirect, on a platform
    // that cannot: drop it rather than carry it forever.
    if (!ref.read(webRedirectSignInProvider)) {
      await store.clearPendingRedirect();
      return null;
    }
    state = state.copyWith(busy: true, clearError: true);
    _signingIn = true;
    final sessions = ref.read(accountSessionsProvider);
    PendingSession? pending;
    try {
      final AuthService service;
      if (!record.link && sessions.available) {
        pending = await sessions.reopen(record.appName);
        service = pending == null
            ? ref.read(authServiceProvider)
            : ref.read(slotAuthServiceFactoryProvider)(pending.auth);
      } else {
        // A LINK never opens a slot: the guest account keeps the session (and
        // the uid) it already had, and only gains a provider. Opening a slot
        // for it would leave two apps fighting over one uid — and a guest
        // whose session lost that fight is a guest with no way back in.
        service = ref.read(authServiceProvider);
      }
      // A hard ceiling on the one await that stands between the user and the
      // app: whatever happens to the SDK, the boot spinner ends.
      final user = await service
          .completeRedirectSignIn()
          .timeout(const Duration(seconds: 30));
      await store.clearPendingRedirect();
      if (user == null) {
        // The user backed out of the provider's page, or the record was stale.
        // Not an error — but the empty slot goes back on the shelf.
        if (pending != null) await sessions.abandon(pending);
        state = state.copyWith(busy: false);
        return RedirectResume(record: record, user: null);
      }
      if (pending != null) await sessions.commit(pending, user.uid);
      state = state.copyWith(user: user, busy: false);
      await _adopt(user);
      return RedirectResume(record: record, user: user);
    } catch (e) {
      if (pending != null) unawaited(sessions.abandon(pending));
      await store.clearPendingRedirect();
      debugPrint('redirect sign-in failed: $e');
      final message = friendlyAuthError(e);
      state = state.copyWith(busy: false, error: message);
      return RedirectResume(record: record, user: null, error: message);
    } finally {
      _signingIn = false;
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

  /// Signs the ACTIVE account out — of its own instance only; every other
  /// account signed in on this device keeps its session. Lands on the local
  /// profile, and the directory keeps the entry (collapsed switcher row).
  Future<void> signOut() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    final sessions = ref.read(accountSessionsProvider);
    final uid = state.user?.uid ??
        ref.read(accountsDirectoryProvider).activeAccountId;
    try {
      if (sessions.isAlive(uid)) {
        await sessions.remove(uid);
      } else if (state.user != null) {
        // No slot to drop (legacy default-app session, or a stubbed service
        // in tests) — sign out of the instance the service fronts.
        await ref.read(authServiceProvider).signOut();
      }
    } catch (e) {
      debugPrint('sign-out failed: $e');
    }
    await ref
        .read(accountsDirectoryProvider.notifier)
        .setActive(kLocalAccountId);
    state = state.copyWith(clearUser: true, busy: false);
  }
}

/// What a consumed redirect turned out to be: the record that was waiting, and
/// the user it produced (null = cancelled, or [error] when it failed). The
/// caller needs the RECORD, not just the user: only it knows whether this was
/// a link, and where in the app the flow started.
class RedirectResume {
  const RedirectResume({required this.record, this.user, this.error});

  final PendingRedirect record;
  final AuthUser? user;
  final String? error;
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
