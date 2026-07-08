import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/app.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _relayCfg = RelayJar(
  jarId: 'jar_cfg',
  donateUrl: 'https://live.tips/t/jar_cfg',
  artistName: 'The Configured',
  currency: 'eur',
  revolutUsername: 'cfg',
  createdAtMs: 0,
);

/// A configured account plus a half-finished one (named on the details step,
/// no method, no data) that is active — the state after backing out of a new
/// account's onboarding.
Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final local = LocalStore(await SharedPreferences.getInstance());
  await local.saveAccountsRegistry(const AccountsRegistry(
    accounts: [
      BandAccount(id: 'acc_cfg', name: 'The Configured', createdAtMs: 0),
      BandAccount(id: 'acc_new', name: 'Half Done', createdAtMs: 1),
    ],
    activeId: 'acc_new',
  ));
  await local.saveRelayJar('acc_cfg', _relayCfg);
  return local;
}

void main() {
  testWidgets('switching away from an unfinished account offers to discard it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final local = await _store();
    final secure = FakeSecureStore({
      '${SecureStore.kRelaySecretBase}_acc_cfg': 'sec_cfg',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(local),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The active account is unfinished → RootGate shows Welcome, whose chip
    // opens the account switcher.
    await tester.tap(find.text('Half Done'));
    await tester.pumpAndSettle();

    expect(find.text('Your accounts'), findsOneWidget);
    await tester.tap(find.text('The Configured'));
    await tester.pumpAndSettle();

    // The discard warning, exactly as asked.
    expect(find.text('Discard this unfinished account?'), findsOneWidget);
    await tester.tap(find.text('Discard & switch'));
    await tester.pumpAndSettle();

    // The unfinished account is gone; only the configured one remains active.
    final registry = local.readAccountsRegistry()!;
    expect(registry.accounts, hasLength(1));
    expect(registry.accounts.single.id, 'acc_cfg');
    expect(registry.activeId, 'acc_cfg');
  });

  testWidgets('keeping the unfinished account cancels the switch',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final local = await _store();
    final secure = FakeSecureStore({
      '${SecureStore.kRelaySecretBase}_acc_cfg': 'sec_cfg',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(local),
          secureStoreProvider.overrideWithValue(secure),
          initialApiKeyProvider.overrideWithValue(null),
        ],
        child: const LiveTipsApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Half Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Configured'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    // Nothing removed, still on the unfinished account.
    final registry = local.readAccountsRegistry()!;
    expect(registry.accounts, hasLength(2));
    expect(registry.activeId, 'acc_new');
  });
}
