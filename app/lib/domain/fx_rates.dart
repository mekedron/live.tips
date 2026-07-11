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
/// The floor under everything: rates baked into the binary, per EUR.
///
/// Every rate service eventually 500s, gets blocked, rebrands, or vanishes,
/// and an artist on stage in a basement venue has no network at all. When that
/// happens we would otherwise have to drop foreign tips out of the night's
/// total. A frozen, roughly-right rate beats a silently missing tip: "≈ €95" is
/// useful, "€85 (we lost one)" is not.
///
/// These are real rates, captured on [kBuiltinRatesAsOf], covering exactly the
/// currencies the jar picker offers. They are a LAST RESORT, in this order:
/// a live provider, then the cached table from the last successful fetch, then
/// these. They are never persisted over a real table, and every total they
/// touch is already rendered with a "≈".
///
/// They do drift. Refresh them when convenient — none of this is load-bearing
/// enough to be worth a build step, and a rate that is a few percent stale is
/// still a far better answer than none.
const kBuiltinRatesAsOf = '2026-07-11';

const Map<String, double> kBuiltinEurRates = {
  'usd': 1.1409,
  'gbp': 0.8516,
  'cad': 1.6157,
  'aud': 1.6416,
  'nzd': 1.9796,
  'chf': 0.9222,
  'sek': 11.0254,
  'nok': 11.1622,
  'dkk': 7.4725,
  'pln': 4.321,
  'czk': 24.2437,
  'ron': 5.2329,
  'huf': 355.74,
  'jpy': 184.53,
  'mxn': 19.9365,
  'brl': 5.8295,
  'sgd': 1.474,
  'hkd': 8.9448,
  'ils': 3.4348,
  'aed': 4.1901,
  'inr': 109.0,
};

/// Where a rate table came from, worst to best.
enum FxOrigin {
  /// Compiled in — see [kBuiltinEurRates]. Right order of magnitude, no more.
  builtin('built-in'),

  /// Fetched from a rate service. [FxRates.source] names which one.
  live('live');

  const FxOrigin(this.label);
  final String label;
}

class FxRates {
  const FxRates({
    required this.base,
    required this.rates,
    required this.fetchedAt,
    this.origin = FxOrigin.live,
    this.source = 'unknown',
  });

  /// The compiled-in table — what we fall back to when every provider is
  /// unreachable and nothing was ever cached.
  factory FxRates.builtin() => FxRates(
    base: 'eur',
    rates: kBuiltinEurRates,
    // Dated to when the rates were captured, not to now: this table is exactly
    // as old as it looks, and marking it fresh would defeat the staleness check
    // that keeps trying to replace it.
    fetchedAt: DateTime.parse(kBuiltinRatesAsOf),
    origin: FxOrigin.builtin,
    source: FxOrigin.builtin.label,
  );

  /// Lowercase ISO-4217 the [rates] are quoted against.
  final String base;

  /// `currency -> units of that currency per 1 [base]`. Lowercase keys.
  final Map<String, double> rates;

  final DateTime fetchedAt;

  /// Whether this table was fetched or compiled in.
  final FxOrigin origin;

  /// Which provider served it (`frankfurter.dev`, …), or "built-in".
  final String source;

  /// Rates go stale; a day-old ECB rate is fine for a goal bar, a month-old
  /// one is a lie we shouldn't tell.
  static const maxAge = Duration(days: 7);

  bool isStaleAt(DateTime now) => now.difference(fetchedAt) > maxAge;

  /// A live table can still have holes — the ECB publishes 29 currencies, and
  /// an artist may well be paid in one of the other 140. Rather than drop the
  /// tip, fall through to the baked-in rate for that one currency. So a table
  /// is "live" overall and still built-in for a given currency; [usesBuiltinFor]
  /// says which, and either way the total already renders as "≈".
  double? _perBase(String currency) {
    final c = currency.toLowerCase();
    if (c == base) return 1;
    return rates[c] ?? (base == 'eur' ? kBuiltinEurRates[c] : null);
  }

  bool usesBuiltinFor(String currency) {
    final c = currency.toLowerCase();
    return c != base && !rates.containsKey(c) && kBuiltinEurRates.containsKey(c);
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
    'source': source,
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
    // Only a fetched table is ever cached, so anything read back is live.
    origin: FxOrigin.live,
    source: json['source'] as String? ?? 'unknown',
  );
}
