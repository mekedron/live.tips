import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/firestore_tip_channel.dart';
import 'package:live_tips/data/tip_channel.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_method.dart';

import 'helpers.dart';

const _jarId = 'jar_live';
const _path = 'jars/$_jarId/pendingTips';

Map<String, dynamic> _pendingTip({
  Object? method = 'revolut',
  Object? amountMinor = 500,
  Object? currency = 'EUR',
  Object? name = 'Sam',
  Object? message = 'Great set!',
  Object? tsMs = 1770000000000,
}) =>
    {
      'method': method,
      'amountMinor': amountMinor,
      'currency': currency,
      'name': name,
      'message': message,
      'tsMs': tsMs,
    };

/// The channel under test, wired to [db] with a backend that accepts the
/// claim. [watch] overrides the Firestore listener (used for the rules test).
({FirestoreTipChannel channel, FakeCallables backend}) _channel(
  FirebaseFirestore db, {
  FakeCallables? backend,
  String? uid = 'uid_relay',
  PendingTipsWatch? watch,
}) {
  final calls = backend ?? FakeCallables();
  final auth = FakeRelayAuth(uid: uid);
  return (
    channel: FirestoreTipChannel(
      db: db,
      auth: auth,
      client: fakeRelayClient(calls, auth: auth),
      jarId: _jarId,
      secret: 'sec',
      watch: watch,
      // No retries in tests: a failure should be observable, not a timer.
      backoff: (_) => null,
    ),
    backend: calls,
  );
}

void main() {
  test('a pending tip is emitted, then acked by deleting the doc', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: backend) = _channel(db);
    addTearDown(channel.dispose);

    final statuses = <RelayHealth>[];
    final tips = <Tip>[];
    channel.status.listen(statuses.add);
    channel.tips.listen(tips.add);

    channel.start();
    await pumpEventQueue();

    // The claim is what authorizes the listener — it must happen before it.
    expect(backend.names, ['claimJar']);
    expect(backend.argsFor('claimJar'),
        {'jarId': _jarId, 'secret': 'sec'});
    expect(statuses, [RelayHealth.connecting, RelayHealth.ok],
        reason: 'the listener attaching IS the feed being up');

    final doc = await db.collection(_path).add(_pendingTip());
    await pumpEventQueue();

    expect(tips, hasLength(1));
    final tip = tips.single;
    expect(tip.id, 'relay_${doc.id}', reason: 'the doc id is the relay id');
    expect(tip.method, TipMethod.revolut);
    expect(tip.amountMinor, 500);
    expect(tip.currency, 'eur');
    expect(tip.name, 'Sam');
    expect(tip.message, 'Great set!');
    expect(tip.createdAt.millisecondsSinceEpoch, 1770000000000);
    expect(tip.viaService, isTrue);
    expect(tip.verified, isFalse);

    // Delivery IS deletion: the relay keeps no tip history.
    final left = await db.collection(_path).get();
    expect(left.docs, isEmpty);
  });

  test('a tip already waiting at attach is delivered (the queue redelivers '
      'what a crash never acked)', () async {
    final db = FakeFirebaseFirestore();
    await db.collection(_path).add(_pendingTip(name: 'Early'));
    final (channel: channel, backend: _) = _channel(db);
    addTearDown(channel.dispose);

    final tips = <Tip>[];
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    expect(tips.map((t) => t.name), ['Early']);
    expect((await db.collection(_path).get()).docs, isEmpty);
  });

  test('a malformed doc emits nothing but is still acked — it must not jam '
      'the queue', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: _) = _channel(db);
    addTearDown(channel.dispose);

    final tips = <Tip>[];
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    // Stripe never arrives on this feed (it comes through the poller), an
    // absent amount is garbage, and a missing timestamp is unusable.
    await db.collection(_path).add(_pendingTip(method: 'stripe'));
    await db.collection(_path).add(_pendingTip(amountMinor: null));
    await db.collection(_path).add(_pendingTip(tsMs: 'now'));
    await pumpEventQueue();

    expect(tips, isEmpty);
    expect((await db.collection(_path).get()).docs, isEmpty);
  });

  test('a rules rejection is terminal: unauthorized, no retry', () async {
    final db = FakeFirebaseFirestore();
    final controller =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    addTearDown(controller.close);
    var listens = 0;
    final (channel: channel, backend: _) = _channel(
      db,
      watch: () {
        listens++;
        return controller.stream;
      },
    );
    addTearDown(channel.dispose);

    final statuses = <RelayHealth>[];
    channel.status.listen(statuses.add);
    channel.start();
    await pumpEventQueue();

    controller.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await pumpEventQueue();

    expect(statuses.last, RelayHealth.unauthorized);
    // Terminal: even a deliberate redial stays out. Only a re-link can fix it.
    channel.reconnectNow();
    await pumpEventQueue();
    expect(listens, 1);
    expect(statuses.last, RelayHealth.unauthorized);
  });

  test('any other listener error is down, not unauthorized', () async {
    final db = FakeFirebaseFirestore();
    final controller =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    addTearDown(controller.close);
    final (channel: channel, backend: _) =
        _channel(db, watch: () => controller.stream);
    addTearDown(channel.dispose);

    final statuses = <RelayHealth>[];
    channel.status.listen(statuses.add);
    channel.start();
    await pumpEventQueue();

    controller.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    await pumpEventQueue();

    expect(statuses.last, RelayHealth.down);
  });

  for (final code in ['not-found', 'unauthenticated']) {
    test('a claim refused with $code is terminal: unauthorized, never listened',
        () async {
      final db = FakeFirebaseFirestore();
      var listens = 0;
      final (channel: channel, backend: _) = _channel(
        db,
        backend: FakeCallables({
          'claimJar': (_) => throw FakeFunctionsException(code),
        }),
        watch: () {
          listens++;
          return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
        },
      );
      addTearDown(channel.dispose);

      final statuses = <RelayHealth>[];
      channel.status.listen(statuses.add);
      channel.start();
      await pumpEventQueue();

      expect(statuses, [RelayHealth.connecting, RelayHealth.unauthorized]);
      expect(listens, 0, reason: 'a jar we cannot claim is never listened to');
    });
  }

  test('an unreachable relay is down, and retried', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: _) = _channel(
      db,
      backend: FakeCallables({
        'claimJar': (_) => throw FakeFunctionsException('unavailable'),
      }),
    );
    addTearDown(channel.dispose);

    final statuses = <RelayHealth>[];
    channel.status.listen(statuses.add);
    channel.start();
    await pumpEventQueue();

    expect(statuses, [RelayHealth.connecting, RelayHealth.down]);
  });

  test('no transport identity → down (not unauthorized), and nothing is '
      'claimed', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: backend) = _channel(db, uid: null);
    addTearDown(channel.dispose);

    final statuses = <RelayHealth>[];
    channel.status.listen(statuses.add);
    channel.start();
    await pumpEventQueue();

    expect(statuses, [RelayHealth.connecting, RelayHealth.down]);
    expect(backend.calls, isEmpty);
  });

  test('the jar is claimed once, not on every re-attach', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: backend) = _channel(db);
    addTearDown(channel.dispose);

    channel.start();
    await pumpEventQueue();
    channel.reconnectNow();
    await pumpEventQueue();
    channel.reconnectNow();
    await pumpEventQueue();

    expect(backend.names, ['claimJar']);
  });

  test('dispose closes both streams and stops the feed', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: _) = _channel(db);

    final tips = <Tip>[];
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    await channel.dispose();
    await db.collection(_path).add(_pendingTip());
    await pumpEventQueue();

    expect(tips, isEmpty);
  });
}
