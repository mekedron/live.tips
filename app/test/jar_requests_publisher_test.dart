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
