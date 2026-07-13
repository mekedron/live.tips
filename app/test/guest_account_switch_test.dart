import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/features/settings/account_switch_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';

import 'helpers.dart';

/// An anonymous Firebase user has no credential: once its session is gone it
/// is gone for good. But switching the active PROFILE never ends a session —
/// so a guest account you switched away from is still right there, and coming
/// back to it is a directory flip, not a sign-in. Greying that row out on the
/// way out is what stranded the guest's profiles and its live tip jar.
const _guest = AuthUser(uid: 'uid_guest', kind: AccountKind.anonymous);

/// Named, so the row's own label can't be mistaken for the "Guest" provider
/// pill every anonymous row carries.
const _guestEntry = AppAccount(
  id: 'uid_guest',
  name: 'Nightbirds',
  kind: AccountKind.anonymous,
);

const _lockedSubtitle =
    "Signed out — a guest account can't be signed back into";

final _navigator = GlobalKey<NavigatorState>();

/// The switcher as it is really reached: pushed on top of Settings, so
/// switching away pops back to the screen underneath.
Future<ProviderContainer> _pumpSwitcher(
  WidgetTester tester, {
  required AuthUser? session,
  required String activeId,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final local = await seededStore();
  await local.saveAccountsDirectory(AccountsDirectory.initial()
      .withAccount(_guestEntry)
      .withActive(activeId));
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    initialApiKeyProvider.overrideWithValue(null),
    authServiceProvider.overrideWithValue(FakeAuthService(user: session)),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: _navigator,
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),
        theme: buildLightTheme(),
        home: const Scaffold(),
      ),
    ),
  );
  await _openSwitcher(tester);
  return container;
}

Future<void> _openSwitcher(WidgetTester tester) async {
  unawaited(_navigator.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const AccountSwitchScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a live guest session stays switchable — out to the local '
      'profile and back is a directory flip', (tester) async {
    final container =
        await _pumpSwitcher(tester, session: _guest, activeId: 'uid_guest');

    // Leave for the device-local profile.
    await tester.tap(find.text('On this device'));
    await tester.pumpAndSettle();
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
    expect(container.read(authControllerProvider).user?.uid, 'uid_guest',
        reason: 'switching profiles must not end the guest\'s session');

    // Come back to the switcher: the guest row is live, not a tombstone.
    await _openSwitcher(tester);
    expect(find.text(_lockedSubtitle), findsNothing,
        reason: 'its session is right there — nothing was signed out');

    await tester.tap(find.text('Nightbirds'));
    await tester.pumpAndSettle();
    expect(
        container.read(accountsDirectoryProvider).activeAccountId, 'uid_guest',
        reason: 'switching back needs no re-auth at all');
  });

  testWidgets('a guest whose session is really gone is disabled — but can be '
      'removed from the device', (tester) async {
    final container =
        await _pumpSwitcher(tester, session: null, activeId: kLocalAccountId);

    expect(find.text(_lockedSubtitle), findsOneWidget);

    // Disabled: tapping it does nothing.
    await tester.tap(find.text('Nightbirds'));
    await tester.pumpAndSettle();
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);

    // …but a dead row need not be forever.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Remove this guest account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(container.read(accountsDirectoryProvider).contains('uid_guest'),
        isFalse);
    expect(find.text('Nightbirds'), findsNothing);
  });
}
