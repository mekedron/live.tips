import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/account_service.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/firebase/device_registry.dart';
import 'package:live_tips/data/firebase/link_codes.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/security_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/device_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// A [LinkCodeService] over no Firebase that records what the UI asked for.
class RecordingLinkCodeService extends LinkCodeService {
  RecordingLinkCodeService() : super();

  final revoked = <String>[];
  String? revokedAllFor;

  /// What the server hands back after the revoke: the caller's own way back in
  /// (#34). Null models a server that mints none — the revoke still happened.
  String? mintedToken = 'token-for-uid_1';

  @override
  Future<void> revokeDevice(String deviceId) async => revoked.add(deviceId);

  @override
  Future<RevokedSessions> revokeAllOtherDevices(String currentDeviceId) async {
    revokedAllFor = currentDeviceId;
    return RevokedSessions(revokedCount: 2, token: mintedToken);
  }
}

/// A [FakeAuthService] that counts the thing the kill switch must NEVER do:
/// send the artist back through an interactive provider sign-in, at the one
/// moment their credentials have just been invalidated. The fakes used to make
/// that round-trip succeed unconditionally — which is precisely why the app
/// tests could not see #34.
class WatchingAuthService extends FakeAuthService {
  WatchingAuthService({super.user, super.nextUser, this.tokenFails = false});

  /// The re-entry cannot be completed (offline, a token the client could not
  /// redeem) — a session is NOT a thing to throw away over that.
  final bool tokenFails;

  int providerSignIns = 0;
  int signOuts = 0;
  final tokens = <String>[];

  @override
  Future<AuthUser?> signInWithApple({bool link = false}) {
    providerSignIns++;
    return super.signInWithApple(link: link);
  }

  @override
  Future<AuthUser?> signInWithGoogle({bool link = false}) {
    providerSignIns++;
    return super.signInWithGoogle(link: link);
  }

  @override
  Future<AuthUser?> signInWithCustomToken(String token) async {
    tokens.add(token);
    return tokenFails ? null : user = nextUser;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    return super.signOut();
  }
}

DeviceInfo _device({
  required String id,
  required String name,
  String platform = 'ios',
  bool isCurrent = false,
  bool revoked = false,
  int lastSeenAtMs = 0,
}) =>
    DeviceInfo(
      id: id,
      name: name,
      platform: platform,
      isCurrent: isCurrent,
      revoked: revoked,
      lastSeenAtMs: lastSeenAtMs == 0
          ? DateTime.now().millisecondsSinceEpoch
          : lastSeenAtMs,
    );

