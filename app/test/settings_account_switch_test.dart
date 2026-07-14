import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/onboarding/account_name_screen.dart';
import 'package:live_tips/features/settings/cloud_account_screen.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Settings has TWO doors, and each opens the sheet its label names (#49).
/// "Switch profile", in the profile group, opens the profiles of the account in
/// use. "Switch account", in the account group, opens the accounts. #29 deleted
/// the second row on the grounds that two rows opening the same sheet would be
/// the split redrawn — which was true of the sheet it left behind, one list
/// holding a mode, some profiles, an account and both doors. Two rows opening
/// two sheets that ask two different questions are not a split: they are the
/// two questions, asked apart, in one shape.
///
/// And the account can be NAMED here: the sign-up step always promised "you can
/// name the account later in Settings", and until then there was no such thing.

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
  testWidgets('Switch profile opens the PROFILES — and nothing else',
      (tester) async {
    await _pumpSettings(tester, user: _casey);

    expect(find.text('Switch profile'), findsOneWidget);

    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();

    // The profiles of the account in use, and the way to make another. Not the
    // device mode, not the account rows, not the sign-in door — every one of
    // which the merged sheet stood in this same column (#49).
    expect(find.text('Your profiles'), findsOneWidget);
    expect(find.text('Add a profile'), findsOneWidget);
    expect(find.text('On this device'), findsNothing);
    expect(find.text('Sign in to another account'), findsNothing);
  });

  testWidgets('Switch account opens the ACCOUNTS — the row #29 deleted, back '
      'because there is now a sheet for it to open', (tester) async {
    await _pumpSettings(tester, user: _casey);

    expect(find.text('Switch account'), findsOneWidget);
    // The two switch rows wear the SAME icon — the owner wants the account
    // switcher and the profile switcher to rhyme, so the pattern is
    // memorable: one icon, two questions.
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.switch_account_rounded), findsNothing);

    await tester.tap(find.text('Switch account'));
    await tester.pumpAndSettle();

    expect(find.text('Your accounts'), findsOneWidget);
    // The accounts this device knows, the mode that is not one, and the door to
    // an account it has never seen.
    expect(find.text('Casey'), findsWidgets);
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);
    // Not one profile: this sheet answers "whose profiles", not "which".
    expect(find.text('Add a profile'), findsNothing);
  });

  testWidgets('the identity row opens the account screen, and its own '
      'identity row the rename', (tester) async {
    await _pumpSettings(tester, user: _casey);

    // Settings' account row is now a door to the whole account page…
    await tester.tap(find.text('Casey'));
    await tester.pumpAndSettle();
    expect(find.byType(CloudAccountScreen), findsOneWidget);

    // …where the same identity row is the way to the name.
    await tester.tap(find.descendant(
      of: find.byType(CloudAccountScreen),
      matching: find.text('Casey'),
    ));
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
    expect(find.text('Anonymous cloud account'), findsOneWidget);
  });

  testWidgets('signed out: no account row to switch between — and the profile '
      'sheet\'s own door still reaches a sign-in', (tester) async {
    await _pumpSettings(tester, user: null);

    expect(find.text('Sign in / Create account'), findsOneWidget);
    // Nothing to switch BETWEEN: the account sheet would hold this device and
    // the sign-in offer the row above already makes, so the row stands aside
    // rather than promising a choice that does not exist.
    expect(find.text('Switch account'), findsNothing);

    // The way into an account is still one tap from the profiles — the door at
    // the foot of the sheet, which says what it opens.
    await tester.tap(find.text('Switch profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profiles'), findsOneWidget);

    await tester.tap(find.text('Switch account'));
    await tester.pumpAndSettle();
    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsOneWidget);
  });

  testWidgets('an account whose SESSION died keeps its row — and one tap '
      'signs it back in', (tester) async {
    // The row a deliberate sign-out no longer leaves behind (#31) is still
    // exactly right for the other thing: an expired slot, a revoked token, a
    // restart the session did not survive. The account is still this device's;
    // only its session is gone, and re-authenticating is the way back. It is an
    // ACCOUNT row, so it is in the account sheet (#49) — the rule is unchanged,
    // only the surface it is read on.
    final auth = FakeAuthService(nextUser: _casey);
    await _pumpSettings(tester, user: null, known: _casey, auth: auth);

    await tester.tap(find.text('Switch account'));
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
