import 'package:flutter/material.dart';

/// How a tip reached the artist: straight through Stripe, or relayed by the
/// live.tips connected-mode worker from a MobilePay/Revolut donor page.
enum TipMethod {
  stripe('stripe', 'Card'),
  revolut('revolut', 'Revolut'),
  mobilepay('mobilepay', 'MobilePay');

  const TipMethod(this.wire, this.label);

  final String wire;
  final String label;

  IconData get icon => switch (this) {
    TipMethod.stripe => Icons.credit_card,
    TipMethod.revolut => Icons.alternate_email,
    TipMethod.mobilepay => Icons.smartphone,
  };

  static TipMethod? fromWire(String? wire) {
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return null;
  }
}
