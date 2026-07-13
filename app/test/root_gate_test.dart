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
import 'package:live_tips/features/home/setup_home_screen.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The soft-lock this file exists for: a user who signs in halfway through
/// onboarding lands in a cloud account with zero bands. Welcome has no shell —
/// no switcher, no Settings, no sign-out — so that used to be a room with no
/// door, surviving a reload, with the user's local bands invisible behind it.
///
/// Welcome is now the genuinely-first-run screen and nothing else; every other
/// "nothing set up yet" state renders inside the shell.

const _jar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Configured',
  currency: 'eur',
  revolutUsername: 'cfg',
  createdAtMs: 0,
);

Future<void> _pumpApp(
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
        // Only the cloud tests need one: without a Firestore the repository
        // falls back to the local store, which is a different scenario.
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
}

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('a genuinely fresh device still gets the Welcome pitch',
      (tester) async {
    await _pumpApp(tester, await _store());

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets(
      'signed in with no band at all: the create-a-profile step, not Welcome '
      'and not an invented band', (tester) async {
    final local = await _store();
    const user = AuthUser(
      uid: 'uid_cloud',
      kind: AccountKind.google,
      displayName: 'Casey',
    );
    // The state after a mid-onboarding sign-in: a cloud profile is active and
    // it owns nothing yet.
    await local.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: 'uid_cloud',
            name: 'Casey',
            kind: AccountKind.google,
          ))
          .withActive('uid_cloud'),
    );
    await _pumpApp(tester, local, auth: FakeAuthService(user: user));

    // "This account has no profile" is a state the app renders — not a hole
    // plugged with a nameless band nobody asked for (#26). The way on is the
    // artist's own tap, and the way out (other accounts) is right there.
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.text('No profile in this account yet'), findsOneWidget);
    expect(find.text('Create a new profile'), findsOneWidget);
    expect(find.text('Switch account'), findsOneWidget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ProfilePickScreen)));
    expect(container.read(appStateProvider).accounts, isEmpty,
        reason: 'nothing may be minted for an account that has no profile');
  });

  testWidgets('an unconfigured band next to a configured one: the shell',
      (tester) async {
    final local = await _store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [
        BandAccount(id: 'acc_cfg', name: 'The Configured', createdAtMs: 0),
        BandAccount(id: 'acc_new', name: 'Half Done', createdAtMs: 1),
      ],
      activeId: 'acc_new',
    ));
    await local.saveRelayJar('acc_cfg', _jar);

    await _pumpApp(tester, local);

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(SetupHomeScreen), findsOneWidget);
  });

  testWidgets('a signed-out device that knows a cloud account: the shell',
      (tester) async {
    // Signed out of a cloud account this device has used. Welcome would hide
    // Settings — and with it the only way back into that account. The local
    // registry is the one every real install has (main() creates it before
    // runApp); the local profile's band is what the shell renders.
    final local = await _store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_local', name: '', createdAtMs: 0)],
      activeId: 'acc_local',
    ));
    await local.saveAccountsDirectory(
      AccountsDirectory.initial().withAccount(const AppAccount(
        id: 'uid_cloud',
        name: 'Casey',
        kind: AccountKind.google,
      )),
    );

    await _pumpApp(tester, local);

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(SetupHomeScreen), findsOneWidget);
  });

  // The un-deletable-profile loop: removing the LAST local profile used to
  // mint a fresh empty one and land the app right back in the shell on it —
  // because a cloud account in the directory said "set up", and the router
  // read that as "something to render". The removal tests always asserted on
  // the registry and the wiped data; these assert on where the user LANDS.

  testWidgets(
      'removing the last local profile beside a cloud account lands on the '
      'create-a-profile step — not in the shell on a fabricated profile, and '
      'not on the switcher it was tapped from (#38)', (tester) async {
    final local = await _store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_solo', name: 'Solo Act', createdAtMs: 0)],
      activeId: 'acc_solo',
    ));
    await local.saveRelayJar('acc_solo', _jar);
    await local.saveAccountsDirectory(
      AccountsDirectory.initial().withAccount(const AppAccount(
        id: 'uid_cloud',
        name: 'Casey',
        kind: AccountKind.google,
      )),
    );
    await _pumpApp(tester, local);
    expect(find.byType(AppShell), findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(
        await container
            .read(appStateProvider.notifier)
            .removeAccount(container.read(appStateProvider).accountId),
        isTrue);
    await tester.pumpAndSettle();

    // An empty profile set is an empty profile set, whoever owns it: the way
    // out is to make a profile, not to be handed the list of accounts (which
    // is the surface the artist would have come FROM).
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.text('No profile on this device yet'), findsOneWidget);
    expect(find.text('Create a new profile'), findsOneWidget);
    expect(find.text('Switch account'), findsOneWidget,
        reason: 'and the other accounts stay one tap away');
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(container.read(appStateProvider).accounts, isEmpty,
        reason: 'no replacement profile may be conjured back');
    expect(local.readAccountsRegistry()!.accounts, isEmpty,
        reason: 'the removal must survive a reboot too');
  });

  testWidgets(
      'the empty "On this device" mode is not a dead end: picking it from the '
      'switcher lands on the create step, never back on the switcher (#38)',
      (tester) async {
    // The state the artist is really in after the upload flow moved their
    // local profiles into an account (#25/#30), or after deleting the last
    // local one (#23): a guest cloud account holding the one profile, and a
    // local registry with nothing in it.
    final local = await _store();
    await local.saveAccountsRegistry(
        const AccountsRegistry(accounts: [], activeId: ''));
    await local.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: 'uid_guest',
            name: 'Guest',
            kind: AccountKind.anonymous,
          ))
          .withActive('uid_guest'),
    );
    final db = FakeFirebaseFirestore();
    await db
        .collection('users')
        .doc('uid_guest')
        .collection('bands')
        .doc('acc_cloud')
        .set({'name': 'The Foxes', 'createdAtMs': 1});
    await _pumpApp(
      tester,
      local,
      auth: FakeAuthService(
          user: const AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous)),
      db: db,
    );
    expect(find.byType(AppShell), findsOneWidget);

    // Settings is a TAB of the shell, so the switcher opens straight over the
    // root — which is what made the old pushed screen's pop land on the screen
    // it came from. A sheet has no route identity to collide with.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();
    expect(find.text('On this device'), findsOneWidget);

    // With no profiles under it, the mode's own label is the door in.
    await tester.tap(find.text('On this device'));
    await tester.pumpAndSettle();

    // Forward, not back: the local mode has no profiles, and the create step is
    // the door it never had. The sheet is gone — the artist is not standing on
    // the row they just tapped.
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.text('Sign in to another account'), findsNothing,
        reason: 'the sheet closed over what the tap landed on');
    expect(find.text('No profile on this device yet'), findsOneWidget);
    expect(find.text('Create a new profile'), findsOneWidget);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfilePickScreen)));
    expect(container.read(activeProfileRenderProvider), ProfileRender.create);
    expect(container.read(appStateProvider).accounts, isEmpty,
        reason: 'and nothing was minted to make the screen go away');
  });

  testWidgets(
      'removing the last local profile with no account of any kind left '
      'lands back on Welcome — onboarding is reachable again', (tester) async {
    final local = await _store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_solo', name: 'Solo Act', createdAtMs: 0)],
      activeId: 'acc_solo',
    ));
    await local.saveRelayJar('acc_solo', _jar);
    await _pumpApp(tester, local);
    expect(find.byType(AppShell), findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(
        await container
            .read(appStateProvider.notifier)
            .removeAccount(container.read(appStateProvider).accountId),
        isTrue);
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(container.read(appStateProvider).accounts, isEmpty);

    // And Welcome is not a dead end — but it is not a mint either (#47). This
    // assertion used to read "walking into onboarding mints the first band
    // again, so setup has something to configure", and it was true when setup
    // could only configure the ACTIVE band. #44 retired that: the details step
    // mints out of the name the artist types, and a tap that merely opens a
    // form writes nothing. So the tap re-opens onboarding and the registry
    // stays exactly as the deletion left it — empty.
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(container.read(appStateProvider).accounts, isEmpty,
        reason: 'a tap is not an ask: no profile before a name (#26, #44)');
    expect(find.text('Let\'s set up your tip jar'), findsOneWidget);

    // The profile appears when the artist names it — one profile, carrying the
    // name they typed, and never "Unnamed".
    await tester.enterText(find.byType(TextField).first, 'Second Act');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final accounts = container.read(appStateProvider).accounts;
    expect(accounts, hasLength(1));
    expect(accounts.single.name, 'Second Act');
    expect(local.readAccountsRegistry()?.accounts.single.name, 'Second Act');
  });

  testWidgets(
      'Try the demo with no profile at all: the demo shell, and still no '
      'profile written (#47)', (tester) async {
    final local = await _store();
    // The registry the artist's own deletion leaves behind: honestly empty.
    await local.saveAccountsRegistry(
        const AccountsRegistry(accounts: [], activeId: ''));
    await _pumpApp(tester, local);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();

    // Demo has everything it needs to render without a band: the jar, the name
    // and the feed are all TipJar.demo. It used to seed a nameless profile to
    // get a shell built around, which is the deletion undone by a tap.
    expect(find.byType(AppShell), findsOneWidget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(container.read(appStateProvider).demo, isTrue);
    expect(container.read(appStateProvider).accounts, isEmpty,
        reason: 'demo is not the artist\'s profile — it writes none');
    expect(local.readAccountsRegistry()?.accounts, isEmpty);
  });

  testWidgets('Try the demo on a fresh install plays demo against the band '
      'main() already seeded — no second one (#47)', (tester) async {
    final local = await _store();
    // What main()'s ensureAccountsRegistry leaves on a fresh install.
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_seed', name: '', createdAtMs: 0)],
      activeId: 'acc_seed',
    ));
    await _pumpApp(tester, local);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(container.read(appStateProvider).demo, isTrue);
    expect(container.read(appStateProvider).accounts, hasLength(1));
  });
}
