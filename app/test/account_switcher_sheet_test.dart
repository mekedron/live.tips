import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/core/theme.dart';
import 'package:live_tips/data/firebase/auth_service.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/widgets/band_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Two local bands behind a button that opens the switcher sheet.
Future<void> _pumpAndOpen(WidgetTester tester, {AuthService? auth}) async {
  await tester.binding.setSurfaceSize(const Size(700, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await local.saveAccountsRegistry(
    const AccountsRegistry(
      accounts: [
        BandAccount(id: 'acc_a', name: 'Solo Act', createdAtMs: 0),
        BandAccount(id: 'acc_b', name: 'The Midnight Foxes', createdAtMs: 1),
      ],
      activeId: 'acc_a',
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(local),
        secureStoreProvider.overrideWithValue(FakeSecureStore()),
        initialApiKeyProvider.overrideWithValue(null),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
      ],
      child: MaterialApp(
        localizationsDelegates: kTestL10nDelegates,
        locale: const Locale('en'),

        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showBandSwitcherSheet(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('band rows and Add-band survive the account-grouped sheet', (
    tester,
  ) async {
    await _pumpAndOpen(tester);

    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('Solo Act'), findsOneWidget);
    expect(find.text('The Midnight Foxes'), findsOneWidget);
    expect(find.text('Add an account'), findsOneWidget);
    // The active profile header: no directory yet → the local profile.
    expect(find.text('On this device'), findsOneWidget);
    // No Firebase → no sign-in row.
    expect(find.text('Sign in to another account'), findsNothing);
  });

  testWidgets('with auth available the sign-in row appears', (tester) async {
    await _pumpAndOpen(tester, auth: FakeAuthService());

    expect(find.text('Sign in to another account'), findsOneWidget);
  });
}
