import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/tip_method.dart';

void main() {
  test('wire values round-trip through fromWire', () {
    for (final method in TipMethod.values) {
      expect(TipMethod.fromWire(method.wire), method);
    }
  });

  test('unknown or missing wire values map to null', () {
    expect(TipMethod.fromWire('paypal'), isNull);
    expect(TipMethod.fromWire(''), isNull);
    expect(TipMethod.fromWire(null), isNull);
  });

  test('labels are display-ready (stripe reads as Card)', () {
    expect(TipMethod.stripe.label, 'Card');
    expect(TipMethod.revolut.label, 'Revolut');
    expect(TipMethod.mobilepay.label, 'MobilePay');
  });
}
