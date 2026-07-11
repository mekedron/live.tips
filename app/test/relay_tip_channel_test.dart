import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/relay_tip_channel.dart';
import 'package:live_tips/data/relay/relay_ws_codec.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/domain/tip_method.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A scriptable stand-in for one WebSocket connection: the test plays the
/// server (send frames, close with a code), the channel under test plays the
/// client (its outbound frames land in [sent]).
class FakeSocket extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final _fromServer = StreamController<dynamic>();
  final sent = <String>[];
  bool sinkClosed = false;
  int? _closeCode;

  late final _FakeSink _sink = _FakeSink(this);

  @override
  Stream<dynamic> get stream => _fromServer.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  // ---- server-side controls ----
  void serverSend(String frame) => _fromServer.add(frame);

  void serverClose([int? code]) {
    _closeCode = code;
    _fromServer.close();
  }

  void serverError(Object error) => _fromServer.addError(error);
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._owner);

  final FakeSocket _owner;
  final _done = Completer<void>();

  @override
  void add(dynamic data) => _owner.sent.add(data as String);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    _owner.sinkClosed = true;
    if (!_done.isCompleted) _done.complete();
    return _done.future;
  }

  @override
  Future<void> get done => _done.future;
}

String tipFrame({String method = 'revolut', int amountMinor = 500}) =>
    jsonEncode({
      'type': 'tip',
      'method': method,
      'amountMinor': amountMinor,
      'currency': 'eur',
      'name': 'Maya',
      'message': 'Encore!',
      'ts': 1751500000000,
    });

/// One channel + its observable output, on a scripted connect function.
class Harness {
  Harness({Duration? Function(int attempt)? backoff}) {
    channel = RelayTipChannel(
      wsUri: Uri.parse('wss://api.live.tips/v1/jars/jar_1/ws'),
      secret: 'sec_test',
      connect: (_) {
        final socket = FakeSocket();
        sockets.add(socket);
        return socket;
      },
      // Deterministic unless the test injects its own.
      backoff: backoff ?? (_) => const Duration(seconds: 5),
    );
    channel.status.listen(statuses.add, onDone: () => statusDone = true);
    channel.tips.listen(tips.add, onDone: () => tipsDone = true);
  }

  late final RelayTipChannel channel;
  final sockets = <FakeSocket>[];
  final statuses = <RelayHealth>[];
  final tips = <Tip>[];
  bool statusDone = false;
  bool tipsDone = false;

  FakeSocket get socket => sockets.last;
}

