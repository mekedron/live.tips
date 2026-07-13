import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/firebase/device_registry.dart';

/// The device list, and what a revocation does to it.
///
/// The tombstone is machinery, not information: `revoked: true` stays in
/// Firestore for the revoked device itself to read and sign out on (deleting
/// it would let a device that was offline at revocation time re-register as
/// trusted), but the artist's list is where they read WHO can see their tips
/// and their keys — and a headstone for every phone they ever revoked makes
/// that answer harder to read, not more honest (#35).

const _uid = 'uid_1';
const _thisDevice = 'dev_self';

Future<DeviceRegistry> _registry(FakeFirebaseFirestore db) async => DeviceRegistry(
      db: db,
      deviceId: _thisDevice,
      describe: () async => const DeviceDescription(
        name: "Casey's iPhone",
        platform: 'ios',
      ),
    );

Future<void> _seedDevice(
  FakeFirebaseFirestore db,
  String id, {
  required bool revoked,
  String name = 'A device',
}) async {
  await db.doc('users/$_uid/devices/$id').set({
    'name': name,
    'platform': 'macos',
    'createdAtMs': 1,
    'lastSeenAtMs': 2,
    'revoked': revoked,
    if (revoked) 'revokedAtMs': 3,
  });
}

void main() {
  test('a revoked device leaves the list; the live ones stay', () async {
    final db = FakeFirebaseFirestore();
    final registry = await _registry(db);
    await _seedDevice(db, 'dev_live', revoked: false, name: 'MacBook Pro');
    await _seedDevice(db, 'dev_gone', revoked: true, name: 'Sold phone');

    final devices = await registry.watchDevices(_uid).first;

    expect(devices.map((d) => d.id), ['dev_live']);
  });

  test('THIS device stays on the list even revoked — hiding the row the '
      'artist is sitting on would be the lie', () async {
    final db = FakeFirebaseFirestore();
    final registry = await _registry(db);
    await _seedDevice(db, _thisDevice, revoked: true, name: 'This phone');
    await _seedDevice(db, 'dev_gone', revoked: true, name: 'Sold phone');

    final devices = await registry.watchDevices(_uid).first;

    expect(devices.map((d) => d.id), [_thisDevice]);
    expect(devices.single.revoked, isTrue);
    expect(devices.single.isCurrent, isTrue);
  });

  test('registering an existing doc cannot clear its own revocation — which '
      'is why the confirm ceremony has to (#36)', () async {
    // The rules pin `revoked` client-side, and registerThisDevice takes the
    // UPDATE path on a doc that already exists: a device that was revoked and
    // signs back in cannot lift its own flag, and must not be able to.
    final db = FakeFirebaseFirestore();
    final registry = await _registry(db);
    await _seedDevice(db, _thisDevice, revoked: true, name: 'Was revoked');

    expect(await registry.registerThisDevice(_uid), isTrue);

    final doc = await db.doc('users/$_uid/devices/$_thisDevice').get();
    expect(doc.data()!['revoked'], isTrue);
    expect(doc.data()!['name'], "Casey's iPhone", reason: 'the rest refreshes');
  });

  test('a first registration declares itself un-revoked', () async {
    final db = FakeFirebaseFirestore();
    final registry = await _registry(db);

    expect(await registry.registerThisDevice(_uid), isTrue);

    final doc = await db.doc('users/$_uid/devices/$_thisDevice').get();
    expect(doc.data()!['revoked'], isFalse);
    expect(doc.data()!.containsKey('revokedAtMs'), isFalse);
  });
}
