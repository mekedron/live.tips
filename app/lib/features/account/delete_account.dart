import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/auth_providers.dart';
import '../../state/providers.dart';

/// Deleting the cloud account, end to end.
///
/// The SERVER erases it (firebase/functions/src/account.ts): every band, the
/// relay jars behind the public tip pages, the sealed Stripe key AND the
/// webhook endpoint on the artist's own Stripe account, the devices, the link
/// codes, the watermark — and the Firebase Auth user itself, last of all. Only
/// once that callable ANSWERS does this device let go of its copy: cached
/// secrets, band data, the session slot, the directory row.
///
/// Server first, deliberately. A local wipe that ran ahead of a refused call
/// would leave the artist holding an account they can no longer see — and
/// therefore no longer delete.
///
/// A function rather than a method on [AuthController], for the same reason
/// runCloudUpload is one: the scrub needs the ACTIVE PROFILE'S repository to
/// name the bands, and that repository is built downstream of the auth state.
/// A controller reaching back down for it is a circular dependency Riverpod
/// refuses to build.
///
/// Returns the webhook endpoints Stripe would not let the server remove
/// (ordinarily none) — the one residue we cannot clear from here. Throws
/// [AccountCallError] when the server refused: nothing local is touched,
/// because the account still exists.
Future<List<String>> runAccountDelete(WidgetRef ref) async {
  final user = ref.read(authControllerProvider).user;
  if (user == null) return const [];
  final uid = user.uid;
  final stranded = await ref.read(accountServiceProvider).deleteAccount();

  // The same broom, in the same order, as the venue scrub: secrets first,
  // while the repository can still NAME the bands (after the sign-out the band
  // list is gone), then the prefs, then the session, then the directory row.
  final local = ref.read(localStoreProvider);
  final secure = ref.read(secureStoreProvider);
  final bandIds = ref.read(accountsDirectoryProvider).activeAccountId == uid
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
  // The account is gone; the device falls back to another it did not choose.
  // Land on the chooser, not auto-opened into the fallback's lone profile —
  // the same rule sign-out obeys (holdPickerAfterAccountExit). Set before the
  // sign-out flips the active account, which is what schedules that reload.
  ref.read(appStateProvider.notifier).holdPickerAfterAccountExit();
  await ref.read(authControllerProvider.notifier).signOut();
  // No collapsed switcher row this time: an ordinary sign-out keeps the entry
  // so you can come back, and there is nothing left to come back to.
  await ref.read(accountsDirectoryProvider.notifier).remove(uid);
  return stranded;
}
