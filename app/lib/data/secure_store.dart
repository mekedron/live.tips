import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything secret lives in the platform keychain/keystore:
/// the Stripe restricted key and the (salted, hashed) stage-lock PIN.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // The data-protection keychain needs a keychain-access-groups
              // entitlement, which requires a real signing team — with the
              // local ad-hoc signature the app is killed at launch. The login
              // keychain works for everyone building from source.
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  final FlutterSecureStorage _storage;

  static const _kApiKey = 'stripe_api_key';
  static const _kPinHash = 'lock_pin_hash';
  static const _kPinSalt = 'lock_pin_salt';

  Future<String?> readApiKey() => _storage.read(key: _kApiKey);

  Future<void> writeApiKey(String key) =>
      _storage.write(key: _kApiKey, value: key.trim());

  Future<void> deleteApiKey() => _storage.delete(key: _kApiKey);

  Future<bool> hasPin() async => await _storage.read(key: _kPinHash) != null;

  Future<void> setPin(String pin) async {
    final saltBytes =
        List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final salt = base64Encode(saltBytes);
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: _hash(salt, pin));
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final stored = await _storage.read(key: _kPinHash);
    if (salt == null || stored == null) return false;
    return _hash(salt, pin) == stored;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
  }

  Future<void> wipeAll() => _storage.deleteAll();

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt|$pin')).toString();
}
