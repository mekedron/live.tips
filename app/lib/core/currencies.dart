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

/// Currencies whose Stripe amounts are expressed in whole units
/// (not multiplied by 100). https://docs.stripe.com/currencies#zero-decimal
const Set<String> kZeroDecimalCurrencies = {
  'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga',
  'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf',
};
