import '../core/money.dart';

/// Daily reference exchange rates, used for ONE thing: adding up tips that
/// arrived in different currencies.
///
/// A tip is always stored in the currency it was actually paid in — a £5 Monzo
/// tip is £5, because £5 is what lands in the artist's Monzo account. Nothing
/// here ever rewrites that. These rates exist only so a stage total can put a
/// €10 Revolut tip and a £5 Monzo tip on the same goal bar, which is impossible
/// without *some* rate.
///
/// That makes every converted figure an approximation, and the UI says so (a
/// "≈" in front of any total that mixes currencies). Rates are ECB reference
/// rates — the mid-market rate of the day, not the rate Monzo or Revolut will
/// actually apply — and they move. Two runs of the same session can therefore
/// show slightly different totals; the per-tip amounts never change.
class FxRates {
  const FxRates({
    required this.base,
    required this.rates,
    required this.fetchedAt,
  });

  /// Lowercase ISO-4217 the [rates] are quoted against.
  final String base;

  /// `currency -> units of that currency per 1 [base]`. Lowercase keys.
  final Map<String, double> rates;

  final DateTime fetchedAt;

  /// Rates go stale; a day-old ECB rate is fine for a goal bar, a month-old
  /// one is a lie we shouldn't tell.
  static const maxAge = Duration(days: 7);

  bool isStaleAt(DateTime now) => now.difference(fetchedAt) > maxAge;

  double? _perBase(String currency) {
    final c = currency.toLowerCase();
    if (c == base) return 1;
    return rates[c];
  }

  bool supports(String currency) => _perBase(currency) != null;

  /// Converts a minor-unit amount between currencies, honouring each side's
  /// minor-unit scale (¥ has none, € has two). Null when either currency is
  /// missing from the table — the caller must then decline to count the tip
  /// rather than guess at it.
  int? convertMinor(int amountMinor, String from, String to) {
    if (from.toLowerCase() == to.toLowerCase()) return amountMinor;
    final fromRate = _perBase(from);
    final toRate = _perBase(to);
    if (fromRate == null || toRate == null || fromRate == 0) return null;

    final major = amountMinor / minorUnitsPerMajor(from);
    final converted = major / fromRate * toRate;
    return (converted * minorUnitsPerMajor(to)).round();
  }

  Map<String, dynamic> toJson() => {
    'base': base,
    'rates': rates,
    'fetchedAt': fetchedAt.millisecondsSinceEpoch,
  };

  factory FxRates.fromJson(Map<String, dynamic> json) => FxRates(
    base: (json['base'] as String).toLowerCase(),
    rates: {
      for (final e in (json['rates'] as Map).entries)
        (e.key as String).toLowerCase(): (e.value as num).toDouble(),
    },
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['fetchedAt'] as num).toInt(),
    ),
  );
}
