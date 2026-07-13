import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth_domain.dart';
import 'auth_service.dart' show AuthUnavailableException;

/// Thrown by [AccountSessions.begin] at the simultaneous-account cap. The
/// message rides [AuthUnavailableException]'s existing path onto the sign-in
/// button, same as every other "this cannot proceed" reason.
class AccountLimitException extends AuthUnavailableException {
  AccountLimitException(int max)
      : super('This device already has $max accounts signed in. '
            'Sign out of one to add another.');
}

/// The Firebase handles of one app instance — a seam so tests can hand in
/// mocks where a real [FirebaseApp] cannot exist.
class SessionHandles {
  const SessionHandles({
    required this.auth,
    this.firestore,
    this.functionsFor,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore? firestore;
  final FirebaseFunctions Function(String region)? functionsFor;
}

/// One signed-in cloud account's own Firebase stack, alive and persisted
/// independently of every other account on this device.
class AccountSession {
  const AccountSession({
    required this.uid,
    required this.appName,
    required this.handles,
  });

  final String uid;

  /// The [FirebaseApp] name this session lives in — a slot name, not the
  /// uid: the app must exist before a sign-in reveals whose it is.
  final String appName;

  final SessionHandles handles;

  FirebaseAuth get auth => handles.auth;
  FirebaseFirestore? get firestore => handles.firestore;
  FirebaseFunctions? functions(String region) =>
      handles.functionsFor?.call(region);
}

/// A slot mid-sign-in: an app exists, nobody is signed into it yet.
class PendingSession {
  const PendingSession({required this.appName, required this.handles});

  final String appName;
  final SessionHandles handles;

  FirebaseAuth get auth => handles.auth;
}

/// N cloud accounts signed in at once, each in its own [FirebaseApp].
///
/// Firebase persists one auth session per app instance — so "switching
/// accounts" used to mean signing out and back in, and a shared tablet meant
/// a Google popup every time. Instead every account gets its own app
/// (`acct_slot_<n>`), its own persisted session, its own Firestore; switching
/// is a directory flip and every session stays alive.
///
/// Two things are deliberately OUTSIDE this registry:
///  - the DEFAULT app, which stays the relay's transport home (its anonymous
///    uid is a credential, not an account — see RelayAuth) and, on installs
///    that signed in before slots existed, hosts that one legacy session
///    ([adoptDefault]);
///  - platforms without Firebase, where [available] is false and every
///    mutator throws [AuthUnavailableException] — the app runs local mode
///    exactly as before.
class AccountSessions {
  AccountSessions({
    FirebaseOptions? options,
    SessionHandles? defaultHandles,
    required Map<String, String> Function() readSlots,
    required Future<void> Function(Map<String, String>) saveSlots,
    this.maxAccounts = 5,
    Future<SessionHandles> Function(String appName)? openApp,
    Future<void> Function(String appName)? closeApp,
  })  : _options = options,
        _defaultHandles = defaultHandles,
        _readSlots = readSlots,
        _saveSlots = saveSlots,
        _openApp = openApp,
        _closeApp = closeApp;

  /// The no-Firebase degenerate: nothing restores, everything refuses.
  AccountSessions.unavailable()
      : this(readSlots: () => const {}, saveSlots: (_) async {});

  final FirebaseOptions? _options;
  final SessionHandles? _defaultHandles;
  final Map<String, String> Function() _readSlots;
  final Future<void> Function(Map<String, String>) _saveSlots;
  final Future<SessionHandles> Function(String appName)? _openApp;
  final Future<void> Function(String appName)? _closeApp;

  /// The simultaneous-account ceiling. Five is generous for a shared tablet
  /// and small enough that a forgotten session is still a short list to read.
  final int maxAccounts;

  /// Set on venue devices: a shared tablet must not accumulate an offline
  /// Firestore cache of every artist who ever signed in — the in-memory
  /// cache serves the running session, and nothing lands on disk.
  bool disableFirestorePersistence = false;

  final Map<String, AccountSession> _sessions = {};
  final _changes = StreamController<void>.broadcast();

  /// Fires on every add/remove — the providers deriving the active account's
  /// handles listen so the UI re-resolves.
  Stream<void> get changes => _changes.stream;

  bool get available => _defaultHandles != null || _openApp != null;

  FirebaseAuth? get defaultAuth => _defaultHandles?.auth;
  FirebaseFirestore? get defaultFirestore => _defaultHandles?.firestore;
  FirebaseFunctions? defaultFunctions(String region) =>
      _defaultHandles?.functionsFor?.call(region);

  AccountSession? sessionFor(String uid) => _sessions[uid];
  bool isAlive(String uid) => _sessions.containsKey(uid);
  List<String> get liveUids => List.unmodifiable(_sessions.keys);

  /// Which [FirebaseApp] holds [uid]'s session, if any — what a redirect
  /// sign-in records so the return leg can find its way back to the same one.
  String? appNameFor(String uid) => _sessions[uid]?.appName;

  static const _slotPrefix = 'acct_slot_';
  static const defaultSlot = '[DEFAULT]';
  static const _defaultSlot = defaultSlot;

  Future<SessionHandles> _open(String appName) async {
    final custom = _openApp;
    if (custom != null) return custom(appName);
    final options = _options;
    if (options == null) {
      throw const AuthUnavailableException(
          'Cloud accounts are not available on this platform.');
    }
    if (appName == _defaultSlot) {
      final handles = _defaultHandles;
      if (handles != null) return handles;
    }
    FirebaseApp app;
    try {
      app = Firebase.app(appName);
    } catch (_) {
      app = await Firebase.initializeApp(name: appName, options: options);
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    applyCustomAuthDomain(auth);
    final db = FirebaseFirestore.instanceFor(app: app);
    if (disableFirestorePersistence) {
      try {
        db.settings = const Settings(persistenceEnabled: false);
      } catch (e) {
        // Already touched (hot restart) — the cache setting is fixed for
        // this run; the venue wipe still scrubs everything that matters.
        debugPrint('firestore persistence setting failed: $e');
      }
    }
    return SessionHandles(
      auth: auth,
      firestore: db,
      functionsFor: (region) =>
          FirebaseFunctions.instanceFor(app: app, region: region),
    );
  }

  Future<void> _close(String appName) async {
    // The default app hosts the relay transport and must outlive any one
    // account; a legacy session there is dropped by sign-out alone.
    if (appName == _defaultSlot) return;
    final custom = _closeApp;
    if (custom != null) return custom(appName);
    try {
      await Firebase.app(appName).delete();
    } catch (e) {
      debugPrint('app close failed: $e');
    }
  }

  /// Revives every persisted slot. A slot whose auth restored a different
  /// user (or none — token revoked, storage cleared) is scrubbed and dropped:
  /// the directory entry survives so the switcher can say "session gone",
  /// but there is no session to serve.
  Future<void> restore() async {
    if (!available) return;
    final slots = Map<String, String>.from(_readSlots());
    var changed = false;
    for (final entry in slots.entries.toList()) {
      try {
        final handles = await _open(entry.value);
        final user = await handles.auth.authStateChanges().first;
        if (user?.uid == entry.key) {
          _sessions[entry.key] = AccountSession(
              uid: entry.key, appName: entry.value, handles: handles);
        } else {
          if (user != null) await handles.auth.signOut();
          await _close(entry.value);
          slots.remove(entry.key);
          changed = true;
        }
      } catch (e) {
        debugPrint('session restore failed for ${entry.key}: $e');
        slots.remove(entry.key);
        changed = true;
      }
    }
    if (changed) await _saveSlots(slots);
  }

  /// Adopts the DEFAULT app's already-signed-in user as a session — the
  /// migration path for installs from before per-account apps. Their session
  /// cannot move to a slot without re-authenticating, so the default app IS
  /// its slot until that account signs out.
  Future<void> adoptDefault(String uid) async {
    final handles = _defaultHandles;
    if (handles == null || _sessions.containsKey(uid)) return;
    _sessions[uid] =
        AccountSession(uid: uid, appName: _defaultSlot, handles: handles);
    final slots = Map<String, String>.from(_readSlots());
    if (slots[uid] != _defaultSlot) {
      slots[uid] = _defaultSlot;
      await _saveSlots(slots);
    }
    _changes.add(null);
  }

  /// Opens a fresh slot for a sign-in. Throws [AccountLimitException] at the
  /// cap and [AuthUnavailableException] where Firebase isn't.
  Future<PendingSession> begin() async {
    if (!available) {
      throw const AuthUnavailableException(
          'Cloud accounts are not available on this platform.');
    }
    if (_sessions.length >= maxAccounts) {
      throw AccountLimitException(maxAccounts);
    }
    final used = _sessions.values.map((s) => s.appName).toSet();
    var k = 0;
    while (used.contains('$_slotPrefix$k')) {
      k++;
    }
    final appName = '$_slotPrefix$k';
    final handles = await _open(appName);
    // A recycled slot may still hold the session of an account that was
    // restored dead (or a crashed half sign-in) — scrub before reuse.
    if (handles.auth.currentUser != null) {
      await handles.auth.signOut();
    }
    return PendingSession(appName: appName, handles: handles);
  }

  /// Re-opens the slot a WEB redirect sign-in was started on, so its result
  /// can be claimed after the page reload destroyed the running app (see
  /// PendingRedirect). The slot was never committed — no uid was known yet —
  /// so [restore] does not revive it; only the app name, written before the
  /// redirect, can find it again. The web SDK keys its pending-redirect state
  /// by app, which is why it has to be THIS app and not a fresh one.
  Future<PendingSession?> reopen(String appName) async {
    if (!available) return null;
    final handles = await _open(appName);
    return PendingSession(appName: appName, handles: handles);
  }

  /// Records a successful sign-in on [pending] as [uid]'s session. Signing
  /// into an account that already HAS a live slot keeps the existing one:
  /// two apps holding the same uid would fight over which is "the" session.
  Future<AccountSession> commit(PendingSession pending, String uid) async {
    final existing = _sessions[uid];
    if (existing != null) {
      await abandon(pending);
      return existing;
    }
    final session = AccountSession(
        uid: uid, appName: pending.appName, handles: pending.handles);
    _sessions[uid] = session;
    final slots = Map<String, String>.from(_readSlots());
    slots[uid] = pending.appName;
    await _saveSlots(slots);
    _changes.add(null);
    return session;
  }

  /// A cancelled or failed sign-in: the slot goes back to the shelf.
  Future<void> abandon(PendingSession pending) async {
    try {
      if (pending.auth.currentUser != null) await pending.auth.signOut();
    } catch (_) {}
    await _close(pending.appName);
  }

  /// Signs [uid] out of ITS instance and forgets the slot. Every other
  /// account's session is untouched — that is the whole point of the slots.
  Future<void> remove(String uid) async {
    final session = _sessions.remove(uid);
    if (session == null) return;
    try {
      await session.auth.signOut();
    } catch (e) {
      debugPrint('slot sign-out failed: $e');
    }
    await _close(session.appName);
    final slots = Map<String, String>.from(_readSlots());
    slots.remove(uid);
    await _saveSlots(slots);
    _changes.add(null);
  }

  /// The device-wipe path (changing the device kind): every account out.
  Future<void> removeAll() async {
    for (final uid in liveUids) {
      await remove(uid);
    }
  }
}
