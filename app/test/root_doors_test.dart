import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The question no test in this suite ever asked (#40, #46): *from this root,
/// can the artist get OUT?*
///
/// Every door out of a state — Settings, and behind it sign-out, the sign-in
/// methods, delete account, what this device is, the demo — used to live inside
/// AppShell, and the shell only builds around a profile. So the two band-less
/// roots were rooms with no doors: an artist who deleted their last profile
/// beside a cloud account the device knew got "No profile on this device yet",
/// no Settings anywhere on the device, no sign-out, and — because
/// deviceIsSetUpProvider is true forever once one cloud row exists — no way
/// back to Welcome, ever. The screens all rendered exactly as their tests said
/// they would.
///
/// These tests walk the graph rather than a node: they land on a root, tap what
/// is on it, and press Back — the thing no test in app/test/ did.
const _uid = 'uid_cloud';

const _jar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'Solo Act',
  currency: 'eur',
  revolutUsername: 'solo',
  createdAtMs: 0,
);

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  LocalStore local, {
  AuthService? auth,
  FakeFirebaseFirestore? db,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
        if (db != null) ...[
          firestoreProvider.overrideWithValue(db),
          tipSourceFactoryProvider.overrideWithValue(
              ({required demo, required apiKey, required jar}) =>
                  NullTipSource()),
          relayChannelFactoryProvider.overrideWithValue(
              ({required demo, required jar, required secret}) => null),
        ],
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
      tester.element(find.byType(LiveTipsApp)),
      listen: false);
}

/// The directory of a device signed into a cloud account.
AccountsDirectory _signedIn() => AccountsDirectory.initial()
    .withAccount(const AppAccount(
      id: _uid,
      name: 'Casey',
      kind: AccountKind.google,
    ))
    .withActive(_uid);

FakeAuthService _casey() => FakeAuthService(
      user: const AuthUser(
        uid: _uid,
        kind: AccountKind.google,
        displayName: 'Casey',
        email: 'casey@example.com',
      ),
    );

