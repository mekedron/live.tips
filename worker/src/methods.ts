/// Which currency a method actually collects in.
///
/// A MobilePay Box settles in euros and a Monzo.me link in sterling, whatever
/// the jar's own currency says — so the currency of a tip is a property of the
/// METHOD, not of the jar. Revolut converts on its side, so it takes the jar's
/// currency as given, and so does a Stripe link (its price defines it).
///
/// This table is what lets one tip page offer all three at once: the jar's
/// currency stops being a lock and becomes the default that the unfixed methods
/// inherit. Everything downstream — the amount the donor types, the bounds it
/// is checked against, the deep link, and the currency stamped on the tip the
/// artist's device records — resolves through here, so a £5 Monzo tip is a £5
/// Monzo tip on a EUR jar.

import type { TipMethod } from "./types";

/** Every relay method, in the fixed order the donor page lists them. */
export const TIP_METHODS: TipMethod[] = ["revolut", "mobilepay", "monzo"];

/** Methods that collect in one currency, always. */
export const FIXED_METHOD_CURRENCY: Partial<Record<TipMethod, string>> = {
  mobilepay: "eur",
  monzo: "gbp",
};

export function methodCurrency(method: TipMethod, jarCurrency: string): string {
  return FIXED_METHOD_CURRENCY[method] ?? jarCurrency;
}
