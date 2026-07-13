import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Settings over a seeded store; [auth] null exercises the default
/// no-Firebase [authServiceProvider] (cloud section must vanish).
Future<void> _pumpSettings(WidgetTester tester, {AuthService? auth}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore();
  // An anonymous uid is an account only when the directory knows it (the
  // relay's transport sign-in is anonymous too, and stays invisible).
  final user = auth?.currentUser;
  if (user != null) {
    await localStore.saveAccountsDirectory(
      AccountsDirectory.initial().withAccount(
        AppAccount(
          id: user.uid,
          name: user.displayName ?? '',
          kind: user.kind,
          email: user.email,
        ),
      ),
    );
  }
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
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed out with auth available: the sign-in row shows', (
    tester,
  ) async {
    await _pumpSettings(tester, auth: FakeAuthService());

    // LtSectionLabel upper-cases the group header.
    expect(find.text('CLOUD ACCOUNT'), findsOneWidget);
    expect(find.text('Sign in / Create account'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('without Firebase the section hides entirely', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('CLOUD ACCOUNT'), findsNothing);
    expect(find.text('Sign in / Create account'), findsNothing);
  });

  testWidgets('signed in: name, provider · email, and a Sign out row', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: FakeAuthService(
        user: const AuthUser(
          uid: 'uid_1',
          kind: AccountKind.google,
          displayName: 'Casey',
          email: 'casey@example.com',
        ),
      ),
    );

    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Google · casey@example.com'), findsOneWidget);
    expect(find.text('Sign in / Create account'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);

    // Signing out asks first.
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
  });

  testWidgets('an anonymous account warns that sign-out loses access', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: FakeAuthService(
        user: const AuthUser(uid: 'anon_1', kind: AccountKind.anonymous),
      ),
    );

    expect(
      find.text(
        'This is a guest account — signing out permanently loses access to it.',
      ),
      findsOneWidget,
    );
  });
}
