import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../data/venue_boot.dart';
import '../domain/device_kind.dart';
import 'auth_providers.dart';
import 'live_session_controller.dart';
import 'onboarding_draft.dart';
import 'providers.dart';

/// How long an artist's account may live on a shared device. Fixed at
/// sign-in, persisted immediately, honoured across restarts — the tablet can
/// crash, reboot or lose power and the deadline stands.
const kVenueSessionCeiling = Duration(hours: 12);

/// Injectable clock so the 12-hour ceiling is testable without waiting.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// What this install is (performer / venue / demo), or null before the
/// onboarding choice. Changing it later goes through [wipeDevice] — never a
/// plain write: data written under one trust model must not leak into the
/// next.
class DeviceKindNotifier extends Notifier<DeviceKind?> {
  @override
  DeviceKind? build() => ref.read(localStoreProvider).readDeviceKind();

  /// The onboarding choice (a fresh device, nothing to wipe). Entering venue
  /// mode attaches the at-rest cipher and turns off Firestore's disk cache
  /// before any account data can land; leaving it detaches them. Throws —
  /// and changes nothing — when the cipher can't attach (see [_applyKind]).
  Future<void> choose(DeviceKind kind) async {
    await _applyKind(kind);
    state = kind;
  }

  /// Backing out of demo play — the one kind change that doesn't wipe the
  /// DEVICE, because demo never held anything real to protect. It does wipe
  /// DEMO: a demo "Go live" persists a goal, a QR mode, a poster, a crash
  /// snapshot and an archived session, all of it in demo's own namespace
  /// ([LocalStore.kDemoAccountId], #52), and a device that only tried the
  /// demo must be left exactly as it was found.
  ///
  /// The wipe goes FIRST, and the kind is still cleared with an await before
  /// the caller drops the in-memory flag — RootGate re-enters demo on "the
  /// install says demo, the flag is off", so that order is #45's fix and it
  /// stays.
  Future<void> clearDemo() async {
    if (state != DeviceKind.demo) return;
    final local = ref.read(localStoreProvider);
    await local.wipeAccount(LocalStore.kDemoAccountId);
    await local.clearDeviceKind();
    state = null;
  }

  Future<void> _applyKind(DeviceKind kind) async {
    final local = ref.read(localStoreProvider);
    if (kind == DeviceKind.venue) {
      final block =
          await attachVenueCipher(local, ref.read(secureStoreProvider));
      if (block != null) {
        // No cipher, no venue mode: proceeding would put a shared tablet's
        // data on disk in plaintext, and the next boot would fail closed on
        // it anyway (see attachVenueCipher). The kind stays unchosen — the
        // caller tells the user to unlock the device and try again.
        throw StateError('venue cipher unavailable: ${block.name}');
      }
    } else {
      local.cipher = null;
    }
    ref.read(accountSessionsProvider).disableFirestorePersistence =
        kind == DeviceKind.venue;
    await local.saveDeviceKind(kind);
  }

  /// The settings-row kind change: EVERYTHING goes. Every account signed
  /// out, every local profile and cached secret wiped, the kind itself
  /// cleared — the device returns to onboarding and chooses again.
  Future<void> wipeDevice() async {
    final local = ref.read(localStoreProvider);
    final secure = ref.read(secureStoreProvider);
    await ref.read(accountSessionsProvider).removeAll();
    try {
      await secure.wipeAll();
    } catch (e) {
      // A locked keychain leaves secrets behind; prefs (below) still go, so
      // nothing left can NAME those entries. Not silent by choice: the wipe
      // is a promise, and a broken half of it should at least be in the log.
      debugPrint('keychain wipe failed: $e');
    }
    await local.wipeAll();
    local.cipher = null;
    ref.read(accountSessionsProvider).disableFirestorePersistence = false;
    state = null;
    // Every notifier that mirrors prefs rebuilds on its now-empty store.
    ref.invalidate(accountsDirectoryProvider);
    ref.invalidate(venueSessionProvider);
    ref.read(onboardingDraftProvider.notifier).clear();
    ref.invalidate(appStateProvider);
  }
}

final deviceKindProvider =
    NotifierProvider<DeviceKindNotifier, DeviceKind?>(DeviceKindNotifier.new);

/// The venue device's current artist stint, or null (sign-in screen).
///
/// Owns the 12-hour ceiling: [start] fixes and persists the deadline, a
/// timer (re-armed at boot from the persisted record, so restarts can only
/// shorten the wait) fires [endSession] — which is also what the banner's
/// "End session" and the identity screen's "This isn't me" run.
class VenueSessionNotifier extends Notifier<VenueSession?> {
  Timer? _timer;

  @override
  VenueSession? build() {
    ref.onDispose(() => _timer?.cancel());
    final session = ref.read(localStoreProvider).readVenueSession();
    if (session != null) _arm(session);
    return session;
  }

  DateTime get _now => ref.read(clockProvider)();

