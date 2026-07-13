import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/features/home/setup_home_screen.dart';
import 'package:live_tips/features/onboarding/welcome_screen.dart';
import 'package:live_tips/features/shell/app_shell.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// The soft-lock this file exists for: a user who signs in halfway through
/// onboarding lands in a cloud account with zero bands. Welcome has no shell —
/// no switcher, no Settings, no sign-out — so that used to be a room with no
/// door, surviving a reload, with the user's local bands invisible behind it.
///
/// Welcome is now the genuinely-first-run screen and nothing else; every other
/// "nothing set up yet" state renders inside the shell.

const _jar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'The Configured',
  currency: 'eur',
  revolutUsername: 'cfg',
  createdAtMs: 0,
);

Future<void> _pumpApp(
  WidgetTester tester,
  LocalStore local, {
  AuthService? auth,
}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
      ],
      child: const LiveTipsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('a genuinely fresh device still gets the Welcome pitch',
      (tester) async {
    await _pumpApp(tester, await _store());

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('signed in with no band at all: the shell, not Welcome',
      (tester) async {
    final local = await _store();
    const user = AuthUser(
      uid: 'uid_cloud',
      kind: AccountKind.google,
      displayName: 'Casey',
    );
    // The state after a mid-onboarding sign-in: a cloud profile is active and
    // it owns nothing yet.
    await local.saveAccountsDirectory(
      AccountsDirectory.initial()
          .withAccount(const AppAccount(
            id: 'uid_cloud',
            name: 'Casey',
            kind: AccountKind.google,
          ))
          .withActive('uid_cloud'),
    );
    await _pumpApp(tester, local, auth: FakeAuthService(user: user));

    // Reachable: the empty-state home, the switcher, and Settings — the way
    // back out of a profile that has nothing in it.
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(SetupHomeScreen), findsOneWidget);
    expect(find.text('This profile has no payment method yet'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('an unconfigured band next to a configured one: the shell',
      (tester) async {
    final local = await _store();
    await local.saveAccountsRegistry(const AccountsRegistry(
      accounts: [
        BandAccount(id: 'acc_cfg', name: 'The Configured', createdAtMs: 0),
        BandAccount(id: 'acc_new', name: 'Half Done', createdAtMs: 1),
      ],
      activeId: 'acc_new',
    ));
    await local.saveRelayJar('acc_cfg', _jar);

    await _pumpApp(tester, local);

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(SetupHomeScreen), findsOneWidget);
  });

  testWidgets('a signed-out device that knows a cloud account: the shell',
      (tester) async {
    // Signed out of a cloud account this device has used. Welcome would hide
    // Settings — and with it the only way back into that account.
    final local = await _store();
    await local.saveAccountsDirectory(
      AccountsDirectory.initial().withAccount(const AppAccount(
        id: 'uid_cloud',
        name: 'Casey',
        kind: AccountKind.google,
      )),
    );

    await _pumpApp(tester, local);

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(SetupHomeScreen), findsOneWidget);
  });
}
