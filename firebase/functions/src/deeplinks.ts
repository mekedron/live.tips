/// Composes payment deep links from validated atoms onto hardcoded hosts.
/// These are UNOFFICIAL surfaces — Revolut, MobilePay and Monzo document none
/// of these parameters — so every assumption lives behind a constant here.

import { ZERO_DECIMAL } from "./validate";
import type { JarProfile, TipRequest } from "./types";

/**
 * Empirically VERIFIED (2026-07): qr.mobilepay.fi renders `amount=1234` as
 * "12,34 €" — the parameter is in cents.
 */
export const MOBILEPAY_AMOUNT_UNIT: "minor" = "minor";

/**
 * VERIFIED empirically (2026-07-07, real revolut.me page): `amount=500`
 * with `currency=eur` prefills €5 — the parameter is in minor units.
 */
export const REVOLUT_AMOUNT_UNIT: "major" | "minor" = "minor";

/** Revolut rejects sub-€1 requests; enforced here and in the tip form. */
export const REVOLUT_MIN_MINOR = 100;

/**
 * VERIFIED empirically (2026-07-11, real monzo.me page): the amount is a PATH
 * segment in MAJOR units, not a query param in minor ones — `/daniel/5` bills
 * "£5.00" and `/daniel/500` bills "£500.00". Decimals ride along fine:
 * `/daniel/5.50` bills "£5.50". Getting this backwards would overcharge a
 * fan 100×, which is why it is spelled out rather than inferred.
 */
export const MONZO_AMOUNT_UNIT: "major" | "minor" = "major";

/** Monzo.me is a sterling-only surface — no currency parameter exists. */
export const MONZO_CURRENCY = "gbp";

/**
 * VERIFIED empirically (2026-07-07): qr.mobilepay.fi renders a 200-char
 * `message` untruncated, so the full message + packed name fits.
 */
export const MOBILEPAY_MESSAGE_MAX = 200;

/**
 * VERIFIED empirically (2026-07-07): the revolut.me note field shows a
 * hard "n / 64" character counter — clamp to what actually fits.
 */
export const REVOLUT_NOTE_MAX = 64;

/**
 * NOT a verified platform limit. monzo.me echoed a 260-char `d` back
 * untruncated (2026-07-11), and the description is never rendered on the web
 * page at all — it is handed to the Monzo app, whose own reference field we
 * cannot inspect from here. So this is our own conservative clamp, set to the
 * same 200 the tip form already caps messages at: a message that fits the
 * form fits the link, and nothing is silently dropped in between.
 */
export const MONZO_DESCRIPTION_MAX = 200;

/** `"name: message"` — the colon is why names must not contain one. */
export function packNote(name: string, message: string): string {
  if (name && message) return `${name}: ${message}`;
  return name || message;
}

/**
 * Song-request note: `"♪ Title — name: message"`. The title goes FIRST so the
 * per-method clamp (Revolut's is 64 code points) sacrifices the fan's message
 * before the one thing the artist must read off the payment — which song was
 * paid for. The title is the server's own config lookup, never fan input.
 */
export function packRequestNote(title: string, name: string, message: string): string {
  const rest = packNote(name, message);
  return rest ? `♪ ${title} — ${rest}` : `♪ ${title}`;
}

export function clampNote(note: string, maxCodePoints: number): string {
  const points = [...note];
  if (points.length <= maxCodePoints) return note;
  return points.slice(0, maxCodePoints - 1).join("") + "…";
}

function amountParam(amountMinor: number, currency: string, unit: "major" | "minor"): string {
  if (unit === "minor" || ZERO_DECIMAL.has(currency)) return String(amountMinor);
  const major = amountMinor / 100;
  return Number.isInteger(major) ? String(major) : major.toFixed(2);
}

export function buildRevolutUrl(username: string, amountMinor: number, currency: string, note: string): string {
  const url = new URL(`https://revolut.me/${encodeURIComponent(username)}`);
  url.searchParams.set("amount", amountParam(amountMinor, currency, REVOLUT_AMOUNT_UNIT));
  url.searchParams.set("currency", currency);
  if (note) url.searchParams.set("note", clampNote(note, REVOLUT_NOTE_MAX));
  return url.toString();
}

export function buildMobilePayUrl(boxId: string, amountMinor: number, note: string): string {
  const url = new URL(`https://qr.mobilepay.fi/box/${encodeURIComponent(boxId)}/pay-in`);
  url.searchParams.set("amount", String(amountMinor));
  if (note) url.searchParams.set("message", clampNote(note, MOBILEPAY_MESSAGE_MAX));
  return url.toString();
}

export function buildMonzoUrl(username: string, amountMinor: number, note: string): string {
  const amount = amountParam(amountMinor, MONZO_CURRENCY, MONZO_AMOUNT_UNIT);
  const url = new URL(`https://monzo.me/${encodeURIComponent(username)}/${amount}`);
  if (note) url.searchParams.set("d", clampNote(note, MONZO_DESCRIPTION_MAX));
  return url.toString();
}

/** Bare method links (no prefill) — tip-page fallbacks when JS/API fails. */
export function bareMethodUrl(profile: JarProfile, method: TipRequest["method"]): string | null {
  if (method === "revolut" && profile.methods.revolutUsername) {
    return `https://revolut.me/${encodeURIComponent(profile.methods.revolutUsername)}`;
  }
  if (method === "mobilepay" && profile.methods.mobilepayBoxId) {
    return `https://qr.mobilepay.fi/box/${encodeURIComponent(profile.methods.mobilepayBoxId)}/pay-in`;
  }
  if (method === "monzo" && profile.methods.monzoUsername) {
    return `https://monzo.me/${encodeURIComponent(profile.methods.monzoUsername)}`;
  }
  return null;
}

export function buildRedirectUrl(profile: JarProfile, tip: TipRequest): string | null {
  const note = tip.songTitle !== undefined
    ? packRequestNote(tip.songTitle, tip.name, tip.message)
    : packNote(tip.name, tip.message);
  if (tip.method === "revolut" && profile.methods.revolutUsername) {
    return buildRevolutUrl(profile.methods.revolutUsername, tip.amountMinor, profile.currency, note);
  }
  if (tip.method === "mobilepay" && profile.methods.mobilepayBoxId) {
    return buildMobilePayUrl(profile.methods.mobilepayBoxId, tip.amountMinor, note);
  }
  if (tip.method === "monzo" && profile.methods.monzoUsername) {
    return buildMonzoUrl(profile.methods.monzoUsername, tip.amountMinor, note);
  }
  return null;
}
