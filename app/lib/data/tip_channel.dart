import 'dart:async';

import '../domain/tip.dart';

/// Health of a push tip feed (the relay fan page), as shown on the stage
/// screen next to the Stripe poll health.
enum RelayHealth {
  /// First connection attempt in flight — nothing has failed yet.
  connecting,

  /// Authenticated and receiving.
  ok,

  /// Connection lost — reconnecting with backoff.
  down,

  /// The feed rejected our credential or its jar is gone. Terminal: no
  /// reconnect will fix it, the artist must re-link in Settings.
  unauthorized,
}

/// A live push feed of tips for one session — today the relay WebSocket,
/// later a Firestore listener. Pure plumbing: no Riverpod, no persistence;
/// whoever creates it disposes it.
abstract interface class TipChannel {
  /// Tips decoded from the feed. NOT exactly-once — the consumer must
  /// dedupe by tip id (the session already does for the Stripe poll).
  Stream<Tip> get tips;

  /// Emits on every health transition. Subscribe BEFORE [start] — broadcast
  /// streams don't replay.
  Stream<RelayHealth> get status;

  void start();

  /// Redials/refreshes immediately — called when the app returns to the
  /// foreground so a feed the OS silently killed comes back without waiting
  /// out a backoff delay.
  void reconnectNow();

  Future<void> dispose();
}
