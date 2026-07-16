import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/relay_jar.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/state/jar_requests_publisher.dart';

import 'helpers.dart';

const _jar = RelayJar(
  jarId: 'jar_1',
  tipUrl: 'https://live.tips/t/jar_1',
  artistName: 'Foxy Live',
  currency: 'eur',
  revolutUsername: 'foxy',
  createdAtMs: 1,
);

LiveSession session() => LiveSession(
      id: 'ses_1',
      startedAt: DateTime(2026, 7, 3, 20),
      currency: 'eur',
      goalMinor: 10000,
    );

Tip request(String id, int amount) => Tip(
      id: id,
      amountMinor: amount,
      currency: 'eur',
      createdAt: DateTime(2026, 7, 3, 21),
      songId: 'sng_1',
      songTitle: 'Wonderwall',
    );

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('queue publishes are trailing-edge throttled and carry LATEST state',
      () async {
    final backend = FakeCallables();
    final publisher = JarRequestsPublisher(
      client: fakeRelayClient(backend),
      jar: _jar,
      secret: 'sec_1',
      throttle: const Duration(milliseconds: 150),
    );
    addTearDown(publisher.dispose);

    final s = session();
    s.addTip(request('a', 500));
    publisher.onQueueChanged(s); // first call: publishes immediately
    await settle();
    expect(backend.calls, hasLength(1));

    // Three more changes inside the window — one trailing publish, and it
    // reads the session as it stands WHEN THE TIMER FIRES, not as queued.
    s.addTip(request('b', 100));
    publisher.onQueueChanged(s);
    s.addTip(request('c', 200));
    publisher.onQueueChanged(s);
    s.setSongStatus('sng_1', LiveSession.statusPlayed);
    publisher.onQueueChanged(s);
    await settle();
    expect(backend.calls, hasLength(1), reason: 'still inside the window');

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(backend.calls, hasLength(2));
    expect(backend.calls.last.args['queue'], {
      'sng_1': {'t': 800, 'c': 3, 's': 'p'},
    });
    expect(backend.calls.last.args.containsKey('open'), isFalse);
  });

  test('onOpenChanged bypasses the throttle and cancels a pending publish',
      () async {
    final backend = FakeCallables();
    final publisher = JarRequestsPublisher(
      client: fakeRelayClient(backend),
      jar: _jar,
      secret: 'sec_1',
      throttle: const Duration(milliseconds: 150),
    );
    addTearDown(publisher.dispose);

    final s = session()..requestsOpen = true;
    publisher.onQueueChanged(s);
    publisher.onQueueChanged(s); // pending trailing publish
    s.requestsOpen = false;
    publisher.onOpenChanged(s); // immediate, supersedes the pending one
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(backend.calls, hasLength(2),
        reason: 'the cancelled trailing publish must not fire a third call');
    expect(backend.calls.last.args['open'], isFalse);
    expect(backend.calls.last.args.containsKey('queue'), isTrue,
        reason: 'the open flip carries the queue so one poll shows it all');
  });

  test('onStop sends {open:false} only, and the publisher is spent', () async {
    final backend = FakeCallables();
    final publisher = JarRequestsPublisher(
      client: fakeRelayClient(backend),
      jar: _jar,
      secret: 'sec_1',
    );
    publisher.onStop();
    await settle();

    expect(backend.calls, hasLength(1));
    expect(backend.calls.single.args['open'], isFalse);
    expect(backend.calls.single.args.containsKey('queue'), isFalse);

    publisher.onQueueChanged(session());
    publisher.onStop();
    await settle();
    expect(backend.calls, hasLength(1), reason: 'disposed — silent for good');
  });

  // ---------------------------------------------------------------------
  // Server-computed totals (#71 Phase 3): on a routed (cloud) jar the tip
  // POST bumps requestsLive.songs itself, and this publisher must speak
  // verdicts only — a wholesale queue push could clobber a bump that raced
  // it. The one exception is the fresh-session reset, which wholesale-clears
  // the previous night's map before the new set can have bumped anything.

  JarRequestsPublisher serverTotalsPublisher(FakeCallables backend) =>
      JarRequestsPublisher(
        client: fakeRelayClient(backend),
        jar: _jar,
        secret: 'sec_1',
        serverComputesTotals: true,
        throttle: const Duration(milliseconds: 150),
      );

  test('server totals: a queue change publishes VERDICTS only, never totals',
      () async {
    final backend = FakeCallables();
    final publisher = serverTotalsPublisher(backend);
    addTearDown(publisher.dispose);

    final s = session();
    s.addTip(request('a', 500));
    s.addTip(request('b', 100));
    s.setSongStatus('sng_1', LiveSession.statusPlayed);
    publisher.onQueueChanged(s);
    await settle();

    expect(backend.calls, hasLength(1));
    expect(backend.calls.single.args['statuses'], {'sng_1': 'p'});
    expect(backend.calls.single.args.containsKey('queue'), isFalse,
        reason: 'a wholesale push could clobber a server bump that raced it');
  });

  test('server totals: an open flip carries open + statuses, still no queue',
      () async {
    final backend = FakeCallables();
    final publisher = serverTotalsPublisher(backend);
    addTearDown(publisher.dispose);

    final s = session()..requestsOpen = true;
    s.addTip(request('a', 500));
    publisher.onOpenChanged(s);
    await settle();

    expect(backend.calls, hasLength(1));
    expect(backend.calls.single.args['open'], isTrue);
    expect(backend.calls.single.args['statuses'], {'sng_1': 'q'});
    expect(backend.calls.single.args.containsKey('queue'), isFalse);
  });

  test('server totals: the fresh-session reset is one wholesale EMPTY queue',
      () async {
    final backend = FakeCallables();
    final publisher = serverTotalsPublisher(backend);
    addTearDown(publisher.dispose);

    final s = session()..requestsOpen = true;
    publisher.onOpenChanged(s, resetQueue: true);
    await settle();

    expect(backend.calls, hasLength(1));
    expect(backend.calls.single.args['open'], isTrue);
    expect(backend.calls.single.args['queue'], isEmpty);
    expect(backend.calls.single.args.containsKey('statuses'), isFalse,
        reason: 'queue and statuses are mutually exclusive on the wire — '
            'and a fresh set has no verdicts to publish anyway');
  });

  test('server totals: onStop still sends {open:false} alone', () async {
    final backend = FakeCallables();
    final publisher = serverTotalsPublisher(backend);
    publisher.onStop();
    await settle();

    expect(backend.calls, hasLength(1));
    expect(backend.calls.single.args['open'], isFalse);
    expect(backend.calls.single.args.containsKey('queue'), isFalse);
    expect(backend.calls.single.args.containsKey('statuses'), isFalse);
  });

  test('without a jar or secret every call is a silent no-op', () async {
    final backend = FakeCallables();
    final publisher = JarRequestsPublisher(
      client: fakeRelayClient(backend),
      jar: null,
      secret: null,
    );
    addTearDown(publisher.dispose);

    publisher.onQueueChanged(session());
    publisher.onOpenChanged(session());
    publisher.onStop();
    await settle();
    expect(backend.calls, isEmpty);
  });
}