  void _arm(VenueSession session) {
    _timer?.cancel();
    final left = DateTime.fromMillisecondsSinceEpoch(session.expiresAtMs)
        .difference(_now);
    // An already-expired record still goes through the timer (duration
    // clamped to zero) rather than a straight call: build() must finish
    // before endSession may touch state.
    _timer = Timer(left.isNegative ? Duration.zero : left,
        () => unawaited(endSession()));
  }

  /// A fresh approval landed: this account now owns the tablet for at most
  /// [kVenueSessionCeiling]. Persisted before it is announced.
  Future<void> start(String uid) async {
    _timer?.cancel();
    final now = _now.millisecondsSinceEpoch;
    final session = VenueSession(
      uid: uid,
      startedAtMs: now,
      expiresAtMs: now + kVenueSessionCeiling.inMilliseconds,
    );
    await ref.read(localStoreProvider).saveVenueSession(session);
    state = session;
    _arm(session);
  }

  /// The artist looked at "signed in as …" and said "that's me".
  Future<void> confirmIdentity() async {
    final session = state;
    if (session == null) return;
    final confirmed = session.copyWith(identityConfirmed: true);
    await ref.read(localStoreProvider).saveVenueSession(confirmed);
    state = confirmed;
  }

  /// Ends the stint — expiry, "End session", "This isn't me", all of them.
  /// Scrubs the account's cached secrets and device-local band data, signs
  /// the account out of this device, and drops its directory row: a public
  /// device keeps no list of past artists.
  Future<void> endSession() async {
    final session = state;
    if (session == null) return;
    _timer?.cancel();
    await _scrub(session.uid);
    await ref.read(localStoreProvider).clearVenueSession();
    state = null;
  }

  /// An account got onto this venue device AROUND the sign-in ceremony (a
  /// legacy session, some future side door) — no venue record, no ceiling,
  /// no banner. Same broom: out it goes, with its cached secrets.
  Future<void> evictStray(String uid) => _scrub(uid);

  Future<void> _scrub(String uid) async {
    // The live session dies FIRST, while the coordinator still has the
    // account's repository and key to archive with. Signing out around a
    // running session left it polling Stripe invisibly behind the next
    // artist's sign-in screen — the exact local state this broom exists to
    // clear. Only when the account IS the active profile: a stray uid's
    // session was never started here.
    if (ref.read(accountsDirectoryProvider).activeAccountId == uid) {
      try {
        // DURABLE: the sign-out below deletes the account's Firebase app, and
        // a venue tablet runs with persistence off — an archive write that is
        // merely queued here dies in RAM with the app instance, and the
        // artist's night reads as 0 tips, €0 forever. The stop waits for it.
        await ref.read(liveSessionProvider.notifier).stop(durable: true);
      } catch (e) {
        // The archive write failed (offline, a dead handle) — the transports
        // are already down, and the wipe below must still happen: a public
        // device may not keep an artist's set. What survives of the night is
        // the tips already in `sessions/{id}/tips`, which the history rebuilds
        // the set from on the artist's own device.
        debugPrint('venue scrub: session stop failed: $e');
      }
    }
    // The broom IS a sign-out now: cached secrets, device-local band data, the
    // band pointer, the directory row — [signOutProvider] drops exactly the
    // list this method used to keep in its own hands (#31), in the order it
    // always needed (the secrets go while the cloud repository can still name
    // the bands; the session goes after). Two copies of that list is how the
    // two paths drifted apart in the first place.
    final sessions = ref.read(accountSessionsProvider);
    if (ref.read(accountsDirectoryProvider).activeAccountId == uid) {
      await ref.read(signOutProvider)();
    }
    // A STRAY uid was never the active profile, so nothing here can name its
    // bands and no sign-out is owed it — the slot goes, and the broom sweeps
    // what is left. Both lines are no-ops after a sign-out that ran, and a
    // public device may not be left holding an account either way (sign-out
    // stands down while another auth call is in flight).
    if (sessions.isAlive(uid)) await sessions.remove(uid);
    await forgetCloudAccountOnDevice(ref, uid, const []);
  }
}

final venueSessionProvider =
    NotifierProvider<VenueSessionNotifier, VenueSession?>(
        VenueSessionNotifier.new);

/// Whether venue-mode chrome (the public-device banner, the re-approval
/// gates) applies right now: a venue install with a confirmed artist on it.
final venueModeActiveProvider = Provider<bool>((ref) =>
    ref.watch(deviceKindProvider) == DeviceKind.venue &&
    ref.watch(venueSessionProvider) != null);

/// True while the venue sign-in ceremony is mid-flight: the token signed the
/// account in (directory flipped) but the session record isn't written yet.
/// The gate's stray-account eviction must not fire in that gap — it would
/// throw out the artist who is signing in right now.
class VenueSignInPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool pending) => state = pending;
}

final venueSignInPendingProvider =
    NotifierProvider<VenueSignInPendingNotifier, bool>(
        VenueSignInPendingNotifier.new);
