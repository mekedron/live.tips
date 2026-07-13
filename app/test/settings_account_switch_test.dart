import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/account_name_screen.dart';
import 'package:live_tips/features/settings/account_switch_screen.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Account switching lives in Settings now — its own deliberate act, apart
/// from picking tonight's profile. And the account can finally be NAMED: the
/// sign-up step always promised "you can name the account later in Settings",
/// and until now there was no such thing.

Future<void> _pumpSettings(WidgetTester tester, {required AuthUser? user}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final local = await seededStore();
  if (user != null) {
    // Signed in AND active — the state a real sign-in leaves behind.
    await local.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(AppAccount(
            id: user.uid,
            name: user.displayName ?? '',
            kind: user.kind,
            email: user.email,
          ))
          .withActive(user.uid),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
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

const _casey = AuthUser(
  uid: 'uid_1',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
);

void main() {
  testWidgets('the cloud section offers Switch account', (tester) async {
    await _pumpSettings(tester, user: _casey);

    expect(find.text('Switch account'), findsOneWidget);
    // And the profile group keeps its own, differently-named switch.
    expect(find.text('Switch profile'), findsOneWidget);

    await tester.tap(find.text('Switch account'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSwitchScreen), findsOneWidget);
    // The known accounts, the local "no account" profile included, plus the
    // door to a new sign-in — everything the profile switcher no longer shows.
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);
  });

  testWidgets('the identity row opens the account rename screen',
      (tester) async {
    await _pumpSettings(tester, user: _casey);

    await tester.tap(find.text('Casey'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountNameScreen), findsOneWidget);
    expect(find.text('Name this account'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    // Prefilled with the name the account already answers to — an empty field
    // reads as "your name is gone".
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Casey',
    );
  });

  testWidgets('the sign-in sheet offers a guest account too', (tester) async {
    await _pumpSettings(tester, user: null);

    await tester.tap(find.text('Sign in / Create account'));
    await tester.pumpAndSettle();

    // Apple, Google — and the door that used to exist only at first run: a
    // local artist could never start a guest account afterwards.
    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Use without sign-in'), findsOneWidget);
  });

  testWidgets('signed out with only the local account: no switch row',
      (tester) async {
    await _pumpSettings(tester, user: null);

    expect(find.text('Sign in / Create account'), findsOneWidget);
    // Nowhere to switch to — the row would be a door to an empty room.
    expect(find.text('Switch account'), findsNothing);
  });
}
