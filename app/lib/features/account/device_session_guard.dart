import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/auth_providers.dart';
import '../../state/device_providers.dart';
import '../../state/providers.dart';

/// Invisible root widget that keeps this device's entry in the account's
/// device list honest, and honours a revocation of it.
///
///  - a sign-in (or a cold start already signed in) registers this device;
///  - every resume bumps its `lastSeenAtMs`, so "last seen" means it;
///  - when the account revokes THIS device, the app signs itself out and
///    scrubs the account's cached band secrets from the keychain.
///
/// The revocation half is cooperative and honest about it: a flag in Firestore
/// that this client chooses to obey. It cannot evict a hostile or offline
/// client — "Sign out everywhere else" (revokeAllOtherDevices, which kills the
/// refresh tokens server-side) is the real thing. What this DOES buy is that
/// the common case — an old phone in a drawer, a borrowed laptop — stops
/// holding Stripe keys and relay secrets the moment the owner says so.
class DeviceSessionGuard extends ConsumerStatefulWidget {
  const DeviceSessionGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeviceSessionGuard> createState() => _DeviceSessionGuardState();
}

class _DeviceSessionGuardState extends ConsumerState<DeviceSessionGuard>
    with WidgetsBindingObserver {
  /// How often the heartbeat freshens `lastSeenAtMs` (and retries a
  /// registration that hasn't landed). Same idea as the session leader's
  /// lease heartbeat, at device-list granularity: "last seen" rounds to
  /// minutes, so anything finer would be Firestore writes for nobody.
  static const _heartbeatEvery = Duration(minutes: 5);

  bool _revoking = false;
  String? _registeredUid;
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Already signed in at launch — the doc still needs its lastSeen bump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authControllerProvider).user?.uid;
      if (uid != null) unawaited(_register(uid));
    });
    // The lifecycle observer alone is not a heartbeat: an always-visible
    // web tab never emits `resumed`, so its "last seen" froze at page load.
    _heartbeat = Timer.periodic(_heartbeatEvery, (_) => _onHeartbeat());
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _onHeartbeat();
  }

  /// Freshens the device doc — or finishes a registration that hasn't
  /// succeeded yet ([DeviceRegistry.touch] re-registers a missing doc).
  void _onHeartbeat() {
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null) return;
    if (_registeredUid == uid) {
      unawaited(ref.read(deviceRegistryProvider).touch(uid));
    } else {
      unawaited(_register(uid));
    }
  }

  /// Memoizes the uid on SUCCESS only. Registration used to stamp
  /// `_registeredUid` before the await — one permission-denied at boot (the
  /// account slot's session not restored yet, so the write went through the
  /// unauthenticated default handle) and it never retried for the whole app
  /// run: no device doc, an orphan Security row, no "This device" pill.
  Future<void> _register(String uid) async {
    if (_registeredUid == uid) return;
    final ok = await ref.read(deviceRegistryProvider).registerThisDevice(uid);
    if (!mounted || !ok) return;
    // Only if this uid is still the signed-in one — a sign-out or account
    // switch mid-await must not mark the NEW state as registered.
    if (ref.read(authControllerProvider).user?.uid == uid) {
      _registeredUid = uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((s) => s.user?.uid),
        (previous, uid) {
      if (uid == null) {
        _registeredUid = null;
        return;
      }
      unawaited(_register(uid));
    });
    // Registration is driven by "there is an authenticated handle for this
    // uid", not by "the app booted": the registry rebuilds whenever the
    // Firestore handle resolves differently (an account slot's session
    // restoring after boot is exactly that moment), and a registration that
    // failed on the old handle must retry on the new one.
    ref.listen(deviceRegistryProvider, (previous, next) {
      _registeredUid = null;
      final uid = ref.read(authControllerProvider).user?.uid;
      if (uid != null) unawaited(_register(uid));
    });
    ref.listen(ownDeviceRevokedProvider, (previous, next) {
      if (next.value == true) unawaited(_onRevoked());
    });
    return widget.child;
  }

  /// This device was revoked: drop the account's secrets from THIS device's
  /// keychain, then sign out. Secrets first — after the sign-out the
  /// repository flips back to local and the cloud band list is gone, taking
  /// with it the ids whose keychain entries need clearing.
  Future<void> _onRevoked() async {
    if (_revoking) return;
    _revoking = true;
    try {
      final bandIds = ref
          .read(accountDataRepositoryProvider)
          .listBands()
          .map((b) => b.id)
          .toList();
      final secure = ref.read(secureStoreProvider);
      for (final id in bandIds) {
        try {
          await secure.wipeAccount(id);
        } catch (_) {
          // A locked keychain leaves that band's secrets behind — the sign-out
          // still happens, which is the part the user asked for.
        }
      }
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.s.t('settings.security.revoked_notice'))),
      );
    } finally {
      _revoking = false;
    }
  }
}
