import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/features/account/cloud_upload_offer.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/route_depth.dart';

import 'helpers.dart';

/// The data-loss bug, in two acts. First: the offer to move this device's
/// profiles into a freshly signed-in account marked itself "already offered"
/// BEFORE the user answered — and it was raised while onboarding was pushing
/// its next screen, so it landed under an opaque route and was never seen.
/// One burned flag, and the local profiles stayed stranded forever. Second:
/// the flag was account-wide, so a profile created AFTER the answer was
/// covered by an answer nobody gave about it — stranded again, from the
/// other side.
///
/// The flag may only be written once an answer exists, and it only covers
/// the profiles the question was about.
class _Harness {
  _Harness(this.local, this.uploads, this.container);

  final LocalStore local;

  /// Every uid the upload actually ran for.
  final List<String> uploads;
  final ProviderContainer container;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool alreadyOffered = false,
  bool signIn = true,
  FirebaseFirestore? db,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // A named profile is worth moving — that is what brings the offer up at all.
  final local = await seededStore(bandName: 'Solo Act');
  if (alreadyOffered) {
    await local.markCloudUploadOffered('uid_test', [kTestAccountId]);
  }
  final uploads = <String>[];

  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    authServiceProvider.overrideWithValue(FakeAuthService()),
    // With a Firestore wired in, the REAL runner (CloudMigrator over the
    // fake db) runs; without one, a recording stub keeps the gate-decision
    // tests independent of the migrator.
    if (db != null)
      firestoreProvider.overrideWithValue(db)
    else
      cloudUploadRunnerProvider.overrideWithValue((uid, {onProgress}) async {
        uploads.add(uid);
        return null;
      }),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: kTestL10nDelegates,
      locale: const Locale('en'),
      theme: buildLightTheme(),
      navigatorObservers: [container.read(routeDepthObserverProvider)],
      home: CloudUploadOfferGate(
        child: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => ref
                    .read(authControllerProvider.notifier)
                    .signInWithGoogle(),
                child: const Text('sign in'),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();

  if (signIn) {
    await tester.tap(find.text('sign in'));
    await tester.pumpAndSettle();
  }
  return _Harness(local, uploads, container);
}

const _title = 'Move your profiles to this account?';

void main() {
  testWidgets('a sign-in raises the offer on the root screen', (tester) async {
    await _pump(tester);

    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('dismissing without answering leaves the offer un-burned',
      (tester) async {
    final h = await _pump(tester);
    expect(find.text(_title), findsOneWidget);

    // Barrier tap — the question was never answered.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    // The whole bug in one line: nothing recorded, so the profiles can still
    // be offered a home.
    expect(h.local.readCloudUploadOfferedBands('uid_test'), isEmpty);
    expect(h.uploads, isEmpty);
  });

  testWidgets('declining records the answer and moves nothing', (tester) async {
    final h = await _pump(tester);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(h.local.readCloudUploadOfferedBands('uid_test'),
        contains(kTestAccountId));
    expect(h.uploads, isEmpty);
  });

  testWidgets('accepting records the answer and moves the profiles',
      (tester) async {
    final h = await _pump(tester);

    await tester.tap(find.text('Move profiles'));
    await tester.pumpAndSettle();

    expect(h.local.readCloudUploadOfferedBands('uid_test'),
        contains(kTestAccountId));
    expect(h.uploads, ['uid_test']);
    expect(find.text('Your profiles now live in your account.'), findsOneWidget);
  });

  testWidgets('an account that answered about these profiles is not re-asked '
      '— but the sign-in still says where they stayed', (tester) async {
    await _pump(tester, alreadyOffered: true);

    expect(find.text(_title), findsNothing);
    // The switch happened anyway: without a word it reads, to the artist,
    // as "my band is gone".
    expect(find.textContaining('Your local profiles stayed on this device'),
        findsOneWidget);
  });

  testWidgets('a profile created after the first answer is a new question',
      (tester) async {
    // The stranding bug from the other side: the account answered once, and
    // the account-wide flag then covered a profile that did not even exist
    // when the question was asked.
    final h = await _pump(tester, alreadyOffered: true, signIn: false);
    await h.local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [
        BandAccount(id: kTestAccountId, name: 'Solo Act', createdAtMs: 0),
        BandAccount(id: 'acc_later', name: 'The Later Band', createdAtMs: 1),
      ],
      activeId: kTestAccountId,
    ));

    await tester.tap(find.text('sign in'));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget,
        reason: 'the flag means "asked about THESE profiles", not '
            '"asked, ever"');

    // The answer covers the new profile too — the next sign-in is quiet.
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(h.local.readCloudUploadOfferedBands('uid_test'),
        containsAll(<String>[kTestAccountId, 'acc_later']));
    expect(h.uploads, isEmpty);
  });

  testWidgets(
      'after the upload the app lands ON the migrated profile — not on some '
      'unrelated pre-existing cloud band', (tester) async {
    // The production shape: the account already owns a band ("Cloud"), and
    // it is recorded as the cloud profile's active band. The migrated band
    // must win over it once the upload commits.
    final db = FakeFirebaseFirestore();
    await db
        .doc('users/uid_test/bands/band_cloud')
        .set({'name': 'Cloud', 'createdAtMs': 1});
    final h = await _pump(tester, db: db);
    await h.local.saveActiveCloudBand('uid_test', 'band_cloud');
    // Mount app state so the directory flip and the mirror drive it.
    h.container.read(appStateProvider);

    await tester.tap(find.text('Move profiles'));
    await tester.pumpAndSettle();

    // The band really moved into the account…
    final doc = await db.doc('users/uid_test/bands/$kTestAccountId').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Solo Act');
    // …and the app switched TO it, instead of keeping "Cloud" active just
    // because it was still a valid id.
    expect(h.local.readActiveCloudBand('uid_test'), kTestAccountId);
    final app = h.container.read(appStateProvider);
    expect(app.accountId, kTestAccountId,
        reason: '"I moved MY band here" must not land on an unrelated '
            'profile — that reads as data loss');
    expect(app.accounts.map((a) => a.name), contains('Solo Act'));
  });

  testWidgets('a sign-in mid-onboarding waits for the flow to finish',
      (tester) async {
    // The reproduction: the user signs in from a pushed onboarding screen
    // (AccountStepScreen), which then pushes the next step. A dialog raised in
    // that moment lands under an opaque route — shown, never seen, gone.
    final h = await _pump(tester, signIn: false);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('onboarding step')),
    ));
    await tester.pumpAndSettle();

    await h.container
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    await tester.pumpAndSettle();

    expect(find.text('onboarding step'), findsOneWidget);
    expect(find.text(_title), findsNothing);
    expect(h.local.readCloudUploadOfferedBands('uid_test'), isEmpty);

    // Onboarding ends (popUntil isFirst) — now the question can be seen, and
    // it is still there to be asked.
    navigator.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();

    expect(find.text(_title), findsOneWidget);
  });
}
