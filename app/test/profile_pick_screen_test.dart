import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/repository/account_data_repository.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
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
          email: 'casey@example.com',
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

  testWidgets('"create a new profile" opens the setup and writes NOTHING — the '
      'name is what creates the profile', (tester) async {
    final db = FakeFirebaseFirestore();
    await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});

    final store = await _signInFromWelcome(tester, db);
    await tester.tap(find.text('Create a new profile'));
    await tester.pumpAndSettle();

    // This test used to assert the opposite — that the tap minted the band —
    // and the bug it encoded is #44: an artist who backed out of the form was
    // left with an "Unnamed" profile they never made, on every device the
    // account touches. The tap opens the form. That is all it does.
    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expect((await _bands(db).get()).docs.map((d) => d.id), [_bandId]);
    expect(store.readActiveCloudBand(_uid), isNot('acc_new'));
    // …and the field is empty: the run is creating a profile, so the active
    // band's name is not a suggestion for it.
    expect(
        (tester.widget(find.byType(TextField).first) as TextField)
            .controller!
            .text,
        isEmpty);

    await tester.enterText(find.byType(TextField).first, 'Duo Sundays');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final docs = (await _bands(db).get()).docs;
    expect(docs, hasLength(2), reason: 'the named profile — and only it');
    final fresh = docs.firstWhere((d) => d.id != _bandId);
    expect(fresh.data()['name'], 'Duo Sundays');
    expect(store.readActiveCloudBand(_uid), fresh.id,
        reason: 'and the artist is standing in the one they just named');
  });

  testWidgets('abandoning the create form leaves NOTHING behind — no band, no '
      'registry entry, on the account or on this device', (tester) async {
    final db = FakeFirebaseFirestore();
    await _bands(db).doc(_bandId).set({'name': 'The Foxes', 'createdAtMs': 1});

    final store = await _signInFromWelcome(tester, db);
    await tester.tap(find.text('Create a new profile'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);

    // The artist changes their mind, and presses Back. Nothing was promised
    // and nothing may be kept: the profile set is what it was.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect((await _bands(db).get()).docs.map((d) => d.id), [_bandId],
        reason: 'a phantom here lands on every device the artist owns (#37)');
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfilePickScreen)),
        listen: false);
    expect(container.read(appStateProvider).accounts.map((a) => a.id),
        [_bandId],
        reason: 'nothing minted, nothing activated — the account is as it was');
    expect(store.readActiveCloudBand(_uid), isNull,
        reason: 'and no phantom to force the picker on the next cold boot');
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

      // The form, and still nothing written: the tap asked for the form, the
      // name is what asks for the profile (#44).
      expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
      expect((await _bands(db).get()).docs, isEmpty);

      await tester.enterText(find.byType(TextField).first, 'The Foxes');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final docs = (await _bands(db).get()).docs;
      expect(docs, hasLength(1),
          reason: 'the artist named it — that is what may write a band');
      expect(docs.first.data()['name'], 'The Foxes');
    });

    testWidgets('abandoning the create form on the LOCAL profile leaves the '
        'device exactly as it was', (tester) async {
      // The reported screen: no profile on this device, a cloud account the
      // device still knows. The only forward move offered is "create" — and
      // taking it back must cost nothing.
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      await store.saveAccountsRegistry(
          const AccountsRegistry(accounts: [], activeId: ''));
      await store.saveAccountsDirectory(
        AccountsDirectory.initial().withAccount(const AppAccount(
          id: _uid,
          name: 'Casey',
          kind: AccountKind.google,
        )),
      );

      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            secureStoreProvider.overrideWithValue(FakeSecureStore()),
            initialApiKeyProvider.overrideWithValue(null),
            authServiceProvider.overrideWithValue(FakeAuthService()),
          ],
          child: const LiveTipsApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No profile on this device yet'), findsOneWidget);
      await tester.tap(find.text('Create a new profile'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
      expect(store.readAccountsRegistry()!.accounts, isEmpty,
          reason: 'the tap opened a form; it did not write a profile');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      expect(find.text('No profile on this device yet'), findsOneWidget);
      expect(store.readAccountsRegistry()!.accounts, isEmpty);
      final container = ProviderScope.containerOf(
          tester.element(find.byType(ProfilePickScreen)),
          listen: false);
      expect(container.read(appStateProvider).accounts, isEmpty);
      expect(container.read(appStateProvider).accountId, isEmpty);
    });
  });

  // ——— #51: the screen that says "this account" says WHICH account ———
  //
  // Every test in this file knew whose account it had pumped — and the screen
  // never said. That is the shape of the bug: a widget test cannot notice a
  // fact it supplied itself. These assert the fact is on the SCREEN.
  group('the account this screen is asking about', () {
    testWidgets('an empty cloud account NAMES itself — name, provider, email — '
        'and the door beside it opens the ACCOUNTS', (tester) async {
      final db = FakeFirebaseFirestore();

      final container = await _bootApp(tester, await _signedInStore(), db);

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      expect(find.text('No profile in this account yet'), findsOneWidget);
      // …under a line that says which one it is. The artist who keeps the
      // band's account beside their own reads this before deciding whether to
      // create a profile here at all.
      expect(find.text('Casey'), findsOneWidget,
          reason: 'the account the profile would be created in, by name');
      expect(find.text('Google'), findsOneWidget,
          reason: 'and the provider, for two accounts with the same name');
      expect(find.text('casey@example.com'), findsOneWidget,
          reason: 'and the email, for two Google accounts');

      // The door is on the identity, not floating in the app bar — and it opens
      // the ACCOUNT sheet, which is the answer to the question the line raises.
      await tester.tap(find.text('Switch account'));
      await tester.pumpAndSettle();
      expect(find.text('Your accounts'), findsOneWidget);
      expect(find.text('Add a profile'), findsNothing,
          reason: 'the profiles are not what this label promises (#49)');

      // Nothing on this screen mints anything (#44/#47).
      expect(container.read(appStateProvider).accounts, isEmpty);
      expect((await _bands(db).get()).docs, isEmpty);
    });

    testWidgets('a guest account is named by what it is — no email invented',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      await store.saveAccountsDirectory(
        AccountsDirectory.initial()
            .withAccount(const AppAccount(
              id: _uid,
              name: '',
              kind: AccountKind.anonymous,
            ))
            .withActive(_uid),
      );
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            secureStoreProvider.overrideWithValue(FakeSecureStore()),
            initialApiKeyProvider.overrideWithValue(null),
            firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
            authServiceProvider.overrideWithValue(FakeAuthService(
              user: const AuthUser(uid: _uid, kind: AccountKind.anonymous),
            )),
          ],
          child: const LiveTipsApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      // A guest has no name and no email — and the screen says the honest thing
      // rather than nothing at all.
      expect(find.text('Guest'), findsWidgets);
      expect(find.text('Signed in to this account'), findsOneWidget);
      expect(find.text('Switch account'), findsOneWidget);
    });

    testWidgets('the LOCAL form does not pretend to have an account',
        (tester) async {
      // The device profile with no profiles left, beside a cloud account the
      // device knows but is signed out of. There is no account for a device
      // profile to be "in" — so no name, no email, no provider pill may appear
      // here, and the known account's name must NOT be borrowed as an identity.
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      await store.saveAccountsRegistry(
          const AccountsRegistry(accounts: [], activeId: ''));
      await store.saveAccountsDirectory(
        AccountsDirectory.initial().withAccount(const AppAccount(
          id: _uid,
          name: 'Casey',
          kind: AccountKind.google,
          email: 'casey@example.com',
        )),
      );

      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            secureStoreProvider.overrideWithValue(FakeSecureStore()),
            initialApiKeyProvider.overrideWithValue(null),
            authServiceProvider.overrideWithValue(FakeAuthService()),
          ],
          child: const LiveTipsApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePickScreen), findsOneWidget);
      expect(find.text('No profile on this device yet'), findsOneWidget);
      // What it IS, said in words that refuse the word "account".
      expect(find.text('On this device'), findsOneWidget);
      expect(find.text('Not an account — these stay on this device'),
          findsOneWidget);
      expect(find.text('Casey'), findsNothing,
          reason: 'a signed-out account this device remembers is not the '
              'identity of the device profile');
      expect(find.text('casey@example.com'), findsNothing);
      expect(find.text('Google'), findsNothing,
          reason: 'a device profile has no provider to show');
      expect(find.text('Signed in to this account'), findsNothing);
      // …and the way to a real account is still one tap away, next to the mode
      // it would replace.
      expect(find.text('Switch account'), findsOneWidget);
    });
  });

  /// THE SPINNER THAT NEVER RESOLVED (#54).
  ///
  /// The screen waited on the WARMTH OF AN OBJECT instead of on the ANSWER.
  /// `accountDataRepositoryProvider` builds a brand-new, COLD FirestoreRepository
  /// every time the session/auth/directory graph moves under it — which is
  /// routinely, in the very beats after the cloud sign-in that lands the artist
  /// on this screen. The old code re-read `repo.isWarm`, found the fresh object
  /// silent, and went back to its spinner — with its only deadline already
  /// cancelled by the warm build before it. No deadline, and no snapshot coming
  /// either (the new repository's listener is its own): the spinner span until
  /// the artist reloaded the page.
  ///
  /// fake_cloud_firestore cannot express this: it answers every listener with
  /// server truth, so a FirestoreRepository built on it is warm on its first
  /// snapshot and never cold again. [_Mirror] is the widened fake — a repository
  /// that has not heard from the server YET, which is what a real one always is
  /// for its first beat, and stays if the server never speaks.
  group('a repository rebuilt cold must not strand the picker (#54)', () {
    testWidgets('the pushed picker keeps the profiles it is already showing',
        (tester) async {
      final local = await seededStore();
      final secure = FakeSecureStore();
      final repo = ValueNotifier<AccountDataRepository>(_Mirror(
        local,
        () => secure,
        warm: true,
        bands: const [BandAccount(id: 'b1', name: 'Nightbirds', createdAtMs: 0)],
      ));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(local),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
          accountDataRepositoryProvider.overrideWith((ref) {
            ref.watch(repoRevisionProvider);
            return repo.value;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: kTestL10nDelegates,
          locale: const Locale('en'),
          theme: buildLightTheme(),
          home: const ProfilePickScreen(), // the gate's onboarding push
        ),
      ));
      await tester.pump();

      expect(find.text('Nightbirds'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // The sign-in's own machinery moves the graph — a slot commit, the auth
      // flip, the directory write — and the repository is rebuilt. Same account,
      // same profiles; a new object that has not heard from the server yet.
      final container = ProviderScope.containerOf(
          tester.element(find.byType(ProfilePickScreen)));
      repo.value = _Mirror(local, () => secure, warm: false);
      container.read(repoRevisionProvider.notifier).bump();
      await tester.pump();

      // A cold object is not new ignorance: these bands are what routed the
      // artist here, and they do not stop existing because the reader was
      // replaced.
      expect(find.text('Nightbirds'), findsOneWidget,
          reason: 'THE BUG: the profiles were un-listed and the screen went '
              'back to a spinner it could never leave');
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // And it stays out — there is no deadline left to save it, and none needed.
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Nightbirds'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the ROOT picker — which never had a deadline at all — lists '
        'the profiles it was routed here on', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final local = await seededStore();
      final secure = FakeSecureStore();
      // RootGate lands on the root picker because the app HAS several profiles
      // and nobody has said which (ProfileRender.pick) — and it is holding them
      // in AppState. The repository underneath is a fresh, cold object.
      final warm = _Mirror(local, () => secure, warm: true, bands: const [
        BandAccount(id: 'b1', name: 'Nightbirds', createdAtMs: 0),
        BandAccount(id: 'b2', name: 'The Wreckage', createdAtMs: 0),
      ]);
      final repo = ValueNotifier<AccountDataRepository>(warm);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(local),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
          accountDataRepositoryProvider.overrideWith((ref) {
            ref.watch(repoRevisionProvider);
            return repo.value;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: kTestL10nDelegates,
          locale: const Locale('en'),
          theme: buildLightTheme(),
          home: const ProfilePickScreen(asRoot: true),
        ),
      ));
      await tester.pump();
      expect(find.text('Nightbirds'), findsOneWidget);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(ProfilePickScreen)));
      repo.value = _Mirror(local, () => secure, warm: false);
      container.read(repoRevisionProvider.notifier).bump();
      await tester.pump(const Duration(seconds: 30));

      // The root form has no band setup to fall through to and never armed a
      // deadline — a cold repository here was a spinner with no exit in the
      // code at all. The only correct answer is the one the app already has.
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'THE BUG: the root picker span forever — no deadline, no '
              'snapshot, no way out but a page reload');
      expect(find.text('Nightbirds'), findsOneWidget);
      expect(find.text('The Wreckage'), findsOneWidget);
    });
  });
}

/// A cloud mirror that has not heard from the server YET — the state every real
/// FirestoreRepository is in for its first beat, and stays in if the server
/// never answers. fake_cloud_firestore cannot raise it: it hands every listener
/// server truth, so a repository built on it is warm immediately and never goes
/// back. Without this, the suite could not see a cold repository at all.
class _Mirror extends LocalStoreRepository {
  _Mirror(super.local, super.resolveSecure, {required this.warm, this.bands});

  final bool warm;
  final List<BandAccount>? bands;

  @override
  bool get isWarm => warm;

  @override
  List<BandAccount> listBands() => bands ?? const [];
}
