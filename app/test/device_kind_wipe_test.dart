import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/account_sessions.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/app_account.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';

import 'helpers.dart';

/// Changing what a device is wipes it — ALL of it: sessions, directory,
/// profiles, secrets, the venue record, the kind itself.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wipeDevice signs everything out and erases every local trace',
      () async {
    final store = await seededStore(
      values: {LocalStore.kDeviceKind: 'performer'},
      bandName: 'The Foxes',
      accountValues: {LocalStore.kTipJarBase: '{"id":"jar_1"}'},
    );
    final secure = FakeSecureStore({
      'stripe_api_key_$kTestAccountId': 'rk_live_secret',
      'relay_jar_secret_$kTestAccountId': 'relay_secret',
    });

    // One cloud account signed in, in its own slot.
    var slots = <String, String>{};
    final sessions = AccountSessions(
      readSlots: () => slots,
      saveSlots: (next) async => slots = Map.of(next),
      openApp: (name) async => SessionHandles(
          auth: MockFirebaseAuth(), firestore: FakeFirebaseFirestore()),
      closeApp: (_) async {},
    );
    final pending = await sessions.begin();
    await (pending.auth as MockFirebaseAuth).signInWithCustomToken('t');
    final live = await sessions.commit(pending, 'uid_cloud');

    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(secure),
      accountSessionsProvider.overrideWithValue(sessions),
    ]);
    addTearDown(container.dispose);

    await container.read(accountsDirectoryProvider.notifier).upsert(
        const AppAccount(
            id: 'uid_cloud', name: 'Cloud', kind: AccountKind.google));
    expect(container.read(deviceKindProvider), DeviceKind.performer);

    await container.read(deviceKindProvider.notifier).wipeDevice();

    // Every account signed out of its own instance.
    expect(sessions.liveUids, isEmpty);
    expect(live.auth.currentUser, isNull);
    // Every cached secret gone.
    expect(secure.values, isEmpty);
    // Every local profile and blob gone; the kind cleared — back to
    // onboarding, where the device is chosen again.
    expect(store.readAccountsRegistry(), isNull);
    expect(store.readTipJar(kTestAccountId), isNull);
    expect(store.readDeviceKind(), isNull);
    expect(store.readVenueSession(), isNull);
    expect(container.read(deviceKindProvider), isNull);
    expect(container.read(accountsDirectoryProvider).accounts.length, 1,
        reason: 'only the permanent local profile remains');
    expect(container.read(accountsDirectoryProvider).activeAccountId,
        kLocalAccountId);
  });
}
