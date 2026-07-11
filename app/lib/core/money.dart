import 'package:intl/intl.dart';

import 'currencies.dart';

/// How many minor units (cents) make up one major unit for [currency].
int minorUnitsPerMajor(String currency) =>
    kZeroDecimalCurrencies.contains(currency.toLowerCase()) ? 1 : 100;

/// Converts a user-entered major amount ("12.50") to Stripe minor units.
/// Returns null if [input] is not a valid positive number.
int? parseMajorToMinor(String input, String currency) {
  final normalized = input.trim().replaceAll(',', '.').replaceAll(' ', '');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value <= 0 || !value.isFinite) return null;
  return (value * minorUnitsPerMajor(currency)).round();
}

/// Formats a Stripe minor-unit amount as a localized currency string.
///
/// Whole amounts are shown without decimals ("€50"), fractional ones with
/// two ("€12.50"). Zero-decimal currencies (JPY, …) never show decimals.
/// Set [approximate] when the figure had to convert currencies to exist —
/// a set that mixed a £ tip into a € total. It renders "≈ €95", because the
/// number depends on today's reference rate and isn't the exact sum of any
/// ledger. Per-tip amounts are never approximate and never take this flag.
String formatAmount(int amountMinor, String currency,
    {bool alwaysShowDecimals = false, bool approximate = false}) {
  final perMajor = minorUnitsPerMajor(currency);
  final value = amountMinor / perMajor;
  final hasFraction = amountMinor % perMajor != 0;
  final decimalDigits =
      perMajor == 1 ? 0 : (hasFraction || alwaysShowDecimals ? 2 : 0);
  final formatted = NumberFormat.simpleCurrency(
    name: currency.toUpperCase(),
    decimalDigits: decimalDigits,
  ).format(value);
  return approximate ? '≈ $formatted' : formatted;
}

/// Bare number without symbol, for text fields ("50" / "12.50").
String formatMajorPlain(int amountMinor, String currency) {
  final perMajor = minorUnitsPerMajor(currency);
  if (amountMinor % perMajor == 0) return (amountMinor ~/ perMajor).toString();
  return (amountMinor / perMajor).toStringAsFixed(2);
}
