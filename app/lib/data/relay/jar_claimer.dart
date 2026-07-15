import 'dart:async';

import 'package:flutter/foundation.dart';

import 'firestore_tip_channel.dart';
import 'relay_client.dart';

/// The claim-on-attach a cloud session runs where [FirestoreTipChannel] used
/// to be (#71).
///
/// A cloud jar's fan tips are written by the SERVER straight into the
/// account's own collections — no pendingTips queue, no client drain — so a
/// cloud session attaches no tip channel at all. But the claim itself must
/// survive: it is what installs (and, after this build, backfills) the jar's
/// route — `ownerUid` + `bandId` on the jar doc, the two fields the server
/// branches on — and what keeps this uid in the jar's `readerUids`. Without
/// a claim, an old jar never converts and its tips keep flowing into a queue
/// nothing reads.
///
/// Retry discipline inherited from the channel it replaces: transient
/// failures (offline, timeouts) back off and retry; the relay's terminal
/// verdicts stop for good —
///
/// * `not-found` / auth errors: the jar is gone or the secret is dead. No
///   retry can fix it; the seen-ping keepalive is the recovery road (it
///   recreates dead jars and warns the artist to reprint).
/// * `resource-exhausted`: the jar's reader list is full. Permanent for this
///   uid until a new link, so retrying would hammer the callable all night.
///
/// There is no health surface here — the relay pill is retired for cloud
/// sessions (the tips-subcollection listener is the feed, and its flow is
/// the main pill's business) — so verdicts are logged, never shown.
///
/// Pure plumbing like the channel: no Riverpod, no persistence; whoever
/// creates it disposes it.
class JarClaimer {
  JarClaimer({
    required RelayClient client,
    required String jarId,
    required String secret,
    required String bandId,
    Duration? Function(int attempt)? backoff,
  })  : _client = client,
        _jarId = jarId,
        _secret = secret,
        _bandId = bandId,
        _backoff = backoff ?? FirestoreTipChannel.defaultBackoff;

  final RelayClient _client;
  final String _jarId;
  final String _secret;
  final String _bandId;
  final Duration? Function(int attempt) _backoff;

  Timer? _retryTimer;
  int _attempt = 0;
  bool _started = false;
  bool _claimed = false;
  bool _terminal = false;
  bool _disposed = false;
  bool _inFlight = false;

  /// The claim landed for this session — visible so tests can pin when the
  /// route install actually happened.
  @visibleForTesting
  bool get claimed => _claimed;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_attach());
  }

  /// Retries an unlanded claim immediately (the app returned to the
  /// foreground) — the same courtesy the channel's reconnect gave a feed
  /// that suspended mid-backoff. A landed claim needs nothing: it is a
  /// one-shot per session, not a connection.
  void reconnectNow() {
    if (_disposed || _terminal || _claimed || !_started) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _attempt = 0; // a deliberate retry is not a failed attempt
    unawaited(_attach());
  }

  Future<void> _attach() async {
    if (_disposed || _terminal || _claimed || _inFlight) return;
    _inFlight = true;
    try {
      await _client.claimJar(jarId: _jarId, secret: _secret, bandId: _bandId);
      if (_disposed) return;
      _claimed = true;
    } on RelayApiException catch (e) {
      if (_disposed) return;
      if (e.isNotFound || e.isAuthError || e.code == 'resource-exhausted') {
        // The channel's terminal verdicts, verbatim (see class doc). The
        // session keeps running — server-routed tips need no claim from us
        // to keep flowing, only NEW route installs do.
        _terminal = true;
        debugPrint('jar claim: terminal ${e.code} for $_jarId');
        return;
      }
      _scheduleRetry();
    } catch (_) {
      // Offline, timeout — retry with backoff.
      if (!_disposed) _scheduleRetry();
    } finally {
      _inFlight = false;
    }
  }

  void _scheduleRetry() {
    if (_retryTimer != null) return;
    final delay = _backoff(_attempt++);
    if (delay == null) return; // seam said "stop retrying"
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_attach());
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
