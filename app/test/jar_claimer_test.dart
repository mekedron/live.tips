import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/jar_claimer.dart';

import 'helpers.dart';

/// The claim-on-attach that replaced [FirestoreTipChannel] for cloud
/// sessions (#71). What must survive the channel's death, pinned here: the
/// retry/terminal discipline its claim path had — transient failures back
/// off and retry, the relay's permanent verdicts (gone jar, dead secret,
/// full reader list) stop for good instead of hammering the callable all
/// night.

JarClaimer claimer(
  FakeCallables backend, {
  Duration? Function(int attempt)? backoff,
}) =>
    JarClaimer(
      client: fakeRelayClient(backend, auth: FakeRelayAuth(owned: true)),
      jarId: 'jar_1',
      secret: 'sec',
      bandId: 'acc_band1',
      backoff: backoff ?? (_) => Duration.zero,
    );

Future<void> settle([int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('claims once, with the full route payload; start() is one-shot',
      () async {
    final backend = FakeCallables();
    final c = claimer(backend);
    addTearDown(c.dispose);

    c.start();
    c.start(); // idempotent
    await settle();

    expect(c.claimed, isTrue);
    expect(backend.calls, hasLength(1));
    expect(backend.argsFor('claimJar'), {
      'jarId': 'jar_1',
      'secret': 'sec',
      'owned': true,
      'bandId': 'acc_band1',
    });

    c.reconnectNow(); // a landed claim needs nothing
    await settle();
    expect(backend.calls, hasLength(1));
  });

  test('a transient failure retries with backoff until the claim lands',
      () async {
    var failures = 2;
    final backend = FakeCallables({
      'claimJar': (_) {
        if (failures-- > 0) throw FakeFunctionsException('unavailable');
        return const {};
      },
    });
    final c = claimer(backend);
    addTearDown(c.dispose);

    c.start();
    await settle(30);

    expect(c.claimed, isTrue);
    expect(backend.calls, hasLength(3),
        reason: 'two refusals, then the claim that landed');
  });

  for (final code in ['not-found', 'unauthenticated', 'permission-denied']) {
    test('$code is terminal: the jar is gone or the secret is dead — no '
        'retry can fix it, and reconnectNow stays quiet too', () async {
      final backend = FakeCallables({
        'claimJar': (_) => throw FakeFunctionsException(code),
      });
      final c = claimer(backend);
      addTearDown(c.dispose);

      c.start();
      await settle(30);
      c.reconnectNow();
      await settle(30);

      expect(c.claimed, isFalse);
      expect(backend.calls, hasLength(1),
          reason: 'a permanent verdict is asked for exactly once — the '
              'seen-ping keepalive is the recovery road, not this loop');
    });
  }

  test('resource-exhausted is terminal on the claim path: the reader list '
      'is full and nothing prunes it except a new link', () async {
    final backend = FakeCallables({
      'claimJar': (_) => throw FakeFunctionsException('resource-exhausted'),
    });
    final c = claimer(backend);
    addTearDown(c.dispose);

    c.start();
    await settle(30);

    expect(c.claimed, isFalse);
    expect(backend.calls, hasLength(1));
  });

  test('reconnectNow retries an unlanded claim immediately, abandoning a '
      'dead backoff (the foreground-return courtesy)', () async {
    var fail = true;
    final backend = FakeCallables({
      'claimJar': (_) {
        if (fail) throw FakeFunctionsException('unavailable');
        return const {};
      },
    });
    // The backoff seam says "stop retrying" — the claim is stuck.
    final c = claimer(backend, backoff: (_) => null);
    addTearDown(c.dispose);

    c.start();
    await settle();
    expect(c.claimed, isFalse);
    expect(backend.calls, hasLength(1));

    fail = false;
    c.reconnectNow();
    await settle();
    expect(c.claimed, isTrue);
    expect(backend.calls, hasLength(2));
  });

  test('dispose cancels a pending retry — no call outlives the session',
      () async {
    final backend = FakeCallables({
      'claimJar': (_) => throw FakeFunctionsException('unavailable'),
    });
    final c = claimer(backend, backoff: (_) => const Duration(hours: 1));

    c.start();
    await settle();
    expect(backend.calls, hasLength(1));

    c.dispose(); // with the timer cancelled the test also ends timer-clean
    await settle();
    expect(backend.calls, hasLength(1));
  });
}
