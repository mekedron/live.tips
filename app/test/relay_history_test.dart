import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/tip_method.dart';

import 'helpers.dart';

Donation relayTip(int serial, {int ts = 1751500000000}) => Donation.relayTip(
      amountMinor: 500 + serial,
      currency: 'eur',
      method: TipMethod.mobilepay,
      name: 'Maya',
      message: 'Encore!',
      ts: ts,
      serial: serial,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round trip: appended tips come back newest first with fields intact',
      () async {
    final store = await seededStore();
    expect(store.readRelayHistory(kTestAccountId), isEmpty);

    // Batches arrive oldest→newest; the archive reads newest-first.
    await store.appendRelayHistory(kTestAccountId, [relayTip(0), relayTip(1)]);
    await store.appendRelayHistory(kTestAccountId, [relayTip(2)]);

    final history = store.readRelayHistory(kTestAccountId);
    expect(history.map((d) => d.id), [
      'relay_1751500000000_2',
      'relay_1751500000000_1',
      'relay_1751500000000_0',
    ]);
    final tip = history.last;
    expect(tip.amountMinor, 500);
    expect(tip.method, TipMethod.mobilepay);
    expect(tip.verified, isFalse);
    expect(tip.livemode, isTrue);
    expect(tip.name, 'Maya');
    expect(tip.message, 'Encore!');
    expect(tip.stripeDashboardUrl, isNull,
        reason: 'tip-page tips have no Stripe transaction to open');
  });

  test('duplicate ids are dropped — within a batch and against the store',
      () async {
    final store = await seededStore();
    await store.appendRelayHistory(kTestAccountId, [relayTip(0)]);
    // Relay redelivery / resumed-session replay: same tip, same id.
    await store.appendRelayHistory(
        kTestAccountId, [relayTip(0), relayTip(0), relayTip(1)]);

    expect(store.readRelayHistory(kTestAccountId).map((d) => d.id), [
      'relay_1751500000000_1',
      'relay_1751500000000_0',
    ]);
  });

  test('the archive is capped — oldest beyond ${LocalStore.relayHistoryCap} '
      'fall off', () async {
    final store = await seededStore();
    final batch = [
      for (var i = 0; i < LocalStore.relayHistoryCap + 5; i++) relayTip(i),
    ];
    await store.appendRelayHistory(kTestAccountId, batch);

    final history = store.readRelayHistory(kTestAccountId);
    expect(history, hasLength(LocalStore.relayHistoryCap));
    // Newest survives at the front…
    expect(history.first.id,
        'relay_1751500000000_${LocalStore.relayHistoryCap + 4}');
    // …the five oldest are gone.
    expect(history.last.id, 'relay_1751500000000_5');
  });

  test('purgeSimulatedData leaves the relay archive alone', () async {
    final store = await seededStore();
    await store.appendRelayHistory(kTestAccountId, [relayTip(0)]);

    await store.purgeSimulatedData(kTestAccountId);

    expect(store.readRelayHistory(kTestAccountId), hasLength(1),
        reason: 'only real (livemode) tips are ever written here — there is '
            'nothing simulated to purge');
  });

  test('wipeAll clears the relay archive', () async {
    final store = await seededStore();
    await store.appendRelayHistory(kTestAccountId, [relayTip(0)]);

    await store.wipeAll();

    expect(store.readRelayHistory(kTestAccountId), isEmpty);
  });
}
