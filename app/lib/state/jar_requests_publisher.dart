import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/relay/relay_client.dart';
import '../domain/live_session.dart';
import '../domain/relay_jar.dart';
import '../domain/request_queue.dart';

/// Publishes a live session's request state — the open window and the
/// ranked queue — to the relay jar, so the server-rendered fan page stays
/// truthful about what fans are voting for.
///
/// One publisher per session, owned by the controller alongside the
/// coordinator. WHO calls it is the caller's business: the controller gates
/// on [SessionCoordinator.publishesRequests] (local: always; cloud: the
/// leader), so the fan page hears exactly one voice per session.
///
/// Every failure is swallowed with a debugPrint: the fan page going stale
/// for a poll cycle is the accepted cost — the band doc and the session are
/// the truth, and the next publish carries the FULL state again, so nothing
/// is ever lost to a dropped call. A session must never feel a relay hiccup.
class JarRequestsPublisher {
  JarRequestsPublisher({
    required RelayClient client,
    required RelayJar? jar,
    required String? secret,
    this.throttle = const Duration(seconds: 5),
  })  : _client = client,
        _jar = jar,
        _secret = secret;

  final RelayClient _client;

  /// Null jar/secret makes the whole publisher a silent no-op — demo
  /// sessions and Stripe-only installs have no fan page to keep truthful.
  final RelayJar? _jar;
  final String? _secret;

  /// Queue publishes are trailing-edge throttled to one per this window: a
  /// storm of request tips must not turn into a callable per tip (the relay
  /// caps ~720/uid/hour — one per 5s, exactly this). The LAST state always
  /// lands: a suppressed call schedules a timer that publishes whatever the
  /// session holds when it fires.
  final Duration throttle;

  Timer? _pending;
  DateTime? _lastQueueAt;
  LiveSession? _latest;
  bool _disposed = false;

  /// The queue changed (a request tip landed, a song was marked played…).
  /// Throttled; sends `queue` only — while the window is open the server
  /// re-arms it on every queue push, so a publishing session never lapses.
  void onQueueChanged(LiveSession session) {
    if (_disposed) return;
    _latest = session;
    final now = DateTime.now();
    final last = _lastQueueAt;
    if (last == null || now.difference(last) >= throttle) {
      _publishQueue();
      return;
    }
    // Trailing edge: one timer, re-armed never — the latest session state
    // is read when it fires, so coalesced changes all ride the one call.
    _pending ??= Timer(throttle - now.difference(last), () {
      _pending = null;
      if (!_disposed) _publishQueue();
    });
  }

  /// The open flag flipped (or a session just began/resumed) — immediate,
  /// and the queue rides along so the page is whole in one poll.
  void onOpenChanged(LiveSession session) {
    if (_disposed) return;
    _latest = session;
    _pending?.cancel();
    _pending = null;
    _lastQueueAt = DateTime.now();
    _send(open: session.requestsOpen, session: session);
  }

  /// The session ended here — best-effort `{open: false}` so the fan page
  /// stops selling requests now instead of when the 12h window lapses.
  void onStop() {
    if (_disposed) return;
    dispose();
    final jar = _jar;
    final secret = _secret;
    if (jar == null || secret == null) return;
    unawaited(_client
        .setJarRequests(jar: jar, secret: secret, open: false)
        .catchError(_logged));
  }

  /// Cancels any pending trailing-edge publish. Idempotent; [onStop] implies
  /// it. The abandon path (remote-ended, controller teardown) lands here
  /// WITHOUT onStop — closing the window is the stopping device's job.
  void dispose() {
    _disposed = true;
    _pending?.cancel();
    _pending = null;
  }

  void _publishQueue() {
    final session = _latest;
    if (session == null) return;
    _lastQueueAt = DateTime.now();
    _send(open: null, session: session);
  }

  void _send({required bool? open, required LiveSession session}) {
    final jar = _jar;
    final secret = _secret;
    if (jar == null || secret == null) return;
    unawaited(_client
        .setJarRequests(
          jar: jar,
          secret: secret,
          open: open,
          queue: RequestQueue.fromSession(session).toWirePayload(),
        )
        .catchError(_logged));
  }

  static void _logged(Object e) =>
      debugPrint('jar requests publish failed (fan page may lag): $e');
}
