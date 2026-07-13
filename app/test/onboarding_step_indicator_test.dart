import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/onboarding_draft.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The owner's complaint, fixed: the account step and the account-name step
/// carry step pills like the rest of onboarding, and once a total has been
/// shown it never shrinks on the way Back.
void main() {
  test('the prelude only ever grows within a run, and resets between runs',
      () async {
    final store = await seededStore();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(FakeSecureStore()),
    ]);
    addTearDown(container.dispose);

    final prelude = container.read(onboardingPreludeProvider.notifier);
    expect(container.read(onboardingPreludeProvider), 0);
    prelude.markAccountStep();
    expect(container.read(onboardingPreludeProvider), 1);
    prelude.markNameStep();
    expect(container.read(onboardingPreludeProvider), 2);
    // Going Back re-marks the earlier step — the count must not shrink.
    prelude.markAccountStep();
    expect(container.read(onboardingPreludeProvider), 2);
    prelude.reset();
    expect(container.read(onboardingPreludeProvider), 0);
  });

  testWidgets(
      'account and name steps are numbered, and the totals carry into the '
      'band steps', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await seededStore();
    // A guest sign-in with no display name — the flow that shows BOTH
    // account-flavored steps.
    final auth = FakeAuthService(
      nextUser: const AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          secureStoreProvider.overrideWithValue(FakeSecureStore()),
          initialApiKeyProvider.overrideWithValue(null),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // The account question is step 1 — with a pill, like every other step.
    expect(find.text('First, an account'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Use without sign-in'));
    await tester.pumpAndSettle();

    // The name step revealed itself: step 2, total grown — never shrunk.
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Step 2 of 5'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Details is step 3 of the same 5 — the account steps stay counted.
    expect(find.text("Let's set up your tip jar"), findsOneWidget);
    expect(find.text('Step 3 of 5'), findsOneWidget);

    // Back to the name step: the numbering holds, nothing shrinks.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 5'), findsOneWidget);
  });
}
