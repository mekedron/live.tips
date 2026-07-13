import 'dart:convert';

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

  /// A LINK is an upgrade in place, and the fake must model that or the tests
  /// would prove nothing: the uid does not change, the account keeps everything
  /// it had, and it simply gains a permanent method.
  Future<AuthUser?> _link(AccountKind kind) async {
    final current = user;
    if (current == null) return _signIn();
    return user = AuthUser(
      uid: current.uid,
      kind: kind,
      displayName: current.displayName,
      email: current.email,
      providers: [
        for (final p in current.providers)
          if (p != kind) p,
        kind,
      ],
    );
  }

  @override
  Future<AuthUser?> signInAnonymously() => _signIn();

  @override
  Future<AuthUser?> signInWithApple({bool link = false}) =>
      link ? _link(AccountKind.apple) : _signIn();

  @override
  Future<AuthUser?> signInWithGoogle({bool link = false}) =>
      link ? _link(AccountKind.google) : _signIn();

  @override
  Future<AuthUser?> unlinkProvider(AccountKind kind) async {
    final current = user;
    if (current == null) return null;
    final left = [
      for (final p in current.providers)
        if (p != kind) p,
    ];
    return user = AuthUser(
      uid: current.uid,
      kind: left.isEmpty ? AccountKind.anonymous : left.first,
      displayName: current.displayName,
      email: current.email,
      providers: left,
    );
  }

  /// Every custom token redeemed on this service — the bridge return leg
  /// (see AuthController.consumePendingRedirect) signs in with exactly one.
  final redeemedTokens = <String>[];

  @override
  Future<AuthUser?> signInWithCustomToken(String token) {
    redeemedTokens.add(token);
    return _signIn();
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
///
/// Any `profile` sent through it is held to the relay's real text caps
/// (functions `validate.ts`): a fake that accepted anything is exactly how
/// the grapheme-vs-code-point clamp mismatch stayed invisible to this suite —
/// green tests, and a production relay refusing every emoji band name.
class FakeCallables {
  FakeCallables([this.routes = const {}]);

  final Map<String, Map<String, dynamic> Function(Map<String, dynamic>)> routes;
  final calls = <RelayCall>[];

  /// Clear only for a test that must reach the fake with a deliberately
  /// over-limit profile.
  bool enforceTextCaps = true;

  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> args) async {
    calls.add((name: name, args: args));
    if (enforceTextCaps) _checkProfile(args);
    final route = routes[name];
    return route == null ? const {} : route(args);
  }

  /// The scrub `validate.ts` runs before counting (minus NFC normalization,
  /// which Dart lacks and which only matters for decomposed input no keyboard
  /// produces): strip invisibles, controls become spaces, trim.
  static final _invisibles =
      RegExp('[\u202A-\u202E\u2066-\u2069\u200B-\u200D\u2060\uFEFF]');
  static final _controls = RegExp('[\u0000-\u001F\u007F-\u009F]');

  /// `textField` from `validate.ts`, verbatim where it counts: the relay
  /// rejects (never truncates) when the scrubbed CODE POINT count or the
  /// UTF-8 BYTE length exceeds the field's cap. Only the caps the client
  /// promises to satisfy by clamping are enforced — structural validity
  /// (required fields, payment methods) stays each test's own business.
  static void _checkText(
      Object? raw, String field, int maxCodePoints, int maxBytes) {
    if (raw is! String) return;
    final clean =
        raw.replaceAll(_invisibles, '').replaceAll(_controls, ' ').trim();
    if (clean.runes.length > maxCodePoints) {
      throw FakeFunctionsException('invalid-argument',
          '$field is too long (max $maxCodePoints characters)');
    }
    if (utf8.encode(clean).length > maxBytes) {
      throw FakeFunctionsException('invalid-argument', '$field is too long');
    }
  }

  static void _checkProfile(Map<String, dynamic> args) {
    final profile = args['profile'];
    if (profile is! Map) return;
    _checkText(profile['artistName'], 'artistName', 50, 200);
    _checkText(profile['message'], 'message', 200, 800);
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
