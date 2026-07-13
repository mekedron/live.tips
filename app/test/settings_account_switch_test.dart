import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/account_name_screen.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Settings has ONE door to the switcher now (#29): "Switch profile" opens the
/// one surface, and it lists the accounts too. The "Switch account" row — the
/// second door, to the second switcher — is gone; two rows opening the same
/// sheet would be the same split, redrawn. And the account can be NAMED here:
/// the sign-up step always promised "you can name the account later in
/// Settings", and until then there was no such thing.

/// [user] is signed in and active. [known] is an account the DIRECTORY knows
/// while nothing is signed in — a session that died on its own, which is a
/// different thing from a sign-out and keeps its switcher row.
Future<void> _pumpSettings(
  WidgetTester tester, {
  required AuthUser? user,
  AuthUser? known,
  AuthService? auth,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final local = await seededStore();
  final entry = user ?? known;
  if (entry != null) {
    // Signed in AND active — the state a real sign-in leaves behind.
    await local.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(AppAccount(
            id: entry.uid,
            name: entry.displayName ?? '',
            kind: entry.kind,
            email: entry.email,
          ))
          .withActive(user != null ? entry.uid : kLocalAccountId),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider
            .overrideWithValue(auth ?? FakeAuthService(user: user)),
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
  testWidgets('one switcher, one row: Switch profile opens the accounts too',
      (tester) async {
    await _pumpSettings(tester, user: _casey);

    expect(find.text('Switch profile'), findsOneWidget);
    expect(find.text('Switch account'), findsNothing,
        reason: 'the second door to the second switcher is gone (#29)');

    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();

    // The one surface: the device's own profiles, the accounts this device
    // knows, and the door to a new sign-in — all of it in the sheet the header
    // tap opens too.
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Casey'), findsWidgets);
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

  testWidgets('signed out: the sign-in row, and the switcher still opens',
      (tester) async {
    await _pumpSettings(tester, user: null);

    expect(find.text('Sign in / Create account'), findsOneWidget);
    // The switcher is never a door to an empty room: with no account at all it
    // still holds this device's profiles, and the way into an account.
    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);
  });

  testWidgets('an account whose SESSION died keeps its row — and one tap '
      'signs it back in', (tester) async {
    // The row a deliberate sign-out no longer leaves behind (#31) is still
    // exactly right for the other thing: an expired slot, a revoked token, a
    // restart the session did not survive. The account is still this device's;
    // only its session is gone, and re-authenticating is the way back.
    final auth = FakeAuthService(nextUser: _casey);
    await _pumpSettings(tester, user: null, known: _casey, auth: auth);

    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();

    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Session ended — selecting it signs in again'),
        findsOneWidget);

    await tester.tap(find.text('Casey'));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.uid, 'uid_1',
        reason: 'the dead row re-runs the provider sign-in');
  });
}
