import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/relay/relay_ws_codec.dart';
import 'package:live_tips/domain/tip_method.dart';

String tipJson({
  Object? method = 'revolut',
  Object? amountMinor = 500,
  Object? currency = 'EUR',
  Object? name = 'Maya',
  Object? message = 'Encore!',
  Object? ts = 1751500000000,
}) =>
    jsonEncode({
      'type': 'tip',
      'method': method,
      'amountMinor': amountMinor,
      'currency': currency,
      'name': name,
      'message': message,
      'ts': ts,
    });

void main() {
  test('decodes ready and ping', () {
    expect(decodeRelayMessage('{"type":"ready"}'), isA<RelayReady>());
    expect(decodeRelayMessage('{"type":"ping"}'), isA<RelayPing>());
  });

  test('decodes a well-formed tip and lowercases the currency', () {
    final tip = decodeRelayMessage(tipJson()) as RelayTip;
    expect(tip.method, TipMethod.revolut);
    expect(tip.amountMinor, 500);
    expect(tip.currency, 'eur');
    expect(tip.name, 'Maya');
    expect(tip.message, 'Encore!');
    expect(tip.ts, 1751500000000);
  });

  test('malformed and unknown input decodes to null, never throws', () {
    expect(decodeRelayMessage('not json'), isNull);
    expect(decodeRelayMessage(''), isNull);
    expect(decodeRelayMessage('42'), isNull);
    expect(decodeRelayMessage('[]'), isNull);
    expect(decodeRelayMessage('{}'), isNull);
    expect(decodeRelayMessage('{"type":"surprise"}'), isNull);
  });

  test('a stripe or unknown method tip is dropped', () {
    expect(decodeRelayMessage(tipJson(method: 'stripe')), isNull,
        reason: 'stripe tips come through the Stripe poller, not the relay');
    expect(decodeRelayMessage(tipJson(method: 'paypal')), isNull);
    expect(decodeRelayMessage(tipJson(method: null)), isNull);
    expect(decodeRelayMessage(tipJson(method: 7)), isNull);
  });

  test('amounts are clamped and non-int amounts rejected', () {
    expect((decodeRelayMessage(tipJson(amountMinor: 0)) as RelayTip)
        .amountMinor, 1);
    expect((decodeRelayMessage(tipJson(amountMinor: -500)) as RelayTip)
        .amountMinor, 1);
    expect((decodeRelayMessage(tipJson(amountMinor: 999999999999)) as RelayTip)
        .amountMinor, 100000000);
    expect(decodeRelayMessage(tipJson(amountMinor: 12.5)), isNull);
    expect(decodeRelayMessage(tipJson(amountMinor: '500')), isNull);
    expect(decodeRelayMessage(tipJson(amountMinor: null)), isNull);
  });

  test('non-string name/message coerce to empty, bad currency/ts reject', () {
    final tip = decodeRelayMessage(tipJson(name: 42, message: null)) as RelayTip;
    expect(tip.name, '');
    expect(tip.message, '');
    expect(decodeRelayMessage(tipJson(currency: null)), isNull);
    expect(decodeRelayMessage(tipJson(currency: '')), isNull);
    expect(decodeRelayMessage(tipJson(ts: 'yesterday')), isNull);
    expect(decodeRelayMessage(tipJson(ts: null)), isNull);
  });

  test('encodeAuth and encodePong produce the wire shapes', () {
    expect(jsonDecode(encodeAuth('s3cret')),
        {'type': 'auth', 'secret': 's3cret'});
    expect(jsonDecode(encodePong()), {'type': 'pong'});
  });

  test('toTip falls back to the serial when the relay sends no id', () {
    final msg = decodeRelayMessage(tipJson(name: '', message: '')) as RelayTip;
    final tip = msg.toTip(4);
    expect(tip.id, 'relay_1751500000000_4');
    expect(tip.verified, isFalse);
    expect(tip.livemode, isTrue);
    expect(tip.method, TipMethod.revolut);
    expect(tip.name, isNull, reason: 'empty name stays anonymous');
    expect(tip.hasMessage, isFalse);
    expect(tip.createdAt.millisecondsSinceEpoch, 1751500000000);
  });

  test("the relay's id wins, so a replayed tip keeps one identity", () {
    final frame = jsonEncode({
      'type': 'tip',
      'id': 'ab12',
      'method': 'revolut',
      'amountMinor': 500,
      'currency': 'EUR',
      'name': 'Maya',
      'message': 'Encore!',
      'ts': 1751500000000,
    });
    final tip = decodeRelayMessage(frame) as RelayTip;
    expect(tip.id, 'ab12');
    // The relay redelivers a queued tip on the next connection, where the
    // channel's serial has restarted. The tip id must not move with it,
    // or the session dedupe lets the same tip onto the stage twice.
    expect(tip.toTip(0).id, tip.toTip(7).id);
    expect(tip.toTip(0).id, 'relay_ab12');
  });

  test('a blank or non-string id degrades to the serial form', () {
    for (final bad in <Object>['', 42, <String, String>{}]) {
      final frame = jsonEncode({
        'type': 'tip',
        'id': bad,
        'method': 'revolut',
        'amountMinor': 500,
        'currency': 'EUR',
        'name': 'Maya',
        'message': 'Encore!',
        'ts': 1751500000000,
      });
      final tip = decodeRelayMessage(frame) as RelayTip;
      expect(tip.id, isNull, reason: '$bad is not an id');
      expect(tip.toTip(3).id, 'relay_1751500000000_3');
    }
  });
}
