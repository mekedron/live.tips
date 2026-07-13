import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:live_tips/widgets/profile_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// TWO switchers, ONE design (#49). #29 brought the account screen and the band
/// sheet into one shape — and merged the two questions while it was there: a
/// device mode, some profiles, an account and two doors, one flat list, one
/// heading. These tests pin the split that undoes that and keeps everything
/// else: the profile sheet asks *which profile am I performing as*, the account
/// sheet asks *whose profiles am I looking at*, and the rules they obey — one
/// guard, one switch, one mint point, one sign-out — are still written once.

const _casey = AuthUser(
  uid: 'uid_1',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

/// A tip source that does nothing — a live session needs one to run.
class _IdleSource extends TipSource {
  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async => const [];

  @override
  String? get cursor => null;

  @override
  void dispose() {}
}

/// Two profiles on the device itself. [cloud] signs an account in beside them
/// and gives it its own Firestore, with two profiles of its own — the state in
/// which "which profile" and "which account" are two visibly different lists.
///
/// Neither sheet is opened here: the surface carries a door to each, because
/// what a door opens is the thing under test.
Future<ProviderContainer> _pumpDoors(
  WidgetTester tester, {
  bool cloud = false,
  bool live = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await local.saveAccountsRegistry(
    const AccountsRegistry(
      accounts: [
        BandAccount(id: 'acc_a', name: 'Solo Act', createdAtMs: 0),
        BandAccount(id: 'acc_b', name: 'The Midnight Foxes', createdAtMs: 1),
      ],
      activeId: 'acc_a',
    ),
  );
  final db = FakeFirebaseFirestore();
  if (cloud) {
    await local.saveAccountsDirectory(AccountsDirectory.initial()
        .withAccount(const AppAccount(
          id: 'uid_1',
          name: 'Casey',
          kind: AccountKind.google,
          email: 'casey@example.com',
        ))
        .withActive('uid_1'));
    await db
        .collection('users')
        .doc('uid_1')
        .collection('bands')
        .doc('acc_cloud')
        .set({'name': 'Duo Sundays', 'createdAtMs': 1});
    await db
        .collection('users')
        .doc('uid_1')
        .collection('bands')
        .doc('acc_cloud2')
        .set({'name': 'Night Shift', 'createdAtMs': 2});
  }
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    if (cloud) ...[
      firestoreProvider.overrideWithValue(db),
      authServiceProvider.overrideWithValue(FakeAuthService(user: _casey)),
    ],
    tipSourceFactoryProvider.overrideWithValue(
        ({required demo, required apiKey, required jar}) => _IdleSource()),
  ]);
  addTearDown(container.dispose);
  container.read(appStateProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => showProfileSheet(context, ref),
                    child: const Text('profiles'),
                  ),
                  TextButton(
                    onPressed: () => showAccountSheet(context, ref),
                    child: const Text('accounts'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (live) {
    // AFTER the mirror is warm — a set that starts on a cold account holds the
    // profile reload (AppStateNotifier), which is a different bug's territory.
    // Demo is the cheapest way to make a profile "connected" enough to run a
    // session; the guard under test never looks at what the session is FOR.
    container.read(appStateProvider.notifier).enterDemo();
    await container.read(liveSessionProvider.notifier).start(goalMinor: 1000);
    expect(container.read(liveSessionProvider), isNotNull);
    await tester.pumpAndSettle();
  }
  return container;
}

Future<void> _open(WidgetTester tester, String door) async {
  await tester.tap(find.text(door));
  await tester.pumpAndSettle();
}

/// Lets a live session's poll timer (and a snackbar's) drain before teardown.
Future<void> _drain(WidgetTester tester, ProviderContainer container) async {
  await container.read(liveSessionProvider.notifier).stop();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the PROFILE sheet asks one question: the profiles of the '
      'account in use, and how to add one', (tester) async {
    await _pumpDoors(tester, cloud: true);
    await _open(tester, 'profiles');

    expect(find.text('Your profiles'), findsOneWidget);
    // The profiles of the account the artist is IN — those, and the way to make
    // another.
    expect(find.text('Duo Sundays'), findsOneWidget);
    expect(find.text('Night Shift'), findsOneWidget);
    expect(find.text('Add a profile'), findsOneWidget);

    // …and nothing that is not a profile. The merged sheet stood a device MODE,
    // an ACCOUNT with a provider pill and a sign-in door in this same column,
    // and the artist had to know which of the four kinds each row was (#49).
    expect(find.text('On this device'), findsNothing);
    expect(find.text('Google'), findsNothing);
    expect(find.text('Sign in to another account'), findsNothing);
    // Nor the profiles of an account the artist is not in — the device's own
    // local ones belong to the local MODE, which is a different answer to a
    // different question.
    expect(find.text('Solo Act'), findsNothing);
    expect(find.text('The Midnight Foxes'), findsNothing);

    // One door out, at the foot, named for what it opens — and it says which
    // account these profiles are in.
    expect(find.text('Switch account'), findsOneWidget);
    expect(find.text('Signed in as Casey'), findsOneWidget);
  });

  testWidgets('the ACCOUNT sheet asks the other one: the accounts, the device '
      'mode, and the door to a new sign-in', (tester) async {
    await _pumpDoors(tester, cloud: true);
    await _open(tester, 'accounts');

    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    // The local mode is an answer to "whose profiles am I looking at" — it
    // stands here, among the accounts, and not among the profiles.
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);

    // And not one profile: this device holds no list of another account's
    // profiles, and the ones it does hold answer the other question.
    expect(find.text('Duo Sundays'), findsNothing);
    expect(find.text('Solo Act'), findsNothing);
    expect(find.text('Add a profile'), findsNothing);
  });

  testWidgets('the profile sheet\'s door opens the ACCOUNT sheet — the label '
      'and the sheet agree', (tester) async {
    await _pumpDoors(tester, cloud: true);
    await _open(tester, 'profiles');

    await tester.tap(find.text('Switch account'));
    await tester.pumpAndSettle();

    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);
    // One sheet at a time: the profile sheet closed on its way out.
    expect(find.text('Your profiles'), findsNothing);
  });

  testWidgets('"On this device" is a mode, not an account: nothing to sign out '
      'of and nothing to delete', (tester) async {
    await _pumpDoors(tester);
    await _open(tester, 'accounts');

    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Not an account — these stay on this device'),
        findsOneWidget);
    // The chrome an ACCOUNT row carries — a provider pill, a way out — is
    // absent: the local profile is permanent by construction
    // (AccountsDirectory.withoutAccount), and a button that cannot work is
    // worse than no button.
    expect(find.text('This device'), findsNothing);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('leaving a cloud account for the device mode is one flip — and '
      'the profile question that follows is the mode\'s own', (tester) async {
    final container = await _pumpDoors(tester, cloud: true);
    expect(container.read(accountsDirectoryProvider).activeAccountId, 'uid_1');
    await _open(tester, 'accounts');

    await tester.tap(find.text('On this device'));
    await tester.pumpAndSettle();

    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
    expect(container.read(appStateProvider).accountId, 'acc_a',
        reason: 'the mode opens on the profile this device last had in it — '
            'the artist is not asked a question they already answered');
    // The sheet closed over what the flip landed on (#38).
    expect(find.text('Your accounts'), findsNothing);
  });

  testWidgets('a live session refuses a PROFILE switch, and says why',
      (tester) async {
    final container = await _pumpDoors(tester, cloud: true, live: true);
    await _open(tester, 'profiles');

    await tester.tap(find.text('Night Shift'));
    await tester.pumpAndSettle();

    expect(
        find.text('Stop the live session before switching.'), findsOneWidget);
    expect(container.read(appStateProvider).accountId, isNot('acc_cloud2'));

    await _drain(tester, container);
  });

  testWidgets('a live session refuses an ACCOUNT flip too — the same guard, '
      'the same sentence', (tester) async {
    // The switch the old account SCREEN used to allow (#2), which is how a flip
    // landed under a live set. Two sheets, and still one guard.
    final container = await _pumpDoors(tester, cloud: true, live: true);
    await _open(tester, 'accounts');

    await tester.tap(find.text('On this device'));
    await tester.pumpAndSettle();

    expect(
        find.text('Stop the live session before switching.'), findsOneWidget);
    expect(container.read(accountsDirectoryProvider).activeAccountId, 'uid_1',
        reason: 'the flip must not have happened');
    expect(container.read(liveSessionProvider), isNotNull);

    await _drain(tester, container);
  });

  testWidgets('sign out is in the account sheet, looks destructive, and is '
      'guarded', (tester) async {
    final container = await _pumpDoors(tester, cloud: true, live: true);
    await _open(tester, 'accounts');

    // Guarded first: an account cannot be dropped out from under a live set,
    // and the refusal is the one every other act here gives.
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Stop the live session before signing out.'),
        findsOneWidget);
    expect(find.text('Sign out?'), findsNothing,
        reason: 'not even the dialog — the refusal comes first');
    expect(container.read(accountsDirectoryProvider).contains('uid_1'), isTrue);

    await _drain(tester, container);

    // The set is over: the same menu now reaches the dialog that says what
    // signing out costs — and the account leaves this device (#31).
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(
        container.read(accountsDirectoryProvider).contains('uid_1'), isFalse);
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
  });

  testWidgets('adding a profile is refused mid-session, and says why',
      (tester) async {
    final container = await _pumpDoors(tester, live: true);
    await _open(tester, 'profiles');

    await tester.tap(find.text('Add a profile'));
    await tester.pumpAndSettle();

    expect(find.text('Stop the live session before adding a profile.'),
        findsOneWidget);
    expect(container.read(appStateProvider).accounts, hasLength(2),
        reason: 'nothing is minted behind a refusal');

    await _drain(tester, container);
  });

  testWidgets('on a venue device: the profiles, and no door into an account',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = await seededStore(
      values: {LocalStore.kDeviceKind: 'venue'},
      bandName: 'Solo Act',
    );
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(local),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
      initialApiKeyProvider.overrideWithValue(null),
      authServiceProvider.overrideWithValue(FakeAuthService(user: _casey)),
    ]);
    addTearDown(container.dispose);
    // The artist's account on a public tablet — the state the banner's
    // ceremony leaves behind.
    await container.read(venueSessionProvider.notifier).start('uid_1');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: kTestL10nDelegates,
          locale: const Locale('en'),
          theme: buildLightTheme(),
          home: Scaffold(
            body: Center(
              child: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showProfileSheet(context, ref),
                  child: const Text('profiles'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _open(tester, 'profiles');

    // The tablet's profiles, and nothing that skips the banner's
    // approve-and-wipe ceremony: no door to the account sheet at all, so no
    // sign-in and no other account — the ways in and out of an account on a
    // public device run through the banner.
    expect(find.text('Solo Act'), findsOneWidget);
    expect(find.text('Switch account'), findsNothing);
    expect(find.text('Sign in to another account'), findsNothing);
    expect(find.text('On this device'), findsNothing);

    // The stint's 12-hour ceiling timer dies with the stint.
    await container.read(venueSessionProvider.notifier).endSession();
    await tester.pumpAndSettle();
  });
}
