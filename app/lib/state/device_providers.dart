import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/deep_links.dart';
import '../data/firebase/device_registry.dart';
import '../data/firebase/link_codes.dart';
import '../domain/app_account.dart';
import 'auth_providers.dart';
import 'providers.dart';

/// Everything the Security section and the QR add-device flow hang off.
/// Kept out of providers.dart so the device surface can grow (and be
/// overridden in tests) without touching the app's core wiring.

/// The callables' home. Null wherever Firebase isn't (Windows/Linux, a failed
/// boot, tests) — [LinkCodeService] then refuses every call politely instead
/// of the app crashing on a null instance.
///
/// Resolves against the ACTIVE account's app so an authenticated callable
/// (createLinkCode, confirmLinkCode) speaks as that account; the local
/// profile gets the default app — enough for the unauthenticated calls a
/// signed-out venue tablet makes (redeemLinkCode, collectLinkToken).
final functionsProvider = Provider<FirebaseFunctions?>((ref) {
  const region = 'europe-west1';
  // firebaseAuthProvider is still the "did Firebase boot?" signal.
  if (ref.watch(firebaseAuthProvider) == null) return null;
  final sessions = ref.watch(accountSessionsProvider);
  ref.watch(accountSessionsChangesProvider);
  final active = ref
      .watch(accountsDirectoryProvider.select((d) => d.activeAccountId));
  if (active != kLocalAccountId) {
    final functions = sessions.sessionFor(active)?.functions(region);
    if (functions != null) return functions;
  }
  return sessions.defaultFunctions(region) ??
      FirebaseFunctions.instanceFor(region: region);
});

final deviceRegistryProvider = Provider<DeviceRegistry>((ref) => DeviceRegistry(
      db: ref.watch(firestoreProvider),
      deviceId: ref.watch(deviceIdProvider),
      // Through the provider, not the bare function: tests override it so
      // registration doesn't hang on the device-info platform channel.
      describe: ref.watch(describeDeviceProvider),
    ));

/// How this device names itself when asking to be let into an account —
/// a provider so tests don't hang on the device-info platform channel.
final describeDeviceProvider = Provider<Future<DeviceDescription> Function()>(
    (ref) => describeThisDevice);

final linkCodeServiceProvider = Provider<LinkCodeService>(
  (ref) => LinkCodeService(
    functions: ref.watch(functionsProvider),
    db: ref.watch(firestoreProvider),
  ),
);

/// Every device signed into the CURRENT cloud account, this one first.
/// Empty in local mode / signed out — there is no device list to speak of.
final devicesProvider = StreamProvider<List<DeviceInfo>>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(const <DeviceInfo>[]);
  return ref.watch(deviceRegistryProvider).watchDevices(uid);
});

/// True once THIS device's own doc says revoked — the cooperative signal
/// [DeviceSessionGuard] acts on. Always false when signed out.
final ownDeviceRevokedProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(authControllerProvider.select((s) => s.user?.uid));
  if (uid == null) return Stream.value(false);
  final registry = ref.watch(deviceRegistryProvider);
  return registry.watchOwnRevocation(uid, registry.deviceId);
});

/// The URL this app was launched with, captured at the very top of main()
/// (see [DeepLinks.bootUrl]) — null everywhere it wasn't, tests included.
final bootLinkUrlProvider = Provider<String?>((ref) => null);

/// Link codes arriving from a universal link (`https://tip.live.tips/link#c=…`)
/// — the cold-start URL and every one handed to a running app. Silent on
/// platforms without cloud accounts: there is nothing to link there.
final deepLinkCodesProvider = StreamProvider<String>((ref) {
  // No Firebase, no sign-in to redeem into.
  if (ref.watch(firebaseAuthProvider) == null) return const Stream<String>.empty();
  return DeepLinks(bootUrl: ref.watch(bootLinkUrlProvider)).codes();
});
