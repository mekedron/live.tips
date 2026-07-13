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
  testWidgets('the sheet lists this account\'s profiles and Add a profile', (
    tester,
  ) async {
    await _pumpAndOpen(tester);

    expect(find.text('Your profiles'), findsOneWidget);
    expect(find.text('Solo Act'), findsOneWidget);
    expect(find.text('The Midnight Foxes'), findsOneWidget);
    expect(find.text('Add a profile'), findsOneWidget);
    // The header names the ACCOUNT these profiles live under (no directory
    // yet → the local one). It is a label, not a switch.
    expect(find.text('On this device'), findsOneWidget);
  });

  testWidgets('cloud accounts never appear in the profile switcher', (
    tester,
  ) async {
    // Auth available and signed in — and the sheet STILL only talks about
    // profiles. Account switching is Settings' job now: one sheet that mixed
    // both is how "switch band" turned into "sign into another account".
    await _pumpAndOpen(tester, auth: FakeAuthService());

    expect(find.text('Your profiles'), findsOneWidget);
    expect(find.text('Sign in to another account'), findsNothing);
    expect(find.text('Other accounts'), findsNothing);
  });
}
