import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/account_name_screen.dart';
import 'package:live_tips/features/onboarding/account_step_screen.dart';
import 'package:live_tips/features/onboarding/onboarding_details_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Pumps the account step over a seeded store. [auth] defaults to a
/// [FakeAuthService] (available, signed out); pass null to exercise the
/// no-Firebase fallback of the default [authServiceProvider].
Future<void> _pump(WidgetTester tester, {AuthService? auth}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(SecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),

        theme: buildLightTheme(),
        home: const AccountStepScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all four account choices', (tester) async {
    await _pump(tester, auth: FakeAuthService());

    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Anonymous cloud account'), findsOneWidget);
    expect(find.text('Continue without an account'), findsOneWidget);
  });

  testWidgets('continue without account routes to the details step', (
    tester,
  ) async {
    await _pump(tester, auth: FakeAuthService());

    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
  });

  testWidgets('a sign-in without a name pushes the account naming step', (
    tester,
  ) async {
    await _pump(
      tester,
      auth: FakeAuthService(
        nextUser: const AuthUser(uid: 'anon_1', kind: AccountKind.anonymous),
      ),
    );

    await tester.tap(find.text('Anonymous cloud account'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountNameScreen), findsOneWidget);
  });

  testWidgets('a sign-in that already has a name skips straight to details', (
    tester,
  ) async {
    await _pump(tester, auth: FakeAuthService());

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expect(find.byType(AccountNameScreen), findsNothing);
  });

  testWidgets('without cloud accounts the step forwards itself to details', (
    tester,
  ) async {
    // No authServiceProvider override → AuthService(null) → unavailable.
    await _pump(tester);

    expect(find.byType(OnboardingDetailsScreen), findsOneWidget);
    expect(find.byType(AccountStepScreen), findsNothing);
  });
}
