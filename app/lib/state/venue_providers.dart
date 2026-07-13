import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/venue_boot.dart';
import '../domain/device_kind.dart';
import 'auth_providers.dart';
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

  /// Backing out of demo play — the one kind change that doesn't wipe,
  /// because demo mode never wrote anything real to protect.
  Future<void> clearDemo() async {
    if (state != DeviceKind.demo) return;
    await ref.read(localStoreProvider).clearDeviceKind();
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
    ref.read(onboardingPreludeProvider.notifier).reset();
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
    final local = ref.read(localStoreProvider);
    final secure = ref.read(secureStoreProvider);
    // Secrets first, while the cloud repository can still name the bands —
    // after the sign-out the band list is gone (same order as the
    // revocation path in DeviceSessionGuard). Only when the repository IS
    // the account's: if it has already fallen back to the local profile,
    // its bands are not ours to wipe.
    final bandIds =
        ref.read(accountsDirectoryProvider).activeAccountId == uid
            ? ref
                .read(accountDataRepositoryProvider)
                .listBands()
                .map((b) => b.id)
                .toList()
            : const <String>[];
    for (final id in bandIds) {
      try {
        await secure.wipeAccount(id);
      } catch (_) {
        // Locked keychain: tombstone so the boot-time retry finishes the job.
        await local.addPendingSecretWipe(id);
      }
      await local.wipeAccount(id);
    }
    await local.clearActiveCloudBand(uid);
    final sessions = ref.read(accountSessionsProvider);
    if (ref.read(accountsDirectoryProvider).activeAccountId == uid) {
      await ref.read(authControllerProvider.notifier).signOut();
    } else if (sessions.isAlive(uid)) {
      await sessions.remove(uid);
    }
    await ref.read(accountsDirectoryProvider.notifier).remove(uid);
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
