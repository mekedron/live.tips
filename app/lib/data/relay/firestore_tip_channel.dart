import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/tip.dart';
import '../../domain/tip_method.dart';
import '../tip_channel.dart';
import 'relay_auth.dart';
import 'relay_client.dart';

/// How the pendingTips feed is opened. The default listens to Firestore;
/// tests hand in a stream they drive — the same seam the WebSocket channel
/// had for its socket, and the only way to exercise a rules rejection without
/// a live backend.
typedef PendingTipsWatch = Stream<QuerySnapshot<Map<String, dynamic>>>
    Function();

/// Owns ONE jar's tip feed on Firebase: sign in (a transport identity is
/// enough), claim the jar so the rules let us read it, then listen to
/// `jars/{jarId}/pendingTips` forever.
///
/// Delivery IS deletion. A pending tip doc lives until this device has shown
/// it, and the delete is the acknowledgement — that is how the relay keeps no
/// tip history. The order is therefore emit-then-delete, never the reverse: a
/// crash between the two redelivers the tip on the next attach (the session
/// dedupes by id), while a delete-first crash would lose it for good.
///
/// Pure plumbing: no Riverpod, no persistence; whoever creates it disposes it.
class FirestoreTipChannel implements TipChannel {
  FirestoreTipChannel({
    required FirebaseFirestore db,
    required RelayAuth auth,
    required RelayClient client,
    required String jarId,
    required String secret,
    PendingTipsWatch? watch,
    Duration? Function(int attempt)? backoff,
  })  : _db = db,
        _auth = auth,
        _client = client,
        _jarId = jarId,
        _secret = secret,
        _watch = watch,
        _backoff = backoff ?? defaultBackoff;

  final FirebaseFirestore _db;
  final RelayAuth _auth;
  final RelayClient _client;
  final String _jarId;
  final String _secret;
  final PendingTipsWatch? _watch;
  final Duration? Function(int attempt) _backoff;

  final _tips = StreamController<Tip>.broadcast();
  final _status = StreamController<RelayHealth>.broadcast();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _retryTimer;
  RelayHealth? _health;
  int _attempt = 0;

  /// Bumped on every (re)attach so a late callback from an abandoned listener
  /// — or an in-flight claimJar — cannot touch the connection that replaced it.
  int _generation = 0;

  /// The jar has been claimed with this uid; claiming again would just cost a
  /// round trip per reconnect.
  String? _claimedUid;

  bool _started = false;
  bool _disposed = false;

  /// True once the relay has said "never come back" — a dead jar or a dead
  /// secret. Mirrors the WS relay's 4401/4410: no retry can fix it, the artist
  /// must re-link in Settings.
  bool _terminal = false;

  @override
  Stream<Tip> get tips => _tips.stream;

  @override
  Stream<RelayHealth> get status => _status.stream;

