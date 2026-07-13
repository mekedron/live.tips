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
  bool _revoking = false;
  String? _registeredUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Already signed in at launch — the doc still needs its lastSeen bump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authControllerProvider).user?.uid;
      if (uid != null) unawaited(_register(uid));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid != null) unawaited(ref.read(deviceRegistryProvider).touch(uid));
  }

  Future<void> _register(String uid) async {
    if (_registeredUid == uid) return;
    _registeredUid = uid;
    await ref.read(deviceRegistryProvider).registerThisDevice(uid);
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
