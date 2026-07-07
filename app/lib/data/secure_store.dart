import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Everything secret lives in the platform keychain/keystore — each band's
/// Stripe restricted key and connected-mode relay jar secret, stored under
/// keys suffixed with the band's account id. (The stage lock uses the
/// device's own auth, so there's no app-managed secret for it.)
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

  static const kApiKeyBase = 'stripe_api_key';
  static const kRelaySecretBase = 'relay_jar_secret';

  static String _apiKey(String accountId) => '${kApiKeyBase}_$accountId';
  static String _relaySecret(String accountId) =>
      '${kRelaySecretBase}_$accountId';

  Future<String?> readApiKey(String accountId) =>
      _storage.read(key: _apiKey(accountId));

  Future<void> writeApiKey(String accountId, String key) =>
      _storage.write(key: _apiKey(accountId), value: key.trim());

  Future<void> deleteApiKey(String accountId) =>
      _storage.delete(key: _apiKey(accountId));

  Future<String?> readRelaySecret(String accountId) =>
      _storage.read(key: _relaySecret(accountId));

  Future<void> writeRelaySecret(String accountId, String secret) =>
      _storage.write(key: _relaySecret(accountId), value: secret.trim());

  Future<void> deleteRelaySecret(String accountId) =>
      _storage.delete(key: _relaySecret(accountId));

  /// Removes both of [accountId]'s secrets.
  Future<void> wipeAccount(String accountId) async {
    await deleteApiKey(accountId);
    await deleteRelaySecret(accountId);
  }

  // --- Pre-multi-band slots (unsuffixed) — the boot migration's territory ---

  Future<String?> readLegacyApiKey() => _storage.read(key: kApiKeyBase);

  Future<String?> readLegacyRelaySecret() =>
      _storage.read(key: kRelaySecretBase);

  Future<void> deleteLegacySlots() async {
    await _storage.delete(key: kApiKeyBase);
    await _storage.delete(key: kRelaySecretBase);
  }

  Future<void> wipeAll() => _storage.deleteAll();
}
