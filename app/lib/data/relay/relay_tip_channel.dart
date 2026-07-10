import 'dart:async';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/donation.dart';
import 'relay_ws_codec.dart';

/// Health of the relay tip feed, as shown on the stage screen.
enum RelayHealth {
  /// First connection attempt in flight — nothing has failed yet.
  connecting,

  /// Authenticated and receiving.
  ok,

  /// Connection lost — reconnecting with backoff.
  down,

  /// The relay rejected the secret or the jar is gone (close 4401/4410).
  /// Terminal: no reconnect will fix it, the artist must re-link in Settings.
  unauthorized,
}

/// Close codes the relay uses for "go away and stay away".
const int _kCloseUnauthorized = 4401;
const int _kCloseJarDeleted = 4410;

/// The exact keepalive frame the server auto-answers (see worker contract):
/// it must be this raw text, not merely equivalent JSON.
const String _kRawPing = '{"type":"ping"}';

/// Owns ONE jar's WebSocket tip feed against the live.tips relay: connect,
/// authenticate, decode tips, answer pings, and reconnect forever with
/// exponential backoff — except on 4401/4410, which are terminal. Pure
/// plumbing: no Riverpod, no persistence; whoever creates it disposes it.
class RelayTipChannel {
  RelayTipChannel({
    required Uri wsUri,
    required String secret,
    WebSocketChannel Function(Uri)? connect,
    Duration? Function(int attempt)? backoff,
  }) : _wsUri = wsUri,
       _secret = secret,
       _connect = connect ?? WebSocketChannel.connect,
       _backoff = backoff ?? defaultBackoff;

  /// The server must say `ready` within this or the attempt is failed —
  /// covers half-open sockets and a relay that accepted TCP but hung.
  static const readyTimeout = Duration(seconds: 10);

  /// Keepalive cadence — under most intermediaries' 60 s idle cutoffs.
  static const pingInterval = Duration(seconds: 55);

  final Uri _wsUri;
  final String _secret;
  final WebSocketChannel Function(Uri) _connect;
  final Duration? Function(int attempt) _backoff;

  final _tips = StreamController<Donation>.broadcast();
  final _status = StreamController<RelayHealth>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _readyTimer;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  RelayHealth? _health;
  int _attempt = 0;
  int _serial = 0;
  bool _started = false;
  bool _disposed = false;

  /// True once the relay has said "never come back" (4401/4410).
  bool _terminal = false;

  /// Donations decoded from the feed. NOT exactly-once — the consumer must
  /// dedupe by donation id (the session already does for the Stripe poll).
  Stream<Donation> get tips => _tips.stream;

