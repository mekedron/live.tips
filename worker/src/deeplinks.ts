/// Composes payment deep links from validated atoms onto hardcoded hosts.
/// These are UNOFFICIAL surfaces — Revolut and MobilePay document none of
/// these parameters — so every assumption lives behind a constant here.

import { ZERO_DECIMAL } from "./validate";
import type { JarProfile, TipRequest } from "./types";

/**
 * Empirically VERIFIED (2026-07): qr.mobilepay.fi renders `amount=1234` as
 * "12,34 €" — the parameter is in cents.
 */
export const MOBILEPAY_AMOUNT_UNIT: "minor" = "minor";

/**
 * revolut.me parameters are entirely undocumented. Nikita's own demo link
 * used `amount=500` for a €5 tip, so we start from "minor" — but this MUST
 * be re-verified with a real Revolut account before launch (open
 * revolut.me/<user>?amount=500&currency=eur and check the prefilled figure).
 * Worst case we flip this constant or stop prefilling; the WS event — not
 * the deep link — is what drives the stage.
 */
export const REVOLUT_AMOUNT_UNIT: "major" | "minor" = "minor";

/** Revolut rejects sub-€1 requests; enforced here and in the donor form. */
export const REVOLUT_MIN_MINOR = 100;

/**
 * Undocumented; MobilePay shows the message on its hosted page. Probe the
 * real limit before launch and adjust — conservative until then.
 */
export const MOBILEPAY_MESSAGE_MAX = 100;

/** Equally undocumented for revolut.me notes — conservative until probed. */
export const REVOLUT_NOTE_MAX = 140;

/** `"name: message"` — the colon is why names must not contain one. */
export function packNote(name: string, message: string): string {
  if (name && message) return `${name}: ${message}`;
  return name || message;
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

/** Bare method links (no prefill) — donor-page fallbacks when JS/API fails. */
export function bareMethodUrl(profile: JarProfile, method: TipRequest["method"]): string | null {
  if (method === "revolut" && profile.methods.revolutUsername) {
    return `https://revolut.me/${encodeURIComponent(profile.methods.revolutUsername)}`;
  }
  if (method === "mobilepay" && profile.methods.mobilepayBoxId) {
    return `https://qr.mobilepay.fi/box/${encodeURIComponent(profile.methods.mobilepayBoxId)}/pay-in`;
  }
  return null;
}

export function buildRedirectUrl(profile: JarProfile, tip: TipRequest): string | null {
  const note = packNote(tip.name, tip.message);
  if (tip.method === "revolut" && profile.methods.revolutUsername) {
    return buildRevolutUrl(profile.methods.revolutUsername, tip.amountMinor, profile.currency, note);
  }
  if (tip.method === "mobilepay" && profile.methods.mobilepayBoxId) {
    return buildMobilePayUrl(profile.methods.mobilepayBoxId, tip.amountMinor, note);
  }
  return null;
}
