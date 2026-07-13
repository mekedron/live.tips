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

/// ONE switcher (#29). Switching the account and switching the profile were two
/// surfaces, two shapes and two rule sets for one question — "which of my things
/// am I working in right now?" — and every bug in that family came out of the
/// split. These tests pin the rules that are now written once: a live session
/// refuses BOTH kinds with one sentence, a profile under another account is one
/// action, the destructive acts are reachable here and guarded, and the device's
/// own profiles are a MODE, not an account.

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
/// and gives it its own Firestore — the state the switcher must render as one
/// list: a mode, an account, and the profiles under each.
Future<ProviderContainer> _pumpSheet(
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
              builder: (context, ref, _) => TextButton(
                onPressed: () => showSwitcherSheet(context, ref),
                child: const Text('open'),
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
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

/// Lets a live session's poll timer (and a snackbar's) drain before teardown.
Future<void> _drain(WidgetTester tester, ProviderContainer container) async {
  await container.read(liveSessionProvider.notifier).stop();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one list: the device\'s profiles, the accounts, and both doors',
      (tester) async {
    await _pumpSheet(tester, cloud: true);

    // The mode, its profiles, the account, ITS profile — one sheet.
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Solo Act'), findsOneWidget);
    expect(find.text('The Midnight Foxes'), findsOneWidget);
    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Duo Sundays'), findsOneWidget);
    expect(find.text('Night Shift'), findsOneWidget);
    // …and the two doors that used to live on two different screens.
    expect(find.text('Add a profile'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);
  });

  testWidgets('"On this device" is a mode, not an account: nothing to sign out '
      'of and nothing to delete', (tester) async {
    await _pumpSheet(tester);

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

  testWidgets('a profile under ANOTHER account is ONE action: the flip and the '
      'choice together', (tester) async {
    final container = await _pumpSheet(tester, cloud: true);
    expect(container.read(accountsDirectoryProvider).activeAccountId, 'uid_1');

    // One tap on a profile that lives under a different account. The artist
    // never says "switch account" first, and is never dropped on a picker to
    // answer the question they have just answered (#25/#28).
    await tester.tap(find.text('The Midnight Foxes'));
    await tester.pumpAndSettle();

    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
    expect(container.read(appStateProvider).accountId, 'acc_b',
        reason: 'exactly the profile that was tapped — not the one this device '
            'last had open over there');
  });

  testWidgets('a live session refuses BOTH kinds of switch, in one sentence',
      (tester) async {
    final container = await _pumpSheet(tester, cloud: true, live: true);

    // A profile of the account in use — the switch the band sheet always
    // refused.
    await tester.tap(find.text('Night Shift'));
    await tester.pumpAndSettle();
    expect(
        find.text('Stop the live session before switching.'), findsOneWidget);
    expect(container.read(appStateProvider).accountId, isNot('acc_cloud2'));

    // And a whole account — the switch the ACCOUNT screen used to allow (#2),
    // which is how a flip landed under a live set. Same guard, same words.
    await tester.tap(find.text('On this device'));
    await tester.pumpAndSettle();
    expect(
        find.text('Stop the live session before switching.'), findsOneWidget);
    expect(container.read(accountsDirectoryProvider).activeAccountId, 'uid_1',
        reason: 'the flip must not have happened');
    expect(container.read(liveSessionProvider), isNotNull);

    await _drain(tester, container);
  });

  testWidgets('sign out is here, looks destructive, and is guarded',
      (tester) async {
    final container = await _pumpSheet(tester, cloud: true, live: true);

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
    final container = await _pumpSheet(tester, live: true);

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
                  onPressed: () => showSwitcherSheet(context, ref),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The tablet's profiles, and nothing that skips the banner's
    // approve-and-wipe ceremony: no other accounts, no sign-in door, not even
    // the local mode.
    expect(find.text('Solo Act'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsNothing);
    expect(find.text('On this device'), findsNothing);

    // The stint's 12-hour ceiling timer dies with the stint.
    await container.read(venueSessionProvider.notifier).endSession();
    await tester.pumpAndSettle();
  });
}
