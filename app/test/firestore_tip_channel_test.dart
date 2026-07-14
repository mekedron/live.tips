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
  Object? songId,
  Object? songTitle,
}) =>
    {
      'method': method,
      'amountMinor': amountMinor,
      'currency': currency,
      'name': name,
      'message': message,
      'tsMs': tsMs,
      'songId': ?songId,
      'songTitle': ?songTitle,
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

  test('a song request carries its songId and songTitle onto the tip', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: _) = _channel(db);
    addTearDown(channel.dispose);

    final tips = <Tip>[];
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    await db.collection(_path).add(_pendingTip(
          songId: 'sng_lxyz1234abcd',
          songTitle: '  Wonderwall ', // the relay trims; so do we
        ));
    await pumpEventQueue();

    expect(tips, hasLength(1));
    expect(tips.single.songId, 'sng_lxyz1234abcd');
    expect(tips.single.songTitle, 'Wonderwall');
    expect(tips.single.amountMinor, 500);
  });

  test('malformed song fields drop the FIELDS, never the tip — the money is '
      'real even when the metadata is garbage', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: _) = _channel(db);
    addTearDown(channel.dispose);

    final tips = <Tip>[];
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    // Each doc is hostile in one way: a non-string id, an id with forbidden
    // characters, an over-long id, a non-string title, an over-long title
    // (121 code points), and a whitespace-only title.
    await db.collection(_path).add(_pendingTip(songId: 42, songTitle: 7));
    await db
        .collection(_path)
        .add(_pendingTip(songId: 'sng bad id!', songTitle: 'X' * 121));
    await db
        .collection(_path)
        .add(_pendingTip(songId: 'a' * 33, songTitle: '   '));
    await pumpEventQueue();

    expect(tips, hasLength(3), reason: 'every tip survives');
    for (final tip in tips) {
      expect(tip.songId, isNull);
      expect(tip.songTitle, isNull);
      expect(tip.amountMinor, 500);
    }
  });

  test('one good song field survives the other being garbage', () async {
    final db = FakeFirebaseFirestore();
    final (channel: channel, backend: _) = _channel(db);
    addTearDown(channel.dispose);

    final tips = <Tip>[];
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    await db
        .collection(_path)
        .add(_pendingTip(songId: 'sng_ok', songTitle: List.filled(3, 'x')));
    await pumpEventQueue();

    expect(tips.single.songId, 'sng_ok');
    expect(tips.single.songTitle, isNull);
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

  test('a claim refused with resource-exhausted is terminal: the reader list '
      'is full and no amount of retrying can drain it', () async {
    final db = FakeFirebaseFirestore();
    var listens = 0;
    final (channel: channel, backend: backend) = _channel(
      db,
      backend: FakeCallables({
        'claimJar': (_) => throw FakeFunctionsException('resource-exhausted'),
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

    expect(statuses, [RelayHealth.connecting, RelayHealth.deviceLimit],
        reason: 'a full reader list is a permanent verdict, not "down"');
    expect(listens, 0, reason: 'a jar we cannot claim is never listened to');

    // No re-attach loop: even a deliberate redial must not hammer the claim
    // — the answer would be the same all night.
    channel.reconnectNow();
    await pumpEventQueue();
    expect(backend.names, ['claimJar']);
    expect(statuses.last, RelayHealth.deviceLimit);
  });

  test('a from-cache snapshot does not report the feed healthy — an offline '
      'device replaying its cache is not "live"', () async {
    final db = FakeFirebaseFirestore();
    final controller =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
    addTearDown(controller.close);
    final (channel: channel, backend: _) =
        _channel(db, watch: () => controller.stream);
    addTearDown(channel.dispose);

    final statuses = <RelayHealth>[];
    final tips = <Tip>[];
    channel.status.listen(statuses.add);
    channel.tips.listen(tips.add);
    channel.start();
    await pumpEventQueue();

    // fake_cloud_firestore never raises a from-cache snapshot, so feed the
    // listener's body directly — the same seam the cloud mirrors use.
    await db.collection(_path).add(_pendingTip(name: 'Cached'));
    channel.applySnapshot(
      (await db.collection(_path).get()).docs,
      fromCache: true,
    );
    await pumpEventQueue();

    expect(statuses, [RelayHealth.connecting],
        reason: 'a cached snapshot is silence from the server, not health');
    // The cached tip itself is real and still delivered (its ack queues up
    // for the reconnect).
    expect(tips.map((t) => t.name), ['Cached']);

    // The server speaking — even with nothing to say — IS the feed being up.
    channel.applySnapshot(const [], fromCache: false);
    await pumpEventQueue();
    expect(statuses, [RelayHealth.connecting, RelayHealth.ok]);
  });

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
