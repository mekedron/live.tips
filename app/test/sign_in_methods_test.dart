import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/account_service.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/sign_in_methods_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The section #32 asked for, and the exit #33 asked for.
///
/// What is pinned here: linking UPGRADES a guest in place (same uid, same
/// profiles, same secrets — nothing migrates); unlinking the last permanent
/// method is refused, out loud, because it would put the account back to
/// unrecoverable; and the delete does nothing at all until the word is typed —
/// then it calls the server, and only then does this device let go of its
/// copy.

/// The deleteAccount callable, recorded. [stranded] models the one residue the
/// server cannot clear: an endpoint the artist's Stripe account kept.
class FakeAccountService extends AccountService {
  FakeAccountService({this.stranded = const [], this.error});

  final List<String> stranded;
  final AccountCallError? error;
  int calls = 0;

  @override
  Future<List<String>> deleteAccount() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return stranded;
  }
}

class _Harness {
  _Harness(this.store, this.secure, this.account);

  final LocalStore store;
  final FakeSecureStore secure;
  final FakeAccountService account;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required AuthUser user,
  FakeAccountService? account,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore(bandName: 'The Midnight Foxes');
  // A cloud profile the device knows AND is looking at — Settings (and this
  // screen) are about the active profile.
  await localStore.saveAccountsDirectory(
    AccountsDirectory.initial()
        .withAccount(AppAccount(
          id: user.uid,
          name: user.displayName ?? '',
          kind: user.kind,
          email: user.email,
        ))
        .withActive(user.uid),
  );
  // The band's Stripe key: it must survive a LINK untouched, and go with a
  // delete.
  final secure = FakeSecureStore({
    '${SecureStore.kApiKeyBase}_$kTestAccountId': 'sk_test_seeded',
  });
  final service = account ?? FakeAccountService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(secure),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
        accountServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const SignInMethodsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(localStore, secure, service);
}

const _guest = AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous);

const _google = AuthUser(
  uid: 'uid_1',
  kind: AccountKind.google,
  displayName: 'Casey',
  email: 'casey@example.com',
  providers: [AccountKind.google],
);

void main() {
  testWidgets(
      'a guest is told what it is missing, and linking upgrades the account '
      'IN PLACE — same uid, same profiles, same keys', (tester) async {
    final harness = await _pump(tester, user: _guest);

    // The honest warning the sign-out dialog used to be the only place to see.
    expect(find.textContaining('no way to sign back in'), findsOneWidget);
    expect(find.text('Not linked'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(TextButton, 'Link').last);
    await tester.pumpAndSettle();

    // Same account, upgraded: the uid never moved, and the directory row now
    // says how you get back in.
    final directory = harness.store.readAccountsDirectory()!;
    expect(directory.accounts.map((a) => a.id), contains('uid_guest'));
    expect(
      directory.accounts.firstWhere((a) => a.id == 'uid_guest').kind,
      AccountKind.google,
      reason: 'the guest uid became a Google account — not a second account',
    );
    expect(directory.activeAccountId, 'uid_guest');
    // Nothing was migrated, because nothing had to be.
    expect(harness.store.readAccountsRegistry()!.accounts.single.name,
        'The Midnight Foxes');
    expect(await harness.secure.readApiKey(kTestAccountId), 'sk_test_seeded');
    expect(find.text('Linked'), findsOneWidget);
    expect(find.textContaining('Same account, same profiles'), findsOneWidget);
  });

  testWidgets('unlinking the only method is refused, and says why',
      (tester) async {
    final harness = await _pump(tester, user: _google);

    await tester.tap(find.widgetWithText(TextButton, 'Unlink'));
    await tester.pumpAndSettle();

    // Not a disabled button with no explanation: the refusal names the reason,
    // because the artist asked for something perfectly reasonable.
    expect(find.text("That's the only way back in"), findsOneWidget);
    expect(find.textContaining('no sign-in method at all'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    // Still linked — Firebase would have done it; we would not.
    expect(find.text('Linked'), findsOneWidget);
    expect(
      harness.store
          .readAccountsDirectory()!
          .accounts
          .firstWhere((a) => a.id == 'uid_1')
          .kind,
      AccountKind.google,
    );
  });

  testWidgets('with a second method attached, unlinking is allowed',
      (tester) async {
    await _pump(
      tester,
      user: const AuthUser(
        uid: 'uid_1',
        kind: AccountKind.apple,
        providers: [AccountKind.apple, AccountKind.google],
      ),
    );

    expect(find.text('Linked'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(TextButton, 'Unlink').first);
    await tester.pumpAndSettle();

    expect(find.text('Unlink Apple?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Unlink'));
    await tester.pumpAndSettle();

    expect(find.text('Apple unlinked.'), findsOneWidget);
    expect(find.text('Linked'), findsOneWidget); // Google's, still there
  });

  testWidgets('deleting the account does nothing until the word is typed',
      (tester) async {
    final harness = await _pump(tester, user: _google);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();

    // The confirmation is proportional: it names what goes AND what stays.
    expect(find.text('Delete this account?'), findsOneWidget);
    expect(find.textContaining('the tip.live.tips links stop working'),
        findsOneWidget);
    expect(find.textContaining('live in YOUR Stripe account'), findsOneWidget);

    // Armed only by the exact word — a stray tap deletes nothing.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete forever'),
    );
    expect(button.onPressed, isNull);
    expect(harness.account.calls, 0);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Delete forever'))
          .onPressed,
      isNull,
      reason: 'the word must match exactly',
    );

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();

    // The server erases the account; the device lets go of its copy only then.
    expect(harness.account.calls, 1);
    expect(harness.store.readAccountsDirectory()!.contains('uid_1'), isFalse);
    expect(await harness.secure.readApiKey(kTestAccountId), isNull);
    expect(find.text('Your account and everything in it are gone.'),
        findsOneWidget);
  });

  testWidgets('a refused delete keeps the account, and never claims otherwise',
      (tester) async {
    final harness = await _pump(
      tester,
      user: _google,
      account: FakeAccountService(
        error: const AccountCallError(AccountCallErrorKind.unauthenticated),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();

    // A stale session is the ONE refusal with a fix the artist can act on.
    expect(find.textContaining('Sign in again'), findsOneWidget);
    // And nothing local was touched: the account still exists.
    expect(harness.store.readAccountsDirectory()!.contains('uid_1'), isTrue);
    expect(await harness.secure.readApiKey(kTestAccountId), 'sk_test_seeded');
  });

  testWidgets('an endpoint Stripe kept is named, not swallowed', (tester) async {
    await _pump(
      tester,
      user: _google,
      account: FakeAccountService(stranded: const ['we_left_behind']),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete forever'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('could not be removed from your Stripe account'),
      findsOneWidget,
    );
  });
}
