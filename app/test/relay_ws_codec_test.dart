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

  test('toDonation builds the relay donation with the serial in the id', () {
    final tip = decodeRelayMessage(tipJson(name: '', message: '')) as RelayTip;
    final donation = tip.toDonation(4);
    expect(donation.id, 'relay_1751500000000_4');
    expect(donation.verified, isFalse);
    expect(donation.livemode, isTrue);
    expect(donation.method, TipMethod.revolut);
    expect(donation.name, isNull, reason: 'empty name stays anonymous');
    expect(donation.hasMessage, isFalse);
    expect(donation.createdAt.millisecondsSinceEpoch, 1751500000000);
  });
}
