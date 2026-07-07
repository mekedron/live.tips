import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything secret lives in the platform keychain/keystore — the Stripe
/// restricted key and the connected-mode relay jar secret. (The stage lock
/// uses the device's own auth, so there's no app-managed secret for it.)
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
  static const _relaySecretKey = 'relay_jar_secret';

  Future<String?> readApiKey() => _storage.read(key: _kApiKey);

  Future<void> writeApiKey(String key) =>
      _storage.write(key: _kApiKey, value: key.trim());

  Future<void> deleteApiKey() => _storage.delete(key: _kApiKey);

  Future<String?> readRelaySecret() => _storage.read(key: _relaySecretKey);

  Future<void> writeRelaySecret(String secret) =>
      _storage.write(key: _relaySecretKey, value: secret.trim());

  Future<void> deleteRelaySecret() => _storage.delete(key: _relaySecretKey);

  Future<void> wipeAll() => _storage.deleteAll();
}
