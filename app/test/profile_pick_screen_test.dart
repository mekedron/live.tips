import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/onboarding_details_screen.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Signing in to an EXISTING cloud account during onboarding used to march
/// straight into band creation — every new device minted another profile.
/// Now the account's real profiles are offered first (ProfilePickScreen);
/// creating a new one is the explicit alternative; and a genuinely fresh
/// account walks on to the band setup exactly as before.
const _uid = 'uid_test'; // FakeAuthService's default nextUser
const _bandId = 'acc_cloud';

CollectionReference<Map<String, dynamic>> _bands(FakeFirebaseFirestore db) =>
    db.collection('users').doc(_uid).collection('bands');

/// Welcome → Get started → the account step → "Sign in with Google" (the
/// default fake user is named, so naming is skipped) — the flow every test
/// here enters the fork through.
Future<LocalStore> _signInFromWelcome(
  WidgetTester tester,
  FakeFirebaseFirestore db,
) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final store = await seededStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        firestoreProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Google'));
  await tester.pumpAndSettle();
  return store;
}

/// A device already signed into the cloud account, with no local profile of
/// its own — the state every boot, account switch and Settings sign-in lands
/// in. (No local registry, so the upload offer has nothing to ask about.)
Future<LocalStore> _signedInStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  await store.saveAccountsDirectory(
    AccountsDirectory.initial()
        .withAccount(const AppAccount(
          id: _uid,
          name: 'Casey',
          kind: AccountKind.google,
        ))
        .withActive(_uid),
  );
  return store;
}

/// Boots the whole app on [store] with [db] behind the signed-in account, and
/// hands back the container so the tests can ask what is ACTIVE — the picker
/// is only half the fix; the other half is that nothing was activated.
Future<ProviderContainer> _bootApp(
  WidgetTester tester,
  LocalStore store,
  FakeFirebaseFirestore db,
) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        firestoreProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(FakeAuthService(
          user: const AuthUser(
            uid: _uid,
            kind: AccountKind.google,
            displayName: 'Casey',
          ),
        )),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
      tester.element(find.byType(LiveTipsApp)),
      listen: false);
}

void main() {
  testWidgets('signing in to an account with profiles shows the picker, and '
      'picking one lands in the shell', (tester) async {
    final db = FakeFirebaseFirestore();
    await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});

    await _signInFromWelcome(tester, db);

    // The fork, not band creation: the account's profile is on offer.
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.text('The Foxes'), findsOneWidget);
    expect(find.text('Create a new profile'), findsOneWidget);

    await tester.tap(find.text('The Foxes'));
    await tester.pumpAndSettle();

    // Onboarding is over — the shell shows the picked profile.
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ProfilePickScreen), findsNothing);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
        listen: false);
    expect(container.read(appStateProvider).accountId, _bandId,
        reason: 'the picked profile is the active one');
    // The regression this screen exists for: no new profile was minted.
    expect((await _bands(db).get()).docs.map((d) => d.id), [_bandId]);
  });

  testWidgets('"create a new profile" continues to the band setup with a '
      'fresh active band', (tester) async {
    final db = FakeFirebaseFirestore();
    await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});

    final store = await _signInFromWelcome(tester, db);
    await tester.tap(find.text('Create a new profile'));
    await tester.pumpAndSettle();

    // The details step, working on a NEW empty band — not renaming The
    // Foxes (the details step renames whatever band is active).
    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expect(store.readActiveCloudBand(_uid), isNot(_bandId));
    expect((await _bands(db).get()).docs, hasLength(2));
  });

  testWidgets('a fresh account with no profiles goes straight to the band '
      'setup — no picker flashed', (tester) async {
    final db = FakeFirebaseFirestore();

    await _signInFromWelcome(tester, db);

    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Create a new profile'), findsNothing);
    // …and it is still an account with no band doc in it: the profile is
    // written when the artist NAMES it, one screen from here, and not before.
    expect((await _bands(db).get()).docs, isEmpty);

    await tester.enterText(
        find.byType(TextField).first, 'The Foxes');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final docs = (await _bands(db).get()).docs;
    expect(docs, hasLength(1), reason: 'the named profile — and only it');
    expect(docs.first.data()['name'], 'The Foxes');
  });

  // ——— The root form: entering an account whose profile question is open ———

  group('the root picker', () {
    testWidgets('an account with several profiles ASKS — and activates '
        'nothing until the artist answers', (tester) async {
      final db = FakeFirebaseFirestore();
      await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});
      await _bands(db)
          .doc('acc_duo')
          .set({'name': 'Duo Sundays', 'createdAtMs': 2});
      final store = await _signedInStore();
      // The band this device last had open. It may point at a row; it may not
      // answer for the artist.
      await store.saveActiveCloudBand(_uid, 'acc_duo');

      final container = await _bootApp(tester, store, db);

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(find.text('The Foxes'), findsOneWidget);
      expect(find.text('Duo Sundays'), findsOneWidget);
      expect(find.text('Last used'), findsOneWidget,
          reason: 'the remembered profile pre-selects a row');
      expect(container.read(appStateProvider).accountId, isEmpty,
          reason: 'no gig is opened before the artist says which');

      // The artist picks the OTHER one — the app must open exactly that.
      await tester.tap(find.text('The Foxes'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(container.read(appStateProvider).accountId, _bandId);
      expect(store.readActiveCloudBand(_uid), _bandId);
    });

    testWidgets('an account with exactly one profile opens it — nothing to ask',
        (tester) async {
      final db = FakeFirebaseFirestore();
      await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});

      final container = await _bootApp(tester, await _signedInStore(), db);

      expect(find.byType(ProfilePickScreen), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
      expect(container.read(appStateProvider).accountId, _bandId);
    });

    testWidgets('an account with no profile at all offers to create one, and '
        'writes nothing until it is created', (tester) async {
      final db = FakeFirebaseFirestore();

      final container = await _bootApp(tester, await _signedInStore(), db);

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      expect(find.text('No profile in this account yet'), findsOneWidget);
      expect(container.read(appStateProvider).accounts, isEmpty);
      expect((await _bands(db).get()).docs, isEmpty,
          reason: 'a warm empty account must not be "repaired" with a band');

      await tester.tap(find.text('Create a new profile'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
      expect((await _bands(db).get()).docs, hasLength(1),
          reason: 'the artist asked for it — that is what may write a band');
    });
  });
}
