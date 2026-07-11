import 'package:flutter/material.dart';

/// How a tip reached the artist: straight through Stripe, or relayed by the
/// live.tips connected-mode worker from a MobilePay/Revolut/Monzo donor page.
enum TipMethod {
  stripe('stripe', 'Card'),
  revolut('revolut', 'Revolut'),
  mobilepay('mobilepay', 'MobilePay'),
  monzo('monzo', 'Monzo');

  const TipMethod(this.wire, this.label);

  final String wire;
  final String label;

  /// The methods that ride through the live.tips relay (a donor page + jar),
  /// in the fixed order every method list and setup flow walks them.
  static const relayMethods = [
    TipMethod.revolut,
    TipMethod.mobilepay,
    TipMethod.monzo,
  ];

  IconData get icon => switch (this) {
    TipMethod.stripe => Icons.credit_card,
    TipMethod.revolut => Icons.alternate_email,
    TipMethod.mobilepay => Icons.smartphone,
    TipMethod.monzo => Icons.account_balance,
  };

  static TipMethod? fromWire(String? wire) {
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}
