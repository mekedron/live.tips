import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/relay/relay_auth.dart';
import 'package:live_tips/data/relay/relay_client.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localization wiring for widget tests: the same delegates the real
/// MaterialApp uses, so `context.s` resolves instead of throwing. Pump a
/// MaterialApp with these and `locale: const Locale('en')`. English resolves
/// synchronously (see AppLocalizations), so no extra pump is needed.
const List<LocalizationsDelegate<Object?>> kTestL10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// In-memory [SecureStore] — the keychain plugin is a silent no-op in tests,
/// so anything that must READ a secret back (migration, band switching)
/// needs this instead.
class FakeSecureStore extends SecureStore {
  FakeSecureStore([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;

  /// Every read/write throws when set — the keychain's transient-failure
  /// mode (locked device, denied prompt).
  bool failing = false;

  void _check() {
    if (failing) throw Exception('keychain unavailable');
  }

  @override
  Future<String?> readApiKey(String accountId) async {
    _check();
    return values['${SecureStore.kApiKeyBase}_$accountId'];
  }

  @override
  Future<void> writeApiKey(String accountId, String key) async {
    _check();
    values['${SecureStore.kApiKeyBase}_$accountId'] = key.trim();
  }

  @override
  Future<void> deleteApiKey(String accountId) async {
    _check();
    values.remove('${SecureStore.kApiKeyBase}_$accountId');
  }

  @override
  Future<String?> readRelaySecret(String accountId) async {
    _check();
    return values['${SecureStore.kRelaySecretBase}_$accountId'];
  }

  @override
  Future<void> writeRelaySecret(String accountId, String secret) async {
    _check();
    values['${SecureStore.kRelaySecretBase}_$accountId'] = secret.trim();
  }

  @override
  Future<void> deleteRelaySecret(String accountId) async {
    _check();
    values.remove('${SecureStore.kRelaySecretBase}_$accountId');
  }

  @override
  Future<void> wipeAccount(String accountId) async {
    await deleteApiKey(accountId);
    await deleteRelaySecret(accountId);
  }

  @override
  Future<String?> readLocalCipherKey() async {
    _check();
    return values[SecureStore.kLocalCipherKey];
  }

  @override
  Future<void> writeLocalCipherKey(String keyBase64) async {
    _check();
    values[SecureStore.kLocalCipherKey] = keyBase64;
  }

  @override
  Future<void> deleteLocalCipherKey() async {
    _check();
    values.remove(SecureStore.kLocalCipherKey);
  }

  @override
  Future<String?> readLegacyApiKey() async {
    _check();
    return values[SecureStore.kApiKeyBase];
  }

  @override
  Future<String?> readLegacyRelaySecret() async {
    _check();
    return values[SecureStore.kRelaySecretBase];
  }

  @override
  Future<void> deleteLegacySlots() async {
    _check();
    values.remove(SecureStore.kApiKeyBase);
    values.remove(SecureStore.kRelaySecretBase);
  }

  @override
  Future<void> wipeAll() async {
    _check();
    values.clear();
  }
}

/// [AuthService] over no Firebase that still REPORTS available — widget
/// tests use it to surface the cloud-account UI without a Firebase app.
/// Every sign-in "succeeds" instantly with [nextUser].
class FakeAuthService extends AuthService {
  FakeAuthService({
    this.user,
    this.nextUser = const AuthUser(
      uid: 'uid_test',
      kind: AccountKind.google,
      displayName: 'Casey',
      email: 'casey@example.com',
    ),
  }) : super(null);

  /// The already-signed-in user, if any.
  AuthUser? user;

  /// What the next sign-in resolves to (and [user] becomes).
  AuthUser nextUser;

  @override
  bool get available => true;

  @override
  Stream<AuthUser?> userChanges() => Stream<AuthUser?>.value(user);

  @override
  AuthUser? get currentUser => user;

  Future<AuthUser?> _signIn() async => user = nextUser;

  @override
  Future<AuthUser?> signInAnonymously() => _signIn();

  @override
  Future<AuthUser?> signInWithApple({bool link = false}) => _signIn();

  @override
  Future<AuthUser?> signInWithGoogle({bool link = false}) => _signIn();

  @override
  Future<AuthUser?> signInWithCustomToken(String token) => _signIn();

  // --- Web redirect sign-in (see AuthService.beginRedirectSignIn) ---

  /// What [completeRedirectSignIn] resolves to — null models "no redirect was
  /// pending" (a normal boot) or a user who backed out of the provider page.
  AuthUser? redirectResult;

  /// Thrown by [completeRedirectSignIn]: a failed/expired redirect.
  Object? redirectError;

  /// Thrown by [beginRedirectSignIn]: the redirect could not even start.
  Object? redirectStartError;

  /// Every redirect this service was asked to start.
  final redirectStarts = <({OAuthProviderKind kind, bool link})>[];

  @override
  Future<void> beginRedirectSignIn(
    OAuthProviderKind kind, {
    bool link = false,
  }) async {
    final error = redirectStartError;
    if (error != null) throw error;
    redirectStarts.add((kind: kind, link: link));
  }

  @override
  Future<AuthUser?> completeRedirectSignIn() async {
    final error = redirectError;
    if (error != null) throw error;
    final result = redirectResult;
    if (result != null) user = result;
    return result;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final u = user;
    if (u != null) {
      user = AuthUser(
        uid: u.uid,
        kind: u.kind,
        displayName: name.trim(),
        email: u.email,
      );
    }
  }

  @override
  Future<void> signOut() async => user = null;
}

/// The account id every seeded test store uses unless it asks for more.
const kTestAccountId = 'acc_test';

/// A fresh [LocalStore] over mocked prefs, pre-registered with one account
/// (`acc_test`) so band-scoped reads/writes have a home. Per-band values in
/// [values] should already be suffixed via [LocalStore.accountKey] — or use
/// [accountValues] to have plain base keys suffixed automatically.
Future<LocalStore> seededStore({
  Map<String, Object> values = const {},
  Map<String, Object> accountValues = const {},
  String accountId = kTestAccountId,
  String bandName = '',
}) async {
  final registry = AccountsRegistry(
    accounts: [BandAccount(id: accountId, name: bandName, createdAtMs: 0)],
    activeId: accountId,
  );
  SharedPreferences.setMockInitialValues({
    LocalStore.kAccounts:
        '{"activeId":"$accountId","accounts":[{"id":"$accountId",'
        '"name":"$bandName","createdAtMs":0}]}',
    ...values,
    for (final e in accountValues.entries)
      LocalStore.accountKey(e.key, accountId): e.value,
  });
  final store = LocalStore(await SharedPreferences.getInstance());
  // Round-trip through the typed writer so the registry JSON always matches
  // the current schema even if the literal above drifts.
  await store.saveAccountsRegistry(registry);
  return store;
}

/// A [RelayAuth] that is already "signed in", with no Firebase behind it —
/// the transport identity every relay call needs, minus the plugin. A null
/// [uid] models a device with no relay at all (no Firebase, or the anonymous
/// sign-in failed).
class FakeRelayAuth extends RelayAuth {
  FakeRelayAuth({this.uid = 'uid_relay', this.owned = false})
      : super(AuthService(null));

  final String? uid;
  final bool owned;

  @override
  Future<String?> ensureRelayUid() async => uid;

  @override
  bool get ownsJars => owned;
}

/// One recorded callable invocation.
typedef RelayCall = ({String name, Map<String, dynamic> args});

/// Stands in for the jar callables: records every call, answers each by name
/// from [routes] (a route may throw), and returns `{}` for anything unrouted.
class FakeCallables {
  FakeCallables([this.routes = const {}]);

  final Map<String, Map<String, dynamic> Function(Map<String, dynamic>)> routes;
  final calls = <RelayCall>[];

  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> args) async {
    calls.add((name: name, args: args));
    final route = routes[name];
    return route == null ? const {} : route(args);
  }

  List<String> get names => [for (final call in calls) call.name];

  Map<String, dynamic> argsFor(String name) =>
      calls.firstWhere((call) => call.name == name).args;
}

RelayClient fakeRelayClient(FakeCallables backend, {RelayAuth? auth}) =>
    RelayClient(auth: auth ?? FakeRelayAuth(), invoke: backend.call);

/// The only way to build a [FirebaseFunctionsException] outside the plugin:
/// its constructor is `@protected`, so a subclass is the sanctioned door.
class FakeFunctionsException extends FirebaseFunctionsException {
  FakeFunctionsException(String code, [String message = 'refused'])
      : super(code: code, message: message);
}
