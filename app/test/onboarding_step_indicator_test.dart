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
import 'package:live_tips/features/onboarding/onboarding_details_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The step indicator, walked as a FLOW — every screen of every path, in order,
/// asserting the sequence of (N, M) the artist actually sees.
///
/// The owner's complaint: steps look skipped and the total does not match what
/// is asked. Both were true, and both were structural. Every screen computed its
/// own index with its own arithmetic ("step 1", "step 2", `prelude + 1`,
/// `prelude + stepOfMethod`) and its own fallback total (`?? 3`), so the numbers
/// contradicted each other: the account question promised "Step 1 of 4" and the
/// very next screen said "Step 2 of 5". The total had grown, because the naming
/// step is only known to exist AFTER the sign-in answers — and no number shown
/// before that answer can be true.
///
/// So the account phase — the question, the naming step, the profile fork — is
/// not numbered: it is a branch, not a queue (picking an existing profile there
/// ends onboarding on the spot). The counted run is the profile setup, whose
/// length the draft KNOWS: details, the method choice, one step per method. The
/// only thing that may move the total is the artist ticking another method — on
/// the screen where they tick it.
void main() {
  Future<LocalStore> store() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStore(await SharedPreferences.getInstance());
  }

  Future<void> pumpApp(
    WidgetTester tester,
    LocalStore local, {
    AuthService? auth,
    FakeFirebaseFirestore? db,
  }) async {
    await tester.binding.setSurfaceSize(const Size(700, 1600));
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
  }

  /// Exactly one step pill, saying exactly this.
  void expectStep(int step, int total) {
    expect(find.text('Step $step of $total'), findsOneWidget,
        reason: 'the artist is told where they are, once, and truthfully');
  }

  void expectNoStep() {
    expect(find.textContaining('Step '), findsNothing,
        reason: 'a screen whose place in the run is unknowable shows no number');
  }

  testWidgets('the local path: 1 of 3 → 2 of 3 → 3 of 3, and Back holds',
      (tester) async {
    // No cloud accounts on this platform (no auth override) — the account
    // question auto-skips, and the run is the setup alone.
    await pumpApp(tester, await store());

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expectStep(1, 3);

    await tester.enterText(find.byType(TextField).first, 'The Foxes');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expectStep(2, 3);

    // One method — the total the details step promised holds.
    await tester.tap(find.text('Revolut'));
    await tester.pumpAndSettle();
    expectStep(2, 3);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expectStep(3, 3);

    // Back is the one thing that may move the counter backwards, and it moves
    // it to the number the artist saw on the way in.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expectStep(2, 3);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expectStep(1, 3);
  });

  testWidgets('a second method lengthens the run — under the artist\'s own '
      'finger, on the screen where they tick it', (tester) async {
    await pumpApp(tester, await store());

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'The Foxes');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expectStep(2, 3);

    await tester.tap(find.text('Revolut'));
    await tester.pumpAndSettle();
    expectStep(2, 3);
    await tester.tap(find.text('Monzo'));
    await tester.pumpAndSettle();
    expectStep(2, 4);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // Revolut comes first in the fixed setup order; every method is a step, and
    // no step is skipped.
    expectStep(3, 4);
  });

  testWidgets('the cloud path: the account screens carry no number at all, and '
      'the setup still starts at 1', (tester) async {
    final auth = FakeAuthService(
      nextUser: const AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous),
    );
    await pumpApp(tester, await store(),
        auth: auth, db: FakeFirebaseFirestore());

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // The account question: a branch. It used to say "Step 1 of 4" and be
    // contradicted by the very next screen.
    expect(find.text('First, an account'), findsOneWidget);
    expectNoStep();

    await tester.tap(find.text('Anonymous cloud account'));
    await tester.pumpAndSettle();

    // The naming step — the screen whose existence nobody could have promised.
    expect(find.text('What should we call you?'), findsOneWidget);
    expectNoStep();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // And the counted run begins where its length is known.
    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expectStep(1, 3);
  });

  testWidgets('adding a profile starts a fresh run at 1 of 3 — it inherits no '
      'numbers from the last one', (tester) async {
    final local = await store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'acc_solo', name: 'Solo Act', createdAtMs: 0)],
      activeId: 'acc_solo',
    ));
    await local.saveRelayJar(
      'acc_solo',
      const RelayJar(
        jarId: 'jar_1',
        tipUrl: 'https://live.tips/t/jar_1',
        artistName: 'Solo Act',
        currency: 'eur',
        revolutUsername: 'solo',
        createdAtMs: 0,
      ),
    );
    await pumpApp(tester, local);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a profile'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expectStep(1, 3);
  });
}
