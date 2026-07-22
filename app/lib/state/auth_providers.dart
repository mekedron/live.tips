import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/account_service.dart';
import '../data/firebase/account_sessions.dart';
import '../data/firebase/auth_bridge.dart';
import '../data/firebase/auth_domain.dart';
import '../data/firebase/auth_service.dart';
import '../data/firebase/callables.dart';
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

/// Whether an Apple/Google sign-in leaves the page (for the auth bridge)
/// instead of opening a popup. TRUE ON ALL OF THE WEB, and there is no popup
/// path left at all — see the note on [AuthController.signInWithGoogle]. A
/// provider only so tests can drive the redirect machinery without a browser
/// under them.
final webRedirectSignInProvider = Provider<bool>((ref) => kIsWeb);

/// The bridge's answer, if this boot came back from one — parsed out of the
/// boot URL in main(), BEFORE Flutter's URL strategy scrubs the fragment
/// (exactly like the add-device `#c=` link). Null on every ordinary boot.
final bridgeResponseProvider = Provider<BridgeResponse?>((ref) => null);

/// Hands the browser to the bridge. A seam: the real thing navigates the page
/// away and cannot run under a test.
final bridgeLauncherProvider =
    Provider<Future<void> Function(Uri)>((ref) => launchAuthBridge);

/// Mints the custom token a LINK carries to the bridge — the guest's own
/// session, riding along so `linkWithRedirect` upgrades that uid instead of
/// signing somebody new in. A seam so tests can script it without Cloud
/// Functions underneath.
final linkTokenMinterProvider = Provider<Future<String> Function()>((ref) {
  return () async {
    final sessions = ref.read(accountSessionsProvider);
    final uid = ref.read(authControllerProvider).user?.uid;
    final functions = (uid == null
            ? null
            : sessions.sessionFor(uid)?.functions(kFunctionsRegion)) ??
        sessions.defaultFunctions(kFunctionsRegion);
    if (functions == null) {
      throw const AuthUnavailableException(
          'Cloud accounts are not available on this platform.');
    }
    final data = await callCallable(functions, 'mintSessionToken');
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthUnavailableException(
          'Sign-in is unavailable right now. Try again in a moment.');
    }
    return token;
  };
});

