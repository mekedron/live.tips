import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/fx_rates.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/tip_method.dart';

/// ~ECB-shaped: units of X per 1 EUR.
final rates = FxRates(
  base: 'eur',
  rates: const {'gbp': 0.85, 'usd': 1.10, 'jpy': 170.0},
  fetchedAt: DateTime(2026, 7, 11),
);

Donation tip(int amountMinor, String currency, TipMethod method) =>
    Donation.relayTip(
      amountMinor: amountMinor,
      currency: currency,
      method: method,
      ts: DateTime(2026, 7, 11).millisecondsSinceEpoch,
      serial: amountMinor,
      relayId: '$currency$amountMinor',
    );

void main() {
  group('FxRates.convertMinor', () {
    test('same currency is returned untouched, to the minor unit', () {
      expect(rates.convertMinor(500, 'eur', 'eur'), 500);
      expect(rates.convertMinor(500, 'GBP', 'gbp'), 500);
    });

    test('converts through the base currency', () {
      // £8.50 at 0.85 GBP/EUR is €10.00.
      expect(rates.convertMinor(850, 'gbp', 'eur'), 1000);
      expect(rates.convertMinor(1000, 'eur', 'gbp'), 850);
      // …and cross-rate, neither side being the base.
      expect(rates.convertMinor(850, 'gbp', 'usd'), 1100);
    });

    test('respects each side\'s minor-unit scale', () {
      // JPY is zero-decimal: ¥170 is one major unit ⇒ €1.00 = 100 minor.
      expect(rates.convertMinor(170, 'jpy', 'eur'), 100);
      expect(rates.convertMinor(100, 'eur', 'jpy'), 170);
    });

    test('an unknown currency converts to null, never to a guess', () {
      expect(rates.convertMinor(500, 'xyz', 'eur'), isNull);
      expect(rates.convertMinor(500, 'eur', 'xyz'), isNull);
      expect(rates.supports('xyz'), isFalse);
    });

    test('survives a JSON round-trip', () {
      final back = FxRates.fromJson(rates.toJson());
      expect(back.convertMinor(850, 'gbp', 'eur'), 1000);
      expect(back.fetchedAt, rates.fetchedAt);
    });
  });

  group('a session that mixes currencies', () {
    LiveSession session() => LiveSession(
      id: 'ses_1',
      startedAt: DateTime(2026, 7, 11),
      currency: 'eur',
      goalMinor: 20000,
    );

    test('totals a £ Monzo tip into a € session at the reference rate', () {
      final s = session()..fx = rates;
      s.addDonation(tip(1000, 'eur', TipMethod.revolut)); // €10
      s.addDonation(tip(850, 'gbp', TipMethod.monzo)); // £8.50 → €10

      expect(s.totalMinor, 2000, reason: '€10 + £8.50 ≈ €20');
      expect(s.isMixedCurrency, isTrue);
      expect(s.uncountedDonations, isEmpty);
      // The stored tip is untouched — it is still £8.50, in GBP.
      final monzo = s.donations.last;
      expect(monzo.amountMinor, 850);
      expect(monzo.currency, 'gbp');
    });

    test('ranks the biggest tip in the session currency, not on raw units', () {
      final s = session()..fx = rates;
      s.addDonation(tip(1100, 'eur', TipMethod.revolut)); // €11.00
      s.addDonation(tip(1000, 'gbp', TipMethod.monzo)); // £10 ≈ €11.76

      // Naive minor-unit comparison would have crowned the €11 tip.
      expect(s.biggest!.currency, 'gbp');
    });

    test('without rates, a foreign tip is shown but not counted', () {
      final s = session(); // fx left null — offline, no cached table
      s.addDonation(tip(1000, 'eur', TipMethod.revolut));
      s.addDonation(tip(850, 'gbp', TipMethod.monzo));

      expect(s.totalMinor, 1000, reason: 'the £ tip is never folded in blind');
      expect(s.count, 2, reason: 'it still happened, and still shows');
      expect(s.uncountedDonations.single.currency, 'gbp');
    });

    test('a single-currency session is exact and never marked approximate', () {
      final s = session()..fx = rates;
      s.addDonation(tip(1000, 'eur', TipMethod.revolut));
      s.addDonation(tip(500, 'eur', TipMethod.mobilepay));

      expect(s.totalMinor, 1500);
      expect(s.isMixedCurrency, isFalse);
    });

    test('rates arriving mid-set re-total the tips already in the jar', () {
      final s = session();
      s.addDonation(tip(850, 'gbp', TipMethod.monzo));
      expect(s.totalMinor, 0);

      s.fx = rates; // the background refresh landed
      expect(s.totalMinor, 1000);
    });
  });
}
