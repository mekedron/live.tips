import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/sign_in_methods_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// The section #32 asked for.
///
/// What is pinned here: linking UPGRADES a guest in place (same uid, same
/// profiles, same secrets — nothing migrates); unlinking the last permanent
/// method is refused, out loud, because it would put the account back to
/// unrecoverable. The exit #33 asked for — Delete account — used to live at
/// the bottom of this screen; it moved to Security (where an artist actually
/// looks for it), and its tests moved to security_screen_test.dart with it.

class _Harness {
  _Harness(this.store, this.secure);

  final LocalStore store;
  final FakeSecureStore secure;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required AuthUser user,
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
  // The band's Stripe key: it must survive a LINK untouched.
  final secure = FakeSecureStore({
    '${SecureStore.kApiKeyBase}_$kTestAccountId': 'sk_test_seeded',
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(secure),
        initialApiKeyProvider.overrideWithValue(null),
        authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
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
  return _Harness(localStore, secure);
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

  testWidgets('the delete no longer lives here — Security is its home now',
      (tester) async {
    await _pump(tester, user: _google);

    expect(find.text('Delete account'), findsNothing,
        reason: 'nobody thinking "delete my account" looks under sign-in '
            'methods; the act moved to Security, unchanged');
  });
}