void main() {
  group('the empty profile set of a cloud account', () {
    testWidgets('reaches Settings — and Back from it comes back here',
        (tester) async {
      final local = await _store();
      await local.saveAccountsDirectory(_signedIn());
      await _pumpApp(tester, local,
          auth: _casey(), db: FakeFirebaseFirestore());

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      expect(find.text('No profile in this account yet'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // The doors, all of them behind this one screen.
      expect(find.byType(SettingsRouteScreen), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('My own device'), findsOneWidget,
          reason: 'what this device is stays changeable from every root');
      // …and nothing that would act on the profile that does not exist.
      expect(find.text('Delete this profile'), findsNothing);

      // The Back arrow of a pushed route over a root that has not moved: it
      // means what it says.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePickScreen), findsOneWidget);
    });

    testWidgets('signs out from there — and onboarding is reachable again',
        (tester) async {
      final local = await _store();
      await local.saveAccountsDirectory(_signedIn());
      final container = await _pumpApp(tester, local,
          auth: _casey(), db: FakeFirebaseFirestore());

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      // The dialog's own "Sign out" is the second of the two.
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();

      expect(container.read(accountsDirectoryProvider).accounts.any((a) =>
          !a.isLocal), isFalse,
          reason: 'sign-out takes the account off the device (#31)');

      // The root under the Settings route rebuilt — and the pitch, the demo and
      // the device-kind link are back. "Welcome is unreachable forever" was the
      // sharpest edge of this room.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(ProfilePickScreen), findsNothing);
    });

    testWidgets('"Switch account" opens the ACCOUNT sheet — the label and the '
        'sheet finally agree (#49)', (tester) async {
      final local = await _store();
      await local.saveAccountsDirectory(_signedIn());
      await _pumpApp(tester, local,
          auth: _casey(), db: FakeFirebaseFirestore());

      await tester.tap(find.text('Switch account'));
      await tester.pumpAndSettle();

      // This test used to tap "Switch account" and assert "Your profiles" —
      // green, and the bug: the only control in the app that said "account"
      // opened the profile sheet, and there was no account picker anywhere. (It
      // was vacuous twice over: "Your profiles" is also this screen's OWN app-bar
      // title, so the assertion could not tell the sheet from the room it opened
      // over. The account sheet's heading names only itself.)
      expect(find.text('Your accounts'), findsOneWidget);
      expect(find.text('Add a profile'), findsNothing,
          reason: 'the profile sheet is not what this label promises');
      // The accounts this device knows, the mode that is not one, and the door
      // to an account it has never seen. Casey appears TWICE: in the sheet's
      // row, and on the screen underneath it, which now names the account it is
      // asking about (#51) — the sheet is a modal, so the room it opened over is
      // still standing.
      expect(find.text('Casey'), findsNWidgets(2));
      expect(find.text('On this device'), findsOneWidget);
      expect(find.text('Sign in to another account'), findsOneWidget);
      // A sheet, not a route: the screen that opened it is still standing.
      expect(find.byType(ProfilePickScreen), findsOneWidget);
    });
  });

  testWidgets(
      'the reported screen — no profile on this device, a cloud account known — '
      'has Settings on it', (tester) async {
    // The state the owner hit: the last local profile deleted while the device
    // still knows a (signed-out) cloud account. deviceIsSetUpProvider says
    // "set up" forever, so Welcome never renders again — and there was no
    // Settings on the device to sign in, sign out, or change what it is.
    final local = await _store();
    await local
        .saveAccountsRegistry(const AccountsRegistry(accounts: [], activeId: ''));
    await local.saveAccountsDirectory(
      AccountsDirectory.initial().withAccount(const AppAccount(
        id: _uid,
        name: 'Casey',
        kind: AccountKind.google,
      )),
    );
    // Signed OUT of it — the account row is all that is left, and it is what
    // makes Welcome unreachable.
    await _pumpApp(tester, local, auth: FakeAuthService());

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.text('No profile on this device yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsRouteScreen), findsOneWidget);
    // The way back INTO the account the device remembers…
    expect(find.text('Sign in / Create account'), findsOneWidget);
    // …the account sheet, which lists it (its session is gone, not the account
    // — one tap signs it back in)…
    expect(find.text('Switch account'), findsOneWidget);
    // …the profile sheet, for the profiles of whatever it lands in…
    expect(find.text('Switch profile'), findsOneWidget);
    // …and the device kind, which is how a device becomes a venue tablet or a
    // demo again.
    expect(find.text('My own device'), findsOneWidget);
  });

  testWidgets('the picker (several profiles, no answer yet) has Settings too',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final bands = db.collection('users').doc(_uid).collection('bands');
    await bands.doc('acc_a').set({'name': 'The Foxes', 'createdAtMs': 1});
    await bands.doc('acc_b').set({'name': 'Duo Sundays', 'createdAtMs': 2});
    final local = await _store();
    await local.saveAccountsDirectory(_signedIn());

    final container = await _pumpApp(tester, local, auth: _casey(), db: db);

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(container.read(appStateProvider).accountId, isEmpty);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsRouteScreen), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    // Nothing here may act on a profile the artist has not chosen yet.
    expect(find.text('Delete this profile'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.text('The Foxes'), findsOneWidget);
    expect(container.read(appStateProvider).accountId, isEmpty,
        reason: 'a trip to Settings answers nothing for the artist');
  });

  testWidgets('the shell keeps Settings where it has always been',
      (tester) async {
    final local = await _store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_solo', name: 'Solo Act', createdAtMs: 0)],
      activeId: 'acc_solo',
    ));
    await local.saveRelayJar('acc_solo', _jar);
    await _pumpApp(tester, local);

    expect(find.byType(AppShell), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(SettingsRouteScreen), findsNothing,
        reason: 'the shell hangs it on a tab — no route, no Back arrow');
    expect(find.text('Delete this profile'), findsOneWidget);
  });
}
