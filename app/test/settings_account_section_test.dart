import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/account/cloud_upload_offer.dart';
import 'package:live_tips/features/settings/cloud_account_screen.dart';
import 'package:live_tips/features/settings/settings_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// Settings over a seeded store; [auth] null exercises the default
/// no-Firebase [authServiceProvider] (cloud section must vanish). A non-null
/// [uploads] wires a recording cloud-upload runner in (the move row hides
/// without one); [bandName] names the seeded local band — a NAMED band is
/// one worth moving.
Future<void> _pumpSettings(
  WidgetTester tester, {
  AuthService? auth,
  String bandName = '',
  List<String>? uploads,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final localStore = await seededStore(bandName: bandName);
  // An anonymous uid is an account only when the directory knows it (the
  // relay's transport sign-in is anonymous too, and stays invisible).
  final user = auth?.currentUser;
  if (user != null) {
    // …and it is the ACTIVE profile — what a real sign-in leaves behind
    // (AuthController._adopt upserts, then activates). Settings is about the
    // active profile, not about whichever session happens to be alive.
    await localStore.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(
            AppAccount(
              id: user.uid,
              name: user.displayName ?? '',
              kind: user.kind,
              email: user.email,
            ),
          )
          .withActive(user.uid),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(SecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
        if (uploads != null)
          cloudUploadRunnerProvider.overrideWithValue((uid, {selectedBandIds, onProgress}) async {
            uploads.add(uid);
            return null;
          }),
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

/// The account's own actions (name, sign-in methods, security, move, sign
/// out) now live one level in, behind the signed-in row — Settings itself
/// carries only that row and "Switch account".
Future<void> _openAccountScreen(WidgetTester tester) async {
  await tester.tap(find.descendant(
    of: find.byType(SettingsScreen),
    matching: find.byIcon(Icons.account_circle_rounded),
  ));
  await tester.pumpAndSettle();
  expect(find.byType(CloudAccountScreen), findsOneWidget);
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

  testWidgets('signed in: name, provider · email — and Sign out one level in', (
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
    // Two rows on Settings itself; the account's own actions moved behind
    // the signed-in row.
    expect(find.text('Sign out'), findsNothing);

    await _openAccountScreen(tester);
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
    await _openAccountScreen(tester);

    expect(
      find.text(
        'This is a guest account — signing out permanently loses access to it.',
      ),
      findsOneWidget,
    );
  });

  // #32/#33: a permanent section, for any signed-in cloud account — the link
  // offer used to exist ONLY inside the sign-out dialog, and the delete
  // nowhere at all.

  testWidgets('signed in: the sign-in methods row is always there', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: FakeAuthService(
        user: const AuthUser(
          uid: 'uid_1',
          kind: AccountKind.google,
          displayName: 'Casey',
          providers: [AccountKind.google],
        ),
      ),
    );
    await _openAccountScreen(tester);

    expect(find.text('Sign-in methods'), findsOneWidget);
    expect(find.text('How you get back into this account'), findsOneWidget);
  });

  testWidgets('a guest account is told, on the row itself, what it lacks', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: FakeAuthService(
        user: const AuthUser(uid: 'anon_1', kind: AccountKind.anonymous),
      ),
    );
    await _openAccountScreen(tester);

    expect(
      find.text('Guest account — nothing can sign it back in'),
      findsOneWidget,
    );
  });

  // The permanent door #25 asked for: the sign-in offer is one-shot per
  // profile, so a local profile created after that answer needs a home in
  // Settings that is ALWAYS there while a local profile and a signed-in
  // account coexist.

  testWidgets(
      'signed in beside a local profile worth moving: the move row shows '
      'and runs the migrator', (tester) async {
    final uploads = <String>[];
    await _pumpSettings(
      tester,
      auth: FakeAuthService(
        user: const AuthUser(
          uid: 'uid_1',
          kind: AccountKind.google,
          displayName: 'Casey',
        ),
      ),
      bandName: 'Solo Act',
      uploads: uploads,
    );
    await _openAccountScreen(tester);

    await tester.tap(find.text('Move profiles into this account'));
    await tester.pumpAndSettle();
    // The same question the sign-in offer asks — walked up to, not waited on.
    expect(find.text('Move your profiles to this account?'), findsOneWidget);

    await tester.tap(find.text('Move profiles'));
    await tester.pumpAndSettle();

    expect(uploads, ['uid_1']);
    expect(
        find.text('Your profiles now live in your account.'), findsOneWidget);
  });

  testWidgets('a pristine placeholder profile earns no move row', (
    tester,
  ) async {
    // Unnamed and holding no data: noise, not value — same rule as the
    // sign-in offer.
    await _pumpSettings(
      tester,
      auth: FakeAuthService(
        user: const AuthUser(
          uid: 'uid_1',
          kind: AccountKind.google,
          displayName: 'Casey',
        ),
      ),
      uploads: <String>[],
    );
    await _openAccountScreen(tester);

    expect(find.text('Move profiles into this account'), findsNothing);
  });

  testWidgets('signed out: no move row — there is no account to move into', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      auth: FakeAuthService(),
      bandName: 'Solo Act',
      uploads: <String>[],
    );

    expect(find.text('Move profiles into this account'), findsNothing);
  });
}
