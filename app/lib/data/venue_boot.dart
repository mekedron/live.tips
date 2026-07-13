import 'package:flutter/foundation.dart';

import 'local_cipher.dart';
import 'local_store.dart';
import 'secure_store.dart';

/// Why a venue boot refused to continue (see [attachVenueCipher]).
enum VenueBootBlock {
  /// The keychain would not answer (locked device, denied prompt, a
  /// first-unlock race). Transient: unlocking or restarting the device and
  /// trying again resolves it.
  keychainUnavailable,

  /// The keychain answered but the root key is GONE while encrypted
  /// envelopes still sit in prefs — exactly what a backup restored onto
  /// different hardware looks like. Not transient and not a first run: the
  /// key never leaves the original device's keystore, so that data cannot
  /// be read here, only deliberately erased.
  rootKeyMissing,
}

/// Attaches the venue at-rest cipher to [local], or says why boot must STOP.
///
/// A cipher failure is a stop, never a run-degraded condition. A boot that
/// carried on with a null cipher read every encrypted value as "nothing
/// stored" while writes went out in plaintext over the envelopes: the device
/// id re-minted (orphaning the device-registry doc, the session leases and
/// the revocation watch), the accounts registry reseeded over the encrypted
/// one, the venue ceiling's timer never re-armed, and persisted auth
/// sessions were neither revived nor signed out. Worse, minting a fresh root
/// key just because the keychain entry was MISSING turned a backup restore
/// into silent, total data loss — every existing envelope fails its MAC
/// under the new key.
///
/// So: a throwing keychain blocks the boot outright; a missing key while
/// envelopes exist on disk is a restore ([VenueBootBlock.rootKeyMissing])
/// and blocks too. Only a genuinely fresh venue install — no key AND no
/// envelopes — mints a key, and the cipher attaches only after that key is
/// safely in the keychain, so a failed write can never strand envelopes
/// whose key existed nowhere but memory.
Future<VenueBootBlock?> attachVenueCipher(
    LocalStore local, SecureStore secure) async {
  String? cipherKey;
  try {
    cipherKey = await secure.readLocalCipherKey();
  } catch (e) {
    debugPrint('venue cipher unavailable: $e');
    return VenueBootBlock.keychainUnavailable;
  }
  if (cipherKey == null) {
    if (local.hasEncryptedValues()) return VenueBootBlock.rootKeyMissing;
    final minted = LocalCipher.newRootKey();
    try {
      await secure.writeLocalCipherKey(minted);
    } catch (e) {
      debugPrint('venue cipher key write failed: $e');
      return VenueBootBlock.keychainUnavailable;
    }
    cipherKey = minted;
  }
  local.cipher = LocalCipher(cipherKey);
  return null;
}
