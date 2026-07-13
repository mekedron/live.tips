import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/account_sessions.dart';
import 'package:live_tips/data/local_cipher.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/secure_store.dart';
import 'package:live_tips/data/venue_boot.dart';
import 'package:live_tips/domain/band_account.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/features/venue/venue_boot_blocked_screen.dart';
import 'package:live_tips/state/auth_providers.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A venue boot whose cipher can't attach is a STOP, not a run-degraded
/// condition: nothing seeded, nothing minted, nothing overwritten. These are
/// the boots the suite never had — a keychain that throws, and a root key
/// that is gone while the envelopes remain (what a backup restore looks
/// like) — the exact states in which the old boot rotated the device id and
/// wrote plaintext over the encrypted registry.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A venue device that has really lived: cipher attached, device id
  /// minted, a session and the registries recorded — everything on disk an
  /// envelope. The returned prefs are what the next boot finds.
  Future<({SharedPreferences prefs, String rootKey, String deviceId})>
      livedInVenuePrefs() async {
    SharedPreferences.setMockInitialValues(
        {LocalStore.kDeviceKind: 'venue'});
    final prefs = await SharedPreferences.getInstance();
    final rootKey = LocalCipher.newRootKey();
    final warm = LocalStore(prefs)..cipher = LocalCipher(rootKey);
    final deviceId = warm.deviceId();
    await warm.saveVenueSession(VenueSession(
      uid: 'uid_v',
      startedAtMs: 1000,
      expiresAtMs: 1000 + const Duration(hours: 12).inMilliseconds,
      identityConfirmed: true,
    ));
    await warm.saveAccountSessionSlots({'uid_v': 'slot_0'});
    await warm.saveAccountsRegistry(const AccountsRegistry(
      accounts: [BandAccount(id: 'band_1', name: 'The Foxes', createdAtMs: 0)],
      activeId: 'band_1',
    ));
    return (prefs: prefs, rootKey: rootKey, deviceId: deviceId);
  }

  Map<String, Object?> snapshotOf(SharedPreferences prefs) =>
      {for (final key in prefs.getKeys()) key: prefs.get(key)};

  test('a throwing keychain stops the boot and touches nothing', () async {
    final device = await livedInVenuePrefs();
    final before = snapshotOf(device.prefs);
    // The reboot: a fresh store over the same prefs, no cipher yet.
    final store = LocalStore(device.prefs);
    final secure = FakeSecureStore(
        {SecureStore.kLocalCipherKey: device.rootKey})
      ..failing = true;

    expect(await attachVenueCipher(store, secure),
        VenueBootBlock.keychainUnavailable);
    expect(snapshotOf(device.prefs), before,
        reason: 'a blocked boot changes nothing on disk');
  });

  test('a missing root key with envelopes on disk is a restore, not a first run',
      () async {
    final device = await livedInVenuePrefs();
    final before = snapshotOf(device.prefs);
    final store = LocalStore(device.prefs);
    // The keychain answers fine — the key just didn't come along.
    final secure = FakeSecureStore();

    expect(await attachVenueCipher(store, secure),
        VenueBootBlock.rootKeyMissing);
    expect(secure.values, isEmpty,
        reason: 'minting a fresh root key over existing envelopes is the '
            'silent-total-data-loss path — every envelope would fail its MAC');
    expect(snapshotOf(device.prefs), before);
  });

  test('a genuinely fresh venue device still onboards: key minted, writes encrypted',
      () async {
    SharedPreferences.setMockInitialValues(
        {LocalStore.kDeviceKind: 'venue'});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final secure = FakeSecureStore();

    expect(await attachVenueCipher(store, secure), isNull);
    expect(secure.values[SecureStore.kLocalCipherKey], isNotNull,
        reason: 'the key is parked in the keychain before the cipher attaches');
    final id = store.deviceId();
    expect(prefs.getString('device_id_v1'), startsWith(LocalCipher.prefix),
        reason: 'everything the venue writes is an envelope');
    expect(store.deviceId(), id, reason: 'the id is stable, never re-minted');
  });

  test('an existing root key attaches and reads everything back — no rotation',
      () async {
    final device = await livedInVenuePrefs();
    final store = LocalStore(device.prefs);
    final secure =
        FakeSecureStore({SecureStore.kLocalCipherKey: device.rootKey});

    expect(await attachVenueCipher(store, secure), isNull);
    expect(store.deviceId(), device.deviceId,
        reason: 'device registry, leases and revocation keep their id');
    expect(store.readVenueSession()?.uid, 'uid_v',
        reason: 'the 12-hour ceiling has its record to re-arm from');
    expect(store.readAccountSessionSlots(), {'uid_v': 'slot_0'},
        reason: 'persisted auth sessions are revivable again');
  });

  test('a root key that cannot be persisted blocks too — an envelope must '
      'never outlive its key', () async {
    SharedPreferences.setMockInitialValues(
        {LocalStore.kDeviceKind: 'venue'});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final secure = _WriteFailingSecureStore();

    // Attaching a cipher whose key exists nowhere but memory would make
    // this boot's writes unreadable forever after the next restart.
    expect(await attachVenueCipher(store, secure),
        VenueBootBlock.keychainUnavailable);
  });

  test('without the cipher, plaintext never overwrites an envelope', () async {
    final device = await livedInVenuePrefs();
    final store = LocalStore(device.prefs); // cipher never attached
    final rawId = device.prefs.getString('device_id_v1');

    // (a) of the bug: the id read as absent, so a new one was minted and
    // written in plaintext over the encrypted one. Now it fails loudly.
    expect(store.deviceId, throwsStateError);
    expect(device.prefs.getString('device_id_v1'), rawId,
        reason: 'the envelope survives the refused write');

    // (b): the seeding path used to overwrite the encrypted registry.
    expect(
        () => store.saveAccountsRegistry(const AccountsRegistry(
              accounts: [BandAccount(id: 'band_2', name: '', createdAtMs: 0)],
              activeId: 'band_2',
            )),
        throwsStateError);
  });

  test('choosing venue mode with a dead keychain refuses — the kind stays unset',
      () async {
    final store = await seededStore();
    final secure = FakeSecureStore()..failing = true;
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(secure),
    ]);
    addTearDown(container.dispose);

    await expectLater(
        container.read(deviceKindProvider.notifier).choose(DeviceKind.venue),
        throwsStateError);
    expect(store.readDeviceKind(), isNull,
        reason: 'a venue install without its cipher must not exist');
    expect(container.read(deviceKindProvider), isNull);
  });

  test('choosing venue mode on a fresh device attaches the cipher before the '
      'kind saves', () async {
    final store = await seededStore();
    final secure = FakeSecureStore();
    final container = ProviderContainer(overrides: [
      localStoreProvider.overrideWithValue(store),
      secureStoreProvider.overrideWithValue(secure),
      accountSessionsProvider.overrideWithValue(AccountSessions.unavailable()),
    ]);
    addTearDown(container.dispose);

    await container.read(deviceKindProvider.notifier).choose(DeviceKind.venue);
    expect(store.readDeviceKind(), DeviceKind.venue);
    expect(secure.values[SecureStore.kLocalCipherKey], isNotNull);
    // Everything the venue writes from here on is an envelope.
    await store.saveVenueSession(const VenueSession(
        uid: 'uid_v', startedAtMs: 0, expiresAtMs: 1));
    expect(store.prefs.getString('venue_session_v1'),
        startsWith(LocalCipher.prefix));
  });

  testWidgets('the locked-keychain boot lands on a blocking screen with a retry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(VenueBootBlockedApp(
      block: VenueBootBlock.keychainUnavailable,
      locale: const Locale('en'),
      onRetry: () => retried = true,
      onErase: () async {},
    ));
    expect(find.text('Secure storage is unavailable'), findsOneWidget);
    expect(find.text('Erase and start over'), findsNothing,
        reason: 'a transient lock must not invite an erase');
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('the restore boot explains itself, and erases only after a confirm',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var erased = false;
    await tester.pumpWidget(VenueBootBlockedApp(
      block: VenueBootBlock.rootKeyMissing,
      locale: const Locale('en'),
      onRetry: () {},
      onErase: () async => erased = true,
    ));
    expect(find.text("This device's data can't be unlocked"), findsOneWidget);

    await tester.tap(find.text('Erase and start over'));
    await tester.pumpAndSettle();
    expect(find.text('Erase this device?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(erased, isFalse, reason: 'backing out erases nothing');

    await tester.tap(find.text('Erase and start over'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erase everything'));
    await tester.pumpAndSettle();
    expect(erased, isTrue);
  });
}

/// The keychain that reads fine but loses the write — the half-failure a
/// fresh venue install can meet mid-mint.
class _WriteFailingSecureStore extends FakeSecureStore {
  @override
  Future<void> writeLocalCipherKey(String keyBase64) async =>
      throw Exception('keychain unavailable');
}
