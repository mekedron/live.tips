import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/features/home/setup_home_screen.dart';
import 'package:live_tips/features/onboarding/profile_pick_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/features/venue/venue_reapproval_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The venue tablet asks WHICH profile — the same question, from the same
/// provider, on the same screen as every other device (#43).
///
/// VenueGate used to route straight to the shell. An artist whose cloud account
/// holds two profiles got `_pickActive(ask: true)`'s deliberate non-answer
/// (`accountId == ''`), a shell built around a band that does not exist, and a
/// "Set it up" button offering to mint a THIRD profile — on the one device where
/// the wrong QR ends up on a merch table in public. #26's rule (the app never
/// mints a profile) and #28's (several profiles ask, never guess) reached
/// RootGate and stopped there.
///
/// The venue tests only ever built this gate around a single-profile account,
/// where `_pickActive` opens the one band and the gap is invisible.
const _uid = 'uid_ana';

const _ana = AuthUser(
  uid: _uid,
  kind: AccountKind.google,
  displayName: 'Ana',
  email: 'ana@example.com',
);

CollectionReference<Map<String, dynamic>> _bands(FakeFirebaseFirestore db) =>
    db.collection('users').doc(_uid).collection('bands');

void main() {
  /// A venue tablet mid-stint: the kind is venue, the code has been redeemed,
  /// the 12-hour session is running and the artist has said "that's me".
  Future<({LocalStore store, FakeSecureStore secure})> pumpVenueApp(
    WidgetTester tester,
    FakeFirebaseFirestore db, {
    String? lastOpen,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await seededStore(values: {
      LocalStore.kDeviceKind: 'venue',
    });
    if (lastOpen != null) await store.saveActiveCloudBand(_uid, lastOpen);
    await store.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: _uid,
            name: 'Ana',
            kind: AccountKind.google,
          ))
          .withActive(_uid),
    );
    await store.saveVenueSession(VenueSession(
      uid: _uid,
      startedAtMs: 0,
      expiresAtMs: DateTime.now()
          .add(const Duration(hours: 6))
          .millisecondsSinceEpoch,
      identityConfirmed: true,
    ));
    final secure = FakeSecureStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
          initialRelaySecretProvider.overrideWithValue(null),
          authServiceProvider.overrideWithValue(FakeAuthService(user: _ana)),
          firestoreProvider.overrideWithValue(db),
          tipSourceFactoryProvider.overrideWithValue(
              ({required demo, required apiKey, required jar}) =>
                  NullTipSource()),
          relayChannelFactoryProvider.overrideWithValue(
              ({required demo, required jar, required secret}) => null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (store: store, secure: secure);
  }

  testWidgets(
      'two profiles on a venue tablet: the picker asks, and NOTHING is minted '
      '(#43)', (tester) async {
    final db = FakeFirebaseFirestore();
    await _bands(db).doc('acc_trio').set({'name': 'Trio', 'createdAtMs': 1});
    await _bands(db).doc('acc_solo').set({'name': 'Solo set', 'createdAtMs': 2});

    await pumpVenueApp(tester, db);

    // The question, not a guess — and not the phantom band-less shell with its
    // "Set it up" button into band creation.
    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(SetupHomeScreen), findsNothing);
    expect(find.text('Set it up'), findsNothing);
    expect(find.text('Trio'), findsOneWidget);
    expect(find.text('Solo set'), findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(ProfilePickScreen)));
    expect(container.read(activeProfileRenderProvider), ProfileRender.pick);
    expect(container.read(appStateProvider).accountId, isEmpty,
        reason: 'nobody has said which profile is tonight\'s yet');

    // A public device has no account door: accounts arrive and leave through
    // the banner's approve-and-wipe ceremony, and nowhere else.
    expect(find.text('Switch account'), findsNothing);
    // The identity is not a door, and it stays: the tablet says whose account
    // it is showing tonight — the fact #51 put on every form of this screen.
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    // The proof that asking mints nothing: the account's band docs are still
    // exactly the two the artist brought.
    expect((await _bands(db).get()).docs.map((d) => d.id),
        unorderedEquals(['acc_trio', 'acc_solo']),
        reason: 'a third profile may never appear in the artist\'s account');
  });

  testWidgets(
      'picking tonight\'s gig on the venue tablet does not demand a second '
      'code — the artist approved this session a minute ago (#43)',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _bands(db).doc('acc_trio').set({'name': 'Trio', 'createdAtMs': 1});
    await _bands(db).doc('acc_solo').set({'name': 'Solo set', 'createdAtMs': 2});

    await pumpVenueApp(tester, db);
    await tester.tap(find.text('Solo set'));
    await tester.pumpAndSettle();

    // The re-approval ceremony guards a CHANGE to what the tablet shows. The
    // first choice of a stint is not one — it is the ceremony's own last step,
    // and charging another add-device cycle for it is what pushed the artist
    // towards the create card instead.
    expect(find.byType(VenueReapprovalScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ProfilePickScreen), findsNothing);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(container.read(appStateProvider).accountId, 'acc_solo');
    expect(container.read(appStateProvider).displayName, 'Solo set');
    expect((await _bands(db).get()).docs, hasLength(2));
  });

  testWidgets(
      'a venue account with NO profile gets the create step, not a phantom '
      'empty shell (#43)', (tester) async {
    final db = FakeFirebaseFirestore();

    await pumpVenueApp(tester, db);

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('No profile in this account yet'), findsOneWidget);
    expect(find.text('Create a new profile'), findsOneWidget);
    expect(find.text('Switch account'), findsNothing);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(ProfilePickScreen)));
    expect(container.read(activeProfileRenderProvider), ProfileRender.create);
    expect(container.read(appStateProvider).accounts, isEmpty,
        reason: 'an empty profile set is a state, not a hole to plug');
    expect((await _bands(db).get()).docs, isEmpty,
        reason: 'and standing on the create step writes no band doc');
  });

  testWidgets(
      'a venue tablet NEVER auto-opens a profile: one profile, a remembered '
      'answer — the picker still asks at every open', (tester) async {
    // The artist's own phone would open this without a question: a single
    // profile, and even a stored last-open answer on file. A shared tablet
    // may not — the artist standing at the bar tonight is not necessarily
    // the artist who stood there this morning, and a screen that guesses
    // is guessing in public.
    final db = FakeFirebaseFirestore();
    await _bands(db).doc('acc_trio').set({'name': 'Trio', 'createdAtMs': 1});

    await pumpVenueApp(tester, db, lastOpen: 'acc_trio');

    expect(find.byType(ProfilePickScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ProfilePickScreen)));
    expect(container.read(appStateProvider).accountId, isEmpty,
        reason: 'nothing opens on a shared device until tonight\'s artist '
            'says so');
    // The memory is not thrown away — it marks the row it may not open.
    expect(find.text('Last used'), findsOneWidget);

    // And the tap is all it ever costs: the one profile is one tap away.
    await tester.tap(find.text('Trio'));
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(container.read(appStateProvider).accountId, 'acc_trio');
  });
}