/// The account-level callables (deleteAccount today), resolved against the
/// ACTIVE account's own Firebase app — like [linkTokenMinterProvider], and for
/// the same reason: a callable that erases an account must speak AS that
/// account. Null functions wherever Firebase isn't; the service then refuses
/// politely instead of the app crashing on a null.
final accountServiceProvider = Provider<AccountService>((ref) {
  final sessions = ref.watch(accountSessionsProvider);
  ref.watch(accountSessionsChangesProvider);
  final active =
      ref.watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
  final functions = (active != kLocalAccountId
          ? sessions.sessionFor(active)?.functions(kFunctionsRegion)
          : null) ??
      sessions.defaultFunctions(kFunctionsRegion);
  return AccountService(functions: functions);
});

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
          : _run((s) => s.signInWithApple(link: link), inPlace: link);

  Future<AuthUser?> signInWithGoogle({
    bool link = false,
    RedirectOrigin origin = RedirectOrigin.app,
  }) =>
      ref.read(webRedirectSignInProvider)
          ? _startRedirect(OAuthProviderKind.google, link: link, origin: origin)
          : _run((s) => s.signInWithGoogle(link: link), inPlace: link);

  /// A guest account needs no provider page, so it never redirects — the same
  /// in-page sign-in on every platform.
  Future<AuthUser?> signInAnonymously() =>
      _run((s) => s.signInAnonymously());

  /// Redeems a custom token. A new device's token (the QR handshake, the venue
  /// tablet) signs a NEW account in and gets its own slot; [inPlace] is for the
  /// token the server mints for a session we ALREADY hold — the kill switch's
  /// way back in (#34), which is the same uid on the same account and must
  /// re-seat that account's own instance rather than open a second one beside
  /// it.
  Future<AuthUser?> signInWithCustomToken(String token,
          {bool inPlace = false}) =>
      _run((s) => s.signInWithCustomToken(token), inPlace: inPlace);

  /// The ONLY door into an account: every sign-in the artist actually asked
  /// for comes through here, and only what comes through here is adopted.
  ///
  /// A fresh sign-in runs on a NEW slot ([AccountSessions.begin]) so the
  /// accounts already signed in on this device are never disturbed. [inPlace]
  /// runs on the ACTIVE account's own instance instead — a link (upgrading the
  /// current anonymous user), or a re-seat of the session that account is
  /// already signed in with. Where slots don't exist (no Firebase, tests that
  /// stub [authServiceProvider]) the active service is the only door there is
  /// — today's single-session behavior, unchanged.
  Future<AuthUser?> _run(
    Future<AuthUser?> Function(AuthService) attempt, {
    bool inPlace = false,
  }) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearError: true);
    _signingIn = true;
    final sessions = ref.read(accountSessionsProvider);
    PendingSession? pending;
    try {
      final AuthService service;
      if (!inPlace && sessions.available) {
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
  /// leg will need, and hands the browser to the auth bridge (never to the
  /// in-page SDK redirect — see auth_bridge.dart for why that flow can only
  /// lose in Safari). Nothing after the navigation runs — this whole app
  /// instance is about to be destroyed — so the record MUST be persisted
  /// before the navigation starts, not after.
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
      final String appName;
      String? linkToken;
      if (!link && sessions.available) {
        // A fresh sign-in gets its OWN app, same as the native path — and
        // begin() enforces the account cap HERE, before the page leaves, so
        // "this device is full" is an error on the button and not a surprise
        // after the whole Google round trip.
        pending = await sessions.begin();
        appName = pending.appName;
      } else {
        // A link upgrades the CURRENT user in place. Its session travels to
        // the bridge as a custom token, so linkWithRedirect over there runs
        // as this uid — and everything the guest owns stays on it.
        appName = (link ? sessions.appNameFor(state.user?.uid ?? '') : null) ??
            AccountSessions.defaultSlot;
        if (link) linkToken = await ref.read(linkTokenMinterProvider)();
      }
      final nonce = newBridgeNonce();
      await store.savePendingRedirect(PendingRedirect(
        appName: appName,
        provider: kind.name,
        link: link,
        uid: link ? state.user?.uid : null,
        origin: origin,
        draft: ref.read(onboardingDraftProvider)?.toJson(),
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
        nonce: nonce,
      ));
      await ref.read(bridgeLauncherProvider)(bridgeSignInUri(
        bridgeUrl: kAuthBridgeUrl,
        provider: kind.name,
        returnUrl: Uri.base.removeFragment(),
        nonce: nonce,
        linkToken: linkToken,
      ));
      // The page is on its way out; the spinner rides along with it. If the
      // navigation somehow never happens, the record is still on disk and the
      // next boot clears it (a redirect with no response is "nothing happened").
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
  /// RedirectSignInGate). Everything a native sign-in does — slot commit,
  /// directory adopt, profile doc, the cloud-upload offer downstream of
  /// [AuthState.user] — happens here too, from the other side of a page reload.
  ///
  /// The bridge's answer arrives in the boot URL's fragment (parsed in main(),
  /// [bridgeResponseProvider]) and is believed only when it echoes the nonce
  /// the departing record wrote down. A custom token is then redeemed with
  /// [AuthService.signInWithCustomToken] — a plain API call on OUR origin, no
  /// iframes, no partitioned storage, nothing left for WebKit to lose. That
  /// determinism is the fix: the old getRedirectResult path completed
  /// sign-ins that no one ever heard about.
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
      await store.clearPendingRedirect();
      final response = ref.read(bridgeResponseProvider);
      // No response (backed out of the whole trip, or a record a crash left
      // behind), a response for some OTHER attempt (nonce mismatch), or an
      // explicit back-out on the provider's page: all "nothing happened".
      if (response == null ||
          response.nonce != record.nonce ||
          record.nonce.isEmpty ||
          response.cancelled) {
        state = state.copyWith(busy: false);
        return RedirectResume(record: record, user: null);
      }
      final failure = response.error;
      if (failure != null) {
        final message = friendlyBridgeError(failure, provider: record.provider);
        state = state.copyWith(busy: false, error: message);
        return RedirectResume(record: record, user: null, error: message);
      }
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
      // app: whatever happens to the network, the boot spinner ends.
      final user = await service
          .signInWithCustomToken(response.token!)
          .timeout(const Duration(seconds: 30));
      if (user == null) {
        if (pending != null) await sessions.abandon(pending);
        state = state.copyWith(busy: false);
        return RedirectResume(record: record, user: null);
      }
      if (record.link) {
        // Honesty checks on an upgrade: the token must resolve to the SAME
        // guest uid, now actually carrying the provider. Claiming success on
        // anything less would tell someone their guest account became a
        // Google/Apple account when it did not.
        final sameUid = record.uid == null || user.uid == record.uid;
        if (!sameUid || user.kind.name != record.provider) {
          state = state.copyWith(busy: false);
          return RedirectResume(record: record, user: null);
        }
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
    // The sign-in that just succeeded is PROOF under one-account-per-email:
    // no other signable account holds this email, so any other row claiming
    // it is an account that was deleted and re-created under the same address
    // — a row that can never be signed into again ([staleEmailTwins], #73).
    // Same broom as the venue stray path (VenueSessionNotifier._scrub), on
    // purpose: forgetCloudAccountOnDevice exists so that cleanup paths cannot
    // drift apart. A corpse's slot can still be "alive" here — Firebase
    // restores sessions from local persistence, so a deleted uid's slot
    // survives until the server refuses its token — and it goes first, while
    // everything still names it. `const []` bandIds is the venue path's
    // accepted limitation: a non-active account's cached bands cannot be
    // enumerated from here. Runs AFTER setActive so the corpse is never the
    // active entry when its row goes (withoutAccount would bounce the active
    // pointer to the local profile mid-adopt).
    final sessions = ref.read(accountSessionsProvider);
    for (final twin in staleEmailTwins(
        entry, ref.read(accountsDirectoryProvider).accounts)) {
      if (sessions.isAlive(twin.id)) await sessions.remove(twin.id);
      await forgetCloudAccountOnDevice(ref, twin.id, const []);
    }
    unawaited(_writeProfileDoc(entry));
  }

  /// Whether [kind] may be detached from the signed-in account right now.
  ///
  /// Only while ANOTHER permanent method remains. Unlinking the last one turns
  /// the account back into a guest — no way to sign in, no kill switch, no
  /// recovery — and Firebase will do it without a murmur. The refusal is ours.
  bool canUnlink(AccountKind kind) {
    final providers = state.user?.providers ?? const [];
    return providers.contains(kind) && providers.length > 1;
  }

  /// Detaches [kind]. Returns false when it was refused ([canUnlink]) or the
  /// provider call failed — the error is on [AuthState.error] either way.
  Future<bool> unlinkProvider(AccountKind kind) async {
    final user = state.user;
    if (user == null || state.busy) return false;
    if (!canUnlink(kind)) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final updated =
          await ref.read(authServiceProvider).unlinkProvider(kind);
      if (updated == null) {
        state = state.copyWith(busy: false);
        return false;
      }
      state = state.copyWith(user: updated, busy: false);
      // The switcher shows the account's method — an unlink that left the row
      // saying "Google" would be a lie about how you get back in.
      await _adopt(updated);
      return true;
    } catch (e) {
      debugPrint('unlink failed: $e');
      state = state.copyWith(busy: false, error: friendlyAuthError(e));
      return false;
    }
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

  /// Ends the ACTIVE account's Firebase session — its own instance only;
  /// every other account signed in on this device keeps its session. Lands on
  /// the local profile.
  ///
  /// Half of a sign-out, and the half that has nothing to do with this device's
  /// copy of the account: [signOutProvider] is the whole act, and every button
  /// that says "Sign out" goes through THAT. Calling this alone leaves the
  /// account's profiles cached and its row in the switcher — which is exactly
  /// the bug (#31), so don't.
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

/// SIGN OUT, as the word promises: the account's Firebase session ends AND the
/// account leaves this device — the cached copies of its profiles, their
/// keychain secrets, the memory of which profile it was on, and its row in the
/// account switcher. Every button that says "Sign out" calls this one.
///
/// The row used to survive, as a collapsed "session ended — sign in again"
/// entry. That is a fast way back in on a device you own, and on a shared one
/// it is the previous artist's email address left on screen for the next one to
/// read (#31). Nothing is lost by dropping it: everything the account owns is
/// in the cloud, signing back in brings all of it back, and the dialog says so.
/// A "stay signed in for later" affordance, if it is ever wanted, is a
/// DIFFERENT button with an honest name — never the one called Sign out.
///
/// A session that DIES on its own — an expired slot, a revoked token, a restart
/// it didn't survive — is a different event and keeps its entry: that is what
/// the switcher's "session ended — selecting it signs in again" row is for, and
/// one tap through the provider brings the account back.
///
/// A provider rather than a method on [AuthController], for a structural
/// reason: the teardown must ask the account's OWN repository which profiles
/// this device cached, and [accountDataRepositoryProvider] watches the auth
/// controller — reading it from inside the controller is a circular dependency.
final signOutProvider = Provider<Future<void> Function()>((ref) => () async {
      final uid = ref.read(authControllerProvider).user?.uid ??
          ref.read(accountsDirectoryProvider).activeAccountId;
      if (uid == kLocalAccountId) return;
      // The artist tapped "Sign out" — they are LEAVING this account, not
      // choosing where to land. The fall-back account (the local mode, or
      // whichever the directory makes active) must not have its lone profile
      // auto-opened under them: they are owed the chooser, so they can see
      // where they now are. Set BEFORE the sign-out flips the active account,
      // because that flip is what schedules the reload this guards.
      ref.read(appStateProvider.notifier).holdPickerAfterAccountExit();
      // Named while the account's repository is still standing: the sign-out
      // below swaps it for the local profile's, and the only list of the
      // profiles this device cached goes with it.
      final bandIds = [
        for (final band in ref.read(accountDataRepositoryProvider).listBands())
          band.id,
      ];
      // Drop this device's push registration while the account's session can
      // still write it (afterwards the handle is dead and the rules say no).
      // Intent goes too: signing out IS leaving this device, and a stale
      // `pushEnabled: true` would make the self-heal silently re-register
      // push the moment this account signs back in here. Best-effort with a
      // short leash: an offline sign-out must not hang on Firestore, and the
      // server prunes dead tokens on the first failed send anyway
      // (functions/src/notifications.ts).
      final db = ref.read(firestoreProvider);
      if (db != null) {
        try {
          await db
              .doc('users/$uid/devices/${ref.read(deviceIdProvider)}')
              .update({
                'pushEnabled': false,
                'fcmToken': FieldValue.delete(),
                'fcmTokenAtMs': FieldValue.delete(),
              })
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('push token cleanup on sign-out failed: $e');
        }
      }
      await ref.read(authControllerProvider.notifier).signOut();
      await forgetCloudAccountOnDevice(ref, uid, bandIds);
    });

/// Everything this device holds FOR the cloud account [uid], dropped: the
/// keychain secrets and device-local blobs of [bandIds] (the profiles it
/// cached), which profile it was on, and its entry in the account switcher.
/// Nothing in the cloud is touched — the account, its profiles, their tip pages
/// and their history are all in Firestore, and the next sign-in brings the lot
/// back.
///
/// Shared by [signOutProvider] and the venue broom (VenueSessionNotifier
/// `_scrub`) on purpose: "the artist signed out" and "the venue stint ended"
/// are the same act on this device, and the one place they disagreed is exactly
/// how sign-out came to leave an email address behind in the switcher while the
/// venue path scrubbed it. One teardown, so they cannot drift apart again.
Future<void> forgetCloudAccountOnDevice(
  Ref ref,
  String uid,
  List<String> bandIds,
) async {
  if (uid == kLocalAccountId) return; // the local profile is not an account
  final local = ref.read(localStoreProvider);
  for (final id in bandIds) {
    try {
      await ref.read(secureStoreProvider).wipeAccount(id);
    } catch (_) {
      // Locked keychain: tombstone so the boot-time retry finishes the job.
      await local.addPendingSecretWipe(id);
    }
    await local.wipeAccount(id);
  }
  await local.clearActiveCloudBand(uid);
  // The switcher must not keep listing an account the artist deliberately
  // left. This also moves the active flag off [uid] when it was still there
  // (see AccountsDirectory.withoutAccount) — the device lands on the local
  // profile, exactly as sign-out always did.
  await ref.read(accountsDirectoryProvider.notifier).remove(uid);
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

/// Reduces a bridge error code (`auth/...`, the only thing a URL fragment can
/// carry across origins) to something worth showing on a button.
///
/// [provider] is the pending record's provider name ('apple' | 'google'),
/// so a permanent refusal can name the method it refuses.
String friendlyBridgeError(String code, {String? provider}) => switch (code) {
      'auth/account-exists-with-different-credential' =>
        'That email already belongs to an account with a different sign-in '
            'method.',
      'auth/credential-already-in-use' || 'auth/email-already-in-use' =>
        'That account is already in use.',
      'auth/user-disabled' => 'This account has been disabled.',
      'auth/network-request-failed' =>
        'The network dropped mid sign-in. Try again.',
      // A provider the project has not enabled/configured. Permanent: it will
      // fail the same way on every attempt until the CONSOLE changes, so
      // "try again" — the fallback's advice — would be a lie here (#57).
      'auth/operation-not-allowed' =>
        '${_bridgeProviderLabel(provider)} sign-in is not available right '
            'now — the fix is on our side, not yours. Use another method.',
      _ => 'Sign-in failed ($code). Try again.',
    };

String _bridgeProviderLabel(String? provider) => switch (provider) {
      'apple' => 'Apple',
      'google' => 'Google',
      _ => 'That',
    };

/// Reduces provider/SDK exceptions to something worth showing on a button.
String friendlyAuthError(Object e) {
  if (e is AuthUnavailableException) return e.message;
  final text = e.toString();
  // FirebaseAuthException.toString() leads with the bracketed code — keep
  // the human sentence after it when there is one.
  final match = RegExp(r'\]\s*(.+)$').firstMatch(text);
  return match?.group(1) ?? text;
}