Future<(RecordingLinkCodeService, WatchingAuthService)> _pump(
  WidgetTester tester, {
  required List<DeviceInfo> devices,
  AccountKind kind = AccountKind.google,
  String? ownDeviceId,
  bool tokenFails = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore();
  // An anonymous uid only counts as an ACCOUNT once the directory says so —
  // the relay's transport sign-in is anonymous too, and must never surface
  // here. An explicit sign-in is adopted, so the fixture records it.
  await localStore.saveAccountsDirectory(
    AccountsDirectory.initial().withAccount(
      AppAccount(id: 'uid_1', name: 'Casey', kind: kind),
    ),
  );
  final service = RecordingLinkCodeService();
  // The re-entry resolves to the SAME account it revoked for: same uid, same
  // kind, a session that is simply new.
  final casey = AuthUser(uid: 'uid_1', kind: kind, displayName: 'Casey');
  final auth = WatchingAuthService(
    user: casey,
    nextUser: casey,
    tokenFails: tokenFails,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider.overrideWithValue(auth),
        linkCodeServiceProvider.overrideWithValue(service),
        devicesProvider.overrideWith((ref) => Stream.value(devices)),
        if (ownDeviceId != null)
          deviceRegistryProvider.overrideWithValue(
              DeviceRegistry(db: null, deviceId: ownDeviceId)),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const SecurityScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (service, auth);
}

/// The deleteAccount callable, recorded. [stranded] models the one residue the
/// server cannot clear: an endpoint the artist's Stripe account kept.
class FakeAccountService extends AccountService {
  FakeAccountService({this.stranded = const [], this.error});

  final List<String> stranded;
  final AccountCallError? error;
  int calls = 0;

  @override
  Future<List<String>> deleteAccount() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return stranded;
  }
}

class _DeleteHarness {
  _DeleteHarness(this.store, this.secure, this.account);

  final LocalStore store;
  final FakeSecureStore secure;
  final FakeAccountService account;
}

/// The harness the delete tests brought over from sign_in_methods_test.dart:
/// a signed-in Google account that is ALSO the active profile, with a band and
/// its Stripe key on the device — so "the device lets go of its copy" is a
/// claim with something to let go of.
Future<_DeleteHarness> _pumpDelete(
  WidgetTester tester, {
  FakeAccountService? account,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const user = AuthUser(
    uid: 'uid_1',
    kind: AccountKind.google,
    displayName: 'Casey',
    email: 'casey@example.com',
    providers: [AccountKind.google],
  );
  final localStore = await seededStore(bandName: 'The Midnight Foxes');
  await localStore.saveAccountsDirectory(
    AccountsDirectory.initial()
        .withAccount(AppAccount(
          id: user.uid,
          name: user.displayName ?? '',
          kind: user.kind,
          email: user.email,
        ))
        .withActive(user.uid),
  );
  final secure = FakeSecureStore({
    '${SecureStore.kApiKeyBase}_$kTestAccountId': 'sk_test_seeded',
  });
  final service = account ?? FakeAccountService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(secure),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
        accountServiceProvider.overrideWithValue(service),
        devicesProvider.overrideWith((ref) => Stream.value(const <DeviceInfo>[])),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const SecurityScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _DeleteHarness(localStore, secure, service);
}

void main() {
  testWidgets('the device list renders, with this device marked', (
    tester,
  ) async {
    await _pump(tester, devices: [
      _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
      _device(
        id: 'dev_b',
        name: 'MacBook Pro',
        platform: 'macos',
        lastSeenAtMs: DateTime.now()
            .subtract(const Duration(hours: 3))
            .millisecondsSinceEpoch,
      ),
    ]);

    expect(find.text("Casey's iPhone"), findsOneWidget);
    expect(find.text('MacBook Pro'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Last seen 3 h ago'), findsOneWidget);
    // The current device offers no revoke button — you don't kick yourself out
    // from here (that's "Sign out"), and the other one does.
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });

  testWidgets('revoking asks first, then calls revokeDevice', (tester) async {
    final (service, _) = await _pump(tester, devices: [
      _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
      _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
    ]);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    // The dialog is honest about what revoking can and cannot do.
    expect(find.text('Revoke Old Pixel?'), findsOneWidget);
    expect(find.textContaining('asks that device to sign out'), findsOneWidget);
    expect(service.revoked, isEmpty); // nothing happened yet

    await tester.tap(find.widgetWithText(FilledButton, 'Revoke'));
    await tester.pumpAndSettle();

    expect(service.revoked, ['dev_b']);
    expect(find.text('That device was asked to sign out.'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog revokes nothing', (tester) async {
    final (service, _) = await _pump(tester, devices: [
      _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
    ]);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(service.revoked, isEmpty);
    expect(find.text('Revoke Old Pixel?'), findsNothing);
  });

  testWidgets(
      'the revoke button names its device to the a11y tree — a screen-reader '
      'user must know WHOSE session they are ending', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, devices: [
      _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
      _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
    ]);

    // A bare "Revoke" is exactly the production bug: one unlabeled tap with
    // no way to tell which device it kills.
    expect(find.bySemanticsLabel('Revoke'), findsNothing);
    expect(find.bySemanticsLabel('Revoke Old Pixel'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
      'the device in your hand never gets the foreign-revoke path — even '
      'when the isCurrent marker has drifted', (tester) async {
    // The production shape: registration failed / the device id rotated, so
    // the list's isCurrent flag marks nothing — but a row still carries the
    // id this device calls itself. Tapping its Revoke must NOT run
    // revokeDevice (which wipes this device's own keys); it is a sign-out,
    // and must say so.
    final (service, _) = await _pump(
      tester,
      ownDeviceId: 'dev_self',
      devices: [
        _device(id: 'dev_self', name: 'This very phone', isCurrent: false),
      ],
    );

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Sign out this device?'), findsOneWidget,
        reason: 'an honest dialog: this is the device being held');
    expect(find.textContaining('asks that device to sign out'), findsNothing,
        reason: 'never the foreign-revoke wording for yourself');

    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(service.revoked, isEmpty,
        reason: 'revokeDevice must never be sent this device\'s own id');
  });

  testWidgets(
      'the kill switch keeps the artist signed in — and never sends them '
      'back through a provider (#34)', (tester) async {
    // The bug: it revoked THIS device's session too and then re-ran an
    // interactive Apple/Google sign-in to restore it. A redirect that never
    // came back, a cancelled sheet — and the app signed the artist out of the
    // account they were protecting. The server now hands the caller a token
    // minted after the revoke, and that is the entire re-entry.
    final (service, auth) = await _pump(
      tester,
      kind: AccountKind.google,
      ownDeviceId: 'dev_a',
      devices: [
        _device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true),
        _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
      ],
    );

    await tester.tap(find.text('Sign out everywhere else'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
    await tester.pumpAndSettle();

    expect(service.revokedAllFor, 'dev_a');
    // The session is re-seated with the server's token, and NOTHING asked a
    // provider for anything.
    expect(auth.tokens, ['token-for-uid_1']);
    expect(auth.providerSignIns, 0,
        reason: 'no sheet, no redirect — nothing for the artist to cancel');
    expect(auth.signOuts, 0);
    expect(auth.user?.uid, 'uid_1');
    expect(find.text('Signed out 2 other device(s).'), findsOneWidget);
    expect(find.text("Casey's iPhone"), findsOneWidget,
        reason: 'still on the security screen, still signed in');
  });

  testWidgets(
      'a re-entry that fails does NOT sign the artist out of a session that '
      'is still valid', (tester) async {
    // The old code called auth.signOut() here. The session in hand is valid
    // until its ID token expires, the minted token stays good for an hour, and
    // a guest has no provider to come back with: signing out is the one thing
    // that turns a hiccup into a lockout.
    final (_, auth) = await _pump(
      tester,
      kind: AccountKind.google,
      ownDeviceId: 'dev_a',
      tokenFails: true,
      devices: [_device(id: 'dev_a', name: "Casey's iPhone", isCurrent: true)],
    );

    await tester.tap(find.text('Sign out everywhere else'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 0);
    expect(auth.user?.uid, 'uid_1');
    expect(auth.providerSignIns, 0);
    expect(find.textContaining('you are still signed in here'), findsOneWidget);
    expect(find.text("Casey's iPhone"), findsOneWidget);
    // And the token is still good, so the artist gets another go at it.
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(auth.tokens, ['token-for-uid_1', 'token-for-uid_1']);
  });

  testWidgets(
      'a guest account can sign out everywhere else — and keeps the door #32 '
      'built', (tester) async {
    // The restriction existed for one reason: a guest had no provider to
    // re-authenticate with. The server's token needs none (#34), so the switch
    // is armed — and linking, still worth offering, is no longer a hostage.
    final (service, auth) = await _pump(
      tester,
      kind: AccountKind.anonymous,
      ownDeviceId: 'dev_a',
      devices: [
        _device(id: 'dev_a', name: 'Guest phone', isCurrent: true),
        _device(id: 'dev_b', name: 'Old Pixel', platform: 'android'),
      ],
    );

    expect(find.textContaining('Link Apple or Google first'), findsNothing);
    expect(find.textContaining('works on a guest account too'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Sign out everywhere else'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Sign out everywhere else'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out others'));
    await tester.pumpAndSettle();

    expect(service.revokedAllFor, 'dev_a');
    expect(auth.tokens, ['token-for-uid_1']);
    expect(auth.providerSignIns, 0);
    expect(auth.user?.uid, 'uid_1');
    expect(find.text('Signed out 2 other device(s).'), findsOneWidget);

    // #32's door is still there: linking is how a guest gets back in on a NEW
    // device, it just is not a prerequisite for the kill switch any more.
    await tester.tap(find.text('Link Apple or Google'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in methods'), findsOneWidget);
  });

  testWidgets('an empty account still renders its (empty) list', (
    tester,
  ) async {
    await _pump(tester, devices: const []);
    expect(find.text('No devices listed yet.'), findsOneWidget);
  });

  // ------------------------------------------------------ delete account ---
  //
  // The exit #33 asked for. It used to live at the bottom of the sign-in
  // methods screen, where nobody thinking "delete my account" ever looked;
  // it now sits here, last of the account's sharp tools — moved, not
  // rewritten, so these tests moved with it (from sign_in_methods_test.dart)
  // and assert the same flow: nothing at all happens until the word is
  // typed, then the server erases first and the device lets go only after.

  testWidgets('deleting the account does nothing until the word is typed',
      (tester) async {
    final harness = await _pumpDelete(tester);

    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();

    // The confirmation is proportional: it names what goes AND what stays.
    expect(find.text('Delete this account?'), findsOneWidget);
    expect(find.textContaining('the tip.live.tips links stop working'),
        findsOneWidget);
    expect(find.textContaining('live in YOUR Stripe account'), findsOneWidget);

    // Armed only by the exact word — a stray tap deletes nothing.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete forever'),
    );
    expect(button.onPressed, isNull);
    expect(harness.account.calls, 0);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Delete forever'))
          .onPressed,
      isNull,
      reason: 'the word must match exactly',
    );

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();

    // The server erases the account; the device lets go of its copy only then.
    expect(harness.account.calls, 1);
    expect(harness.store.readAccountsDirectory()!.contains('uid_1'), isFalse);
    expect(await harness.secure.readApiKey(kTestAccountId), isNull);
    expect(find.text('Your account and everything in it are gone.'),
        findsOneWidget);
  });

  testWidgets('a refused delete keeps the account, and never claims otherwise',
      (tester) async {
    final harness = await _pumpDelete(
      tester,
      account: FakeAccountService(
        error: const AccountCallError(AccountCallErrorKind.unauthenticated),
      ),
    );

    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();

    // A stale session is the ONE refusal with a fix the artist can act on.
    expect(find.textContaining('Sign in again'), findsOneWidget);
    // And nothing local was touched: the account still exists.
    expect(harness.store.readAccountsDirectory()!.contains('uid_1'), isTrue);
    expect(await harness.secure.readApiKey(kTestAccountId), 'sk_test_seeded');
  });

  testWidgets('an endpoint Stripe kept is named, not swallowed', (tester) async {
    await _pumpDelete(
      tester,
      account: FakeAccountService(stranded: const ['we_left_behind']),
    );

    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('could not be removed from your Stripe account'),
      findsOneWidget,
    );
  });
}