  @override
  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_attach());
  }

  /// Re-attaches immediately, abandoning the listener we currently hold.
  ///
  /// Called when the app returns to the foreground. A suspended process comes
  /// back holding a stream the OS has not yet told us is dead, so the feed
  /// looks healthy while nothing arrives. The relay holds tips for a device
  /// that is away, so the only cost of an unnecessary re-attach is one listen.
  @override
  void reconnectNow() {
    if (_disposed || _terminal || !_started) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _attempt = 0; // a deliberate re-attach is not a failed attempt
    unawaited(_attach());
  }

  static final _jitterRandom = Random();

  /// Exponential 1 s → 30 s cap, ±20% jitter so a backend blip doesn't get
  /// every jar in the world re-listening on the same beat.
  static Duration defaultBackoff(int attempt) {
    final seconds = min(30.0, pow(2, attempt).toDouble());
    final jittered = seconds * (0.8 + _jitterRandom.nextDouble() * 0.4);
    return Duration(milliseconds: (jittered * 1000).round());
  }

  Future<void> _attach() async {
    if (_disposed || _terminal) return;
    final generation = ++_generation;
    unawaited(_sub?.cancel());
    _sub = null;

    // Once the feed has been seen to fail, "down (retrying)" is the honest
    // state until it is actually back — flipping to "connecting" on every
    // backoff attempt would just make the health pill flicker.
    if (_health != RelayHealth.down) _setStatus(RelayHealth.connecting);

    try {
      final uid = await _auth.ensureRelayUid();
      if (uid == null) {
        // No Firebase, or the anonymous sign-in failed. Transient as far as we
        // can tell (offline at launch looks exactly like this), so retry.
        _fail(generation);
        return;
      }
      // The claim is what puts this uid in the jar's readerUids — without it
      // the listener below is a guaranteed permission-denied. Re-claim after a
      // secret rotation elsewhere revoked us: cheap, and the only way back in.
      if (_claimedUid != uid) {
        await _client.claimJar(jarId: _jarId, secret: _secret);
        if (_disposed || generation != _generation) return;
        _claimedUid = uid;
      }
    } on RelayApiException catch (e) {
      if (generation != _generation) return;
      // A gone jar or a dead secret: terminal, exactly like the WS relay's
      // 4410/4401 close codes.
      if (e.isNotFound || e.isAuthError) {
        _goTerminal();
      } else {
        _fail(generation);
      }
      return;
    } catch (_) {
      // Offline, timeout — retry with backoff.
      _fail(generation);
      return;
    }
    if (_disposed || generation != _generation) return;

    final stream =
        _watch?.call() ?? _db.collection('jars/$_jarId/pendingTips').snapshots();
    _sub = stream.listen(
      (snapshot) => _onSnapshot(generation, snapshot),
      onError: (Object error) => _onListenerError(generation, error),
      cancelOnError: false,
    );
  }

  void _onSnapshot(
    int generation,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (_disposed || generation != _generation) return;
    // The listener is alive and the rules let us read: that IS the feed being
    // up, tips or no tips.
    _attempt = 0; // a good attach earns a fresh backoff ladder
    _setStatus(RelayHealth.ok);

    // Only additions are tips: a doc we already emitted comes back as a
    // `removed` change once our own delete lands, and nothing ever edits one
    // in place (the rules forbid it).
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final doc = change.doc;
      final tip = _tipFromDoc(doc.id, doc.data());
      // Emit first, ack second. A malformed doc emits nothing but is still
      // deleted — otherwise it would jam the queue forever.
      if (tip != null && !_tips.isClosed) _tips.add(tip);
      unawaited(_ack(doc.reference));
    }
  }

  /// The delete that acknowledges delivery. Best effort: a failed ack leaves
  /// the doc for the next attach, which redelivers it — duplicates are the
  /// price of never losing a tip, and the session dedupes by id.
  Future<void> _ack(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await ref.delete();
    } catch (_) {}
  }

  void _onListenerError(int generation, Object error) {
    if (_disposed || generation != _generation) return;
    // The rules said no. Either the jar was deleted or a rotation elsewhere
    // dropped this uid from readerUids and our secret can no longer buy it
    // back — the same terminal verdict the claim would give us.
    if (error is FirebaseException && error.code == 'permission-denied') {
      _goTerminal();
      return;
    }
    _fail(generation);
  }

  void _goTerminal() {
    _terminal = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _setStatus(RelayHealth.unauthorized);
  }

  void _fail(int generation) {
    if (_disposed || _terminal || generation != _generation) return;
    unawaited(_sub?.cancel());
    _sub = null;
    _setStatus(RelayHealth.down);
    if (_retryTimer != null) return;
    final delay = _backoff(_attempt++);
    if (delay == null) return; // seam said "stop retrying"
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_attach());
    });
  }

  void _setStatus(RelayHealth health) {
    if (_health == health) return;
    _health = health;
    if (!_status.isClosed) _status.add(health);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    await _tips.close();
    await _status.close();
  }
}

const int _kMinAmountMinor = 1;
const int _kMaxAmountMinor = 100000000;

/// Decodes one `pendingTips` doc. Everything from the server is treated as
/// hostile — fields are type-checked, amounts re-clamped, and anything
/// malformed or unknown is dropped rather than shown on stage. Stripe
/// payments never arrive here (they come through the Stripe poller), so a
/// `stripe` method on this feed is malformed by definition.
Tip? _tipFromDoc(String id, Map<String, dynamic>? data) {
  if (data == null) return null;
  try {
    final method = TipMethod.fromWire(
        data['method'] is String ? data['method'] as String : null);
    if (method == null || method == TipMethod.stripe) return null;

    final amount = data['amountMinor'];
    if (amount is! num) return null;

    final currency = data['currency'];
    if (currency is! String || currency.isEmpty) return null;

    final ts = data['tsMs'];
    if (ts is! num) return null;

    final name = data['name'] is String ? data['name'] as String : '';
    final message = data['message'] is String ? data['message'] as String : '';

    return Tip.relayTip(
      amountMinor: amount.toInt().clamp(_kMinAmountMinor, _kMaxAmountMinor),
      currency: currency.toLowerCase(),
      method: method,
      name: name.isEmpty ? null : name,
      message: message.isEmpty ? null : message,
      ts: ts.toInt(),
      // The doc id is the relay's own id, stable across redeliveries — the
      // serial only ever mattered for relays that had none.
      serial: 0,
      relayId: id,
    );
  } catch (_) {
    return null;
  }
}
