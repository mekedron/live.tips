/// Curated list of currencies for the tip jar picker.
///
/// Stripe supports far more — this keeps the dropdown manageable. Add more
/// freely; everything else in the app handles any ISO code.
const List<String> kSupportedCurrencies = [
  'usd',
  'eur',
  'gbp',
  'cad',
  'aud',
  'nzd',
  'chf',
  'sek',
  'nok',
  'dkk',
  'pln',
  'czk',
  'ron',
  'huf',
  'jpy',
  'mxn',
  'brl',
  'sgd',
  'hkd',
  'ils',
  'aed',
  'inr',
];

/// Human names for the picker ("USD — US Dollar"). Any code missing here
/// still works — it just shows as the bare uppercase code.
const Map<String, String> kCurrencyNames = {
  'usd': 'US Dollar',
  'eur': 'Euro',
  'gbp': 'British Pound',
  'cad': 'Canadian Dollar',
  'aud': 'Australian Dollar',
  'nzd': 'New Zealand Dollar',
  'chf': 'Swiss Franc',
  'sek': 'Swedish Krona',
  'nok': 'Norwegian Krone',
  'dkk': 'Danish Krone',
  'pln': 'Polish Złoty',
  'czk': 'Czech Koruna',
  'ron': 'Romanian Leu',
  'huf': 'Hungarian Forint',
  'jpy': 'Japanese Yen',
  'mxn': 'Mexican Peso',
  'brl': 'Brazilian Real',
  'sgd': 'Singapore Dollar',
  'hkd': 'Hong Kong Dollar',
  'ils': 'Israeli Shekel',
  'aed': 'UAE Dirham',
  'inr': 'Indian Rupee',
};

/// "USD — US Dollar", or just "USD" for codes we have no name for.
String currencyLabel(String code) {
  final name = kCurrencyNames[code.toLowerCase()];
  final upper = code.toUpperCase();
  return name == null ? upper : '$upper — $name';
}

/// Currencies whose Stripe amounts are expressed in whole units
/// (not multiplied by 100). https://docs.stripe.com/currencies#zero-decimal
const Set<String> kZeroDecimalCurrencies = {
  'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga',
  'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf',
};
