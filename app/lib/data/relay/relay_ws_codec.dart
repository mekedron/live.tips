import 'dart:convert';

import '../../domain/tip.dart';
import '../../domain/tip_method.dart';

/// (En/de)coding for the relay's per-jar WebSocket — pure data, no socket —
/// so the whole protocol surface is unit-testable without a connection.
/// Everything from the wire is treated as hostile: fields are type-checked,
/// amounts re-clamped, and anything malformed or unknown is dropped.

String encodeAuth(String secret) =>
    jsonEncode({'type': 'auth', 'secret': secret});

String encodePong() => '{"type":"pong"}';

sealed class RelayInMessage {
  const RelayInMessage();
}

/// Auth accepted — the tip feed is live.
class RelayReady extends RelayInMessage {
  const RelayReady();
}

/// Keepalive — answer with [encodePong].
class RelayPing extends RelayInMessage {
  const RelayPing();
}

/// A fan-declared MobilePay/Revolut tip. Stripe payments never arrive
/// here — they come through the Stripe poller — so a `stripe` method on
/// this channel is dropped as malformed.
class RelayTip extends RelayInMessage {
  const RelayTip({
    required this.method,
    required this.amountMinor,
    required this.currency,
    required this.name,
    required this.message,
    required this.ts,
    this.id,
  });

  /// The relay's own id, stable across redeliveries of a tip it held while
  /// this device was offline. Null from relays older than the tip queue.
  final String? id;

  final TipMethod method;
  final int amountMinor;
  final String currency;

  /// May be '' — fans can stay anonymous.
  final String name;

  /// May be ''.
  final String message;

  /// Milliseconds since epoch, as stamped by the relay.
  final int ts;

  /// [serial] keeps ids unique when several tips share the same millisecond,
  /// for relays that send no [id] of their own.
  Tip toTip(int serial) => Tip.relayTip(
        amountMinor: amountMinor,
        currency: currency,
        method: method,
        name: name.isEmpty ? null : name,
        message: message.isEmpty ? null : message,
        ts: ts,
        serial: serial,
        relayId: id,
      );
}

const int _kMinAmountMinor = 1;
const int _kMaxAmountMinor = 100000000;

/// Null for malformed input or unknown types (ignored by contract).
/// Never throws.
RelayInMessage? decodeRelayMessage(String raw) {
  Object? parsed;
  try {
    parsed = jsonDecode(raw);
  } catch (_) {
    return null;
  }
  if (parsed is! Map) return null;
  final map = Map<String, dynamic>.from(parsed);
  switch (map['type']) {
    case 'ready':
      return const RelayReady();
    case 'ping':
      return const RelayPing();
    case 'tip':
      return _decodeTip(map);
    default:
      return null;
  }
}

RelayTip? _decodeTip(Map<String, dynamic> map) {
  try {
    // Only relayed methods are valid here; stripe or unknown → drop.
    final method =
        TipMethod.fromWire(map['method'] is String ? map['method'] as String : null);
    if (method == null || method == TipMethod.stripe) return null;

    final amount = map['amountMinor'];
    if (amount is! int) return null;

    final currency = map['currency'];
    if (currency is! String || currency.isEmpty) return null;

    final ts = map['ts'];
    if (ts is! int) return null;

    final id = map['id'];

    return RelayTip(
      method: method,
      amountMinor: amount.clamp(_kMinAmountMinor, _kMaxAmountMinor),
      currency: currency.toLowerCase(),
      name: map['name'] is String ? map['name'] as String : '',
      message: map['message'] is String ? map['message'] as String : '',
      ts: ts,
      id: id is String && id.isNotEmpty ? id : null,
    );
  } catch (_) {
    return null;
  }
}