  /// Emits on every health transition. Subscribe BEFORE [start] — broadcast
  /// streams don't replay.
  Stream<RelayHealth> get status => _status.stream;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _open();
  }

  /// Redials immediately, abandoning any socket we currently hold.
  ///
  /// Call this when the app returns to the foreground. A suspended process
  /// comes back holding a socket the OS has not yet told us is dead, so the
  /// feed looks healthy while nothing arrives — and once the death does
  /// surface we would sit out a backoff delay before trying again. Both mean
  /// "Can't reach live.tips" on stage for no reason. The relay holds tips for
  /// a device that is away, so the only cost of an unnecessary redial is one
  /// handshake.
  void reconnectNow() {
    if (_disposed || _terminal || !_started) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _attempt = 0; // a deliberate redial is not a failed attempt
    final channel = _channel;
    if (channel != null) {
      // Drop it without going through _failCurrent: cancelling the
      // subscription first means the old socket's done/error can never land
      // on the connection we are about to open.
      _channel = null;
      _readyTimer?.cancel();
      _readyTimer = null;
      _pingTimer?.cancel();
      _pingTimer = null;
      unawaited(_sub?.cancel());
      _sub = null;
      _closeQuietly(channel);
    }
    _open();
  }

  static final _jitterRandom = Random();

  /// Exponential 1 s → 30 s cap, ±20% jitter so a relay restart doesn't get
  /// every jar in the world reconnecting on the same beat.
  static Duration defaultBackoff(int attempt) {
    final seconds = min(30.0, pow(2, attempt).toDouble());
    final jittered = seconds * (0.8 + _jitterRandom.nextDouble() * 0.4);
    return Duration(milliseconds: (jittered * 1000).round());
  }

  void _open() {
    if (_disposed || _terminal) return;
    // Once the feed has been seen to fail, "down (retrying)" is the honest
    // state until it's actually back — flipping to "connecting" on every
    // backoff attempt would just make the health pill flicker.
    if (_health != RelayHealth.down) _setStatus(RelayHealth.connecting);

    final WebSocketChannel channel;
    try {
      channel = _connect(_wsUri);
    } catch (_) {
      _setStatus(RelayHealth.down);
      _scheduleReconnect();
      return;
    }
    _channel = channel;
    // Failures already reach us through the stream's error/done — but the
    // `ready` and `sink.done` futures ALSO error on a rejected upgrade, and
    // an unlistened-to future error is an unhandled exception (confirmed
    // against production: connecting to a deleted jar blew up the zone).
    unawaited(channel.ready.catchError((_) {}));
    unawaited(channel.sink.done.catchError((Object _) {}));
    // Auth is the FIRST frame, sent immediately: the sink buffers until the
    // socket is up, and the server drops any connection that says anything
    // else first.
    _safeSend(encodeAuth(_secret));
    _readyTimer = Timer(readyTimeout, _failCurrent);
    _sub = channel.stream.listen(
      _onFrame,
      // WebSocket errors are terminal for the connection: fold error and
      // done into one idempotent failure path (both may fire).
      onError: (Object _) => _failCurrent(),
      onDone: _failCurrent,
      cancelOnError: false,
    );
  }

  void _onFrame(dynamic frame) {
    // Contract for stream callbacks: never throw out of them.
    try {
      if (frame is! String) return;
      switch (decodeRelayMessage(frame)) {
        case RelayReady():
          _readyTimer?.cancel();
          _readyTimer = null;
          _attempt = 0; // a good connection earns a fresh backoff ladder
          _setStatus(RelayHealth.ok);
          _pingTimer?.cancel();
          _pingTimer = Timer.periodic(
            pingInterval,
            (_) => _safeSend(_kRawPing),
          );
        case RelayPing():
          _safeSend(encodePong());
        case final RelayTip tip:
          if (!_tips.isClosed) _tips.add(tip.toDonation(_serial++));
        case null:
          break; // malformed/unknown — dropped by contract
      }
    } catch (_) {
      // A poisoned frame must not kill the feed.
    }
  }

  /// Tears down the current connection and decides what's next: 4401/4410 →
  /// unauthorized and stop forever; anything else → down + backoff retry.
  /// Idempotent per connection (error, done and the ready timeout can race).
  void _failCurrent() {
    final channel = _channel;
    if (channel == null || _disposed) return;
    _channel = null;
    _readyTimer?.cancel();
    _readyTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    // Read the server's close code BEFORE closing our side.
    final closeCode = channel.closeCode;
    _closeQuietly(channel);
    if (closeCode == _kCloseUnauthorized || closeCode == _kCloseJarDeleted) {
      _terminal = true;
      _setStatus(RelayHealth.unauthorized);
      return;
    }
    _setStatus(RelayHealth.down);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _terminal || _reconnectTimer != null) return;
    final delay = _backoff(_attempt++);
    if (delay == null) return; // seam said "stop retrying"
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _open();
    });
  }

  void _safeSend(String frame) {
    try {
      _channel?.sink.add(frame);
    } catch (_) {
      // A dead sink surfaces through the stream's error/done — handled there.
    }
  }

  void _setStatus(RelayHealth health) {
    if (_health == health) return;
    _health = health;
    if (!_status.isClosed) _status.add(health);
  }

  void _closeQuietly(WebSocketChannel channel) {
    try {
      unawaited(channel.sink.close().catchError((_) {}));
    } catch (_) {
      // Already closed — fine.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _readyTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Everything below is INITIATED synchronously — the socket close and the
    // done events must not depend on await scheduling (which fakeAsync-based
    // tests, and dispose-during-shutdown, both punish).
    unawaited(_sub?.cancel());
    _sub = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) _closeQuietly(channel);
    final tipsClosed = _tips.close();
    final statusClosed = _status.close();
    await tipsClosed;
    await statusClosed;
  }
}