void main() {
  test('auth is the FIRST outbound frame, sent immediately on start', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();

      expect(h.sockets, hasLength(1));
      expect(h.socket.sent, isNotEmpty);
      expect(h.socket.sent.first, encodeAuth('sec_test'));
      expect(h.statuses, [RelayHealth.connecting]);
    });
  });

  test('ready flips status to ok', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();

      h.socket.serverSend('{"type":"ready"}');
      async.flushMicrotasks();

      expect(h.statuses, [RelayHealth.connecting, RelayHealth.ok]);
    });
  });

  test('a tip frame becomes an unverified Tip with the method mapped',
      () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      h.socket.serverSend(tipFrame(method: 'mobilepay', amountMinor: 700));
      async.flushMicrotasks();

      expect(h.tips, hasLength(1));
      final tip = h.tips.single;
      expect(tip.verified, isFalse);
      expect(tip.method, TipMethod.mobilepay);
      expect(tip.amountMinor, 700);
      expect(tip.currency, 'eur');
      expect(tip.name, 'Maya');
      expect(tip.id, 'relay_1751500000000_0',
          reason: 'serials start at 0 and go into the id');

      // Serials advance so same-millisecond tips never collide.
      h.socket.serverSend(tipFrame());
      async.flushMicrotasks();
      expect(h.tips[1].id, 'relay_1751500000000_1');
    });
  });

  test('a server ping is answered with a pong', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      h.socket.serverSend('{"type":"ping"}');
      async.flushMicrotasks();

      expect(h.socket.sent, contains(encodePong()));
    });
  });

  test('after ready the client pings every ~55 s with the exact raw frame',
      () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      async.flushMicrotasks();

      expect(h.socket.sent.where((f) => f == '{"type":"ping"}'), isEmpty);
      async.elapse(RelayTipChannel.pingInterval);
      expect(h.socket.sent.where((f) => f == '{"type":"ping"}'),
          hasLength(1));
      async.elapse(RelayTipChannel.pingInterval);
      expect(h.socket.sent.where((f) => f == '{"type":"ping"}'),
          hasLength(2));
    });
  });

  test('malformed frames are dropped without killing the feed', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      h.socket.serverSend('not json at all');
      h.socket.serverSend('{"type":"tip","method":"stripe","amountMinor":1,'
          '"currency":"eur","ts":1}');
      h.socket.serverSend(tipFrame());
      async.flushMicrotasks();

      expect(h.tips, hasLength(1));
      expect(h.statuses.last, RelayHealth.ok);
    });
  });

  for (final code in const [4401, 4410]) {
    test('close $code is terminal: unauthorized, and NO reconnect ever', () {
      fakeAsync((async) {
        final h = Harness();
        h.channel.start();
        async.flushMicrotasks();
        h.socket.serverSend('{"type":"ready"}');
        async.flushMicrotasks();

        h.socket.serverClose(code);
        async.flushMicrotasks();

        expect(h.statuses.last, RelayHealth.unauthorized);
        expect(h.sockets, hasLength(1));
        async.elapse(const Duration(minutes: 10));
        expect(h.sockets, hasLength(1),
            reason: 'a dead secret cannot be retried into working');
      });
    });
  }

  test('an ordinary close goes down, then reconnects with full re-auth', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      async.flushMicrotasks();

      h.socket.serverClose(); // no code — network blip
      async.flushMicrotasks();

      expect(h.statuses.last, RelayHealth.down);
      expect(h.sockets, hasLength(1),
          reason: 'the retry waits out the backoff');

      async.elapse(const Duration(seconds: 4));
      expect(h.sockets, hasLength(1), reason: 'backoff is 5 s here');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(h.sockets, hasLength(2));
      expect(h.sockets[1].sent.first, encodeAuth('sec_test'),
          reason: 'every reconnect re-authenticates from scratch');

      // The feed recovers — and the serials keep advancing across sockets.
      h.sockets[1].serverSend('{"type":"ready"}');
      h.sockets[1].serverSend(tipFrame());
      async.flushMicrotasks();
      expect(h.statuses.last, RelayHealth.ok);
      expect(h.tips.single.id, 'relay_1751500000000_0');
    });
  });

  test('a stream error is treated as a connection failure', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      async.flushMicrotasks();

      h.socket.serverError(StateError('boom'));
      async.flushMicrotasks();

      expect(h.statuses.last, RelayHealth.down);
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(h.sockets, hasLength(2));
    });
  });

  test('no ready within 10 s fails the attempt and reconnects', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();

      async.elapse(RelayTipChannel.readyTimeout);
      async.flushMicrotasks();
      expect(h.statuses.last, RelayHealth.down);
      expect(h.socket.sinkClosed, isTrue,
          reason: 'the half-open socket is abandoned');

      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(h.sockets, hasLength(2));
    });
  });

  test('the injected backoff drives the retry cadence and attempt count', () {
    fakeAsync((async) {
      final attempts = <int>[];
      final h = Harness(backoff: (attempt) {
        attempts.add(attempt);
        return Duration(seconds: attempt + 1);
      });
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverClose();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 1)); // attempt 0 → 1 s
      async.flushMicrotasks();
      expect(h.sockets, hasLength(2));
      h.sockets[1].serverClose();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 2)); // attempt 1 → 2 s
      async.flushMicrotasks();
      expect(h.sockets, hasLength(3));
      expect(attempts, [0, 1], reason: 'attempts grow while it stays down');

      // A successful auth resets the ladder.
      h.sockets[2].serverSend('{"type":"ready"}');
      async.flushMicrotasks();
      h.sockets[2].serverClose();
      async.flushMicrotasks();
      expect(attempts, [0, 1, 0]);
    });
  });

  test('the default backoff is exponential, capped, and jittered ±20%', () {
    // 2^attempt seconds, so attempt 0 ∈ [0.8, 1.2] s … capped at 30 s ± 20%.
    for (var attempt = 0; attempt < 12; attempt++) {
      final base = attempt >= 5 ? 30.0 : (1 << attempt).toDouble();
      for (var i = 0; i < 20; i++) {
        final d = RelayTipChannel.defaultBackoff(attempt);
        expect(d.inMilliseconds,
            inInclusiveRange((base * 800).round(), (base * 1200).round()));
      }
    }
  });

  test('dispose closes the socket, stops timers, and never reconnects', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverSend('{"type":"ready"}');
      async.flushMicrotasks();

      h.channel.dispose();
      async.flushMicrotasks();

      expect(h.socket.sinkClosed, isTrue);
      expect(h.tipsDone, isTrue);
      expect(h.statusDone, isTrue);

      final pingsBefore =
          h.socket.sent.where((f) => f == '{"type":"ping"}').length;
      async.elapse(const Duration(minutes: 10));
      expect(h.sockets, hasLength(1), reason: 'no reconnect after dispose');
      expect(h.socket.sent.where((f) => f == '{"type":"ping"}').length,
          pingsBefore,
          reason: 'the keepalive timer is dead');
    });
  });

  test('dispose while down cancels the pending reconnect', () {
    fakeAsync((async) {
      final h = Harness();
      h.channel.start();
      async.flushMicrotasks();
      h.socket.serverClose();
      async.flushMicrotasks();
      expect(h.statuses.last, RelayHealth.down);

      h.channel.dispose();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 10));
      expect(h.sockets, hasLength(1));
    });
  });

  group('reconnectNow (app returned to the foreground)', () {
    test('redials at once instead of waiting out the backoff', () {
      fakeAsync((async) {
        final h = Harness(backoff: (_) => const Duration(seconds: 30));
        h.channel.start();
        async.flushMicrotasks();
        h.socket.serverClose(); // suspended: the socket died
        async.flushMicrotasks();
        expect(h.statuses.last, RelayHealth.down);
        expect(h.sockets, hasLength(1), reason: '30 s of backoff still to run');

        h.channel.reconnectNow();
        async.flushMicrotasks();

        expect(h.sockets, hasLength(2), reason: 'redialled without waiting');
        expect(h.socket.sent.first, encodeAuth('sec_test'));

        h.socket.serverSend('{"type":"ready"}');
        async.flushMicrotasks();
        expect(h.statuses.last, RelayHealth.ok);

        // The 30 s timer that was already ticking must not fire a second,
        // redundant connect on top of the one we just made.
        async.elapse(const Duration(minutes: 1));
        expect(h.sockets, hasLength(2));
      });
    });

    test('replaces a socket the OS has not yet admitted is dead', () {
      fakeAsync((async) {
        final h = Harness();
        h.channel.start();
        async.flushMicrotasks();
        h.socket.serverSend('{"type":"ready"}');
        async.flushMicrotasks();
        expect(h.statuses.last, RelayHealth.ok);

        // Looks healthy; the phone was actually asleep and the peer is gone.
        final stale = h.socket;
        h.channel.reconnectNow();
        async.flushMicrotasks();

        expect(stale.sinkClosed, isTrue);
        expect(h.sockets, hasLength(2));

        h.socket.serverSend('{"type":"ready"}');
        async.flushMicrotasks();
        expect(h.statuses.last, RelayHealth.ok);

        // A late done from the abandoned socket must not kill the new one.
        stale.serverClose();
        async.elapse(const Duration(minutes: 1));
        expect(h.sockets, hasLength(2), reason: 'no cascade of reconnects');
        expect(h.statuses.last, RelayHealth.ok);
      });
    });

    test('stays put after a terminal close, and after dispose', () {
      fakeAsync((async) {
        final h = Harness();
        h.channel.start();
        async.flushMicrotasks();
        h.socket.serverClose(4401); // bad secret — re-linking is the only cure
        async.flushMicrotasks();
        expect(h.statuses.last, RelayHealth.unauthorized);

        h.channel.reconnectNow();
        async.elapse(const Duration(minutes: 10));
        expect(h.sockets, hasLength(1), reason: 'terminal means terminal');

        h.channel.dispose();
        async.flushMicrotasks();
        h.channel.reconnectNow();
        async.elapse(const Duration(minutes: 10));
        expect(h.sockets, hasLength(1));
      });
    });

    test('a 4408 auth timeout is transient, not a re-link', () {
      fakeAsync((async) {
        final h = Harness();
        h.channel.start();
        async.flushMicrotasks();
        h.socket.serverClose(4408); // slow link, relay swept the socket
        async.flushMicrotasks();

        expect(h.statuses.last, RelayHealth.down);
        async.elapse(const Duration(seconds: 6));
        expect(h.sockets, hasLength(2), reason: 'it retries on its own');
      });
    });
  });
}
