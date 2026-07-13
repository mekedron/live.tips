/// Every byte an artist or fan can submit passes through this file.
/// Policy: validate atoms against strict patterns, reject over-limit input
/// (never truncate silently), and keep free text plain — no URLs are ever
/// accepted as free-form strings anywhere in the API.

import { methodCurrency } from "./methods";
import type { JarProfile, TipRequest } from "./types";

export type Ok<T> = { ok: true; value: T };
export type Err = { ok: false; status: number; error: string };
export type Result<T> = Ok<T> | Err;

const err = (status: number, error: string): Err => ({ ok: false, status, error });

// ---------------------------------------------------------------------------
// Text scrubbing

/** Bidi overrides/isolates, zero-width chars, and BOM — visual spoofing kit. */
const INVISIBLES = /[\u202A-\u202E\u2066-\u2069\u200B-\u200D\u2060\uFEFF]/g;
/** C0 and C1 control characters (tab/newline become spaces on purpose). */
const CONTROLS = /[\u0000-\u001F\u007F-\u009F]/g;

export function scrubText(raw: string): string {
  return raw.normalize("NFC").replace(INVISIBLES, "").replace(CONTROLS, " ").trim();
}

const BYTES = new TextEncoder();

/**
 * Scrub + enforce caps. Over-limit input is a rejection, not a truncation:
 * a fan who typed a 300-char message should know it didn't fit.
 */
function textField(
  raw: unknown,
  field: string,
  { maxCodePoints, maxBytes, required = false }: { maxCodePoints: number; maxBytes: number; required?: boolean },
): Result<string> {
  if (raw === undefined || raw === null) {
    return required ? err(422, `${field} is required`) : { ok: true, value: "" };
  }
  if (typeof raw !== "string") return err(422, `${field} must be a string`);
  if (raw.length > maxCodePoints * 8) return err(422, `${field} is too long`);
  const clean = scrubText(raw);
  if (required && clean.length === 0) return err(422, `${field} is required`);
  if ([...clean].length > maxCodePoints) return err(422, `${field} is too long (max ${maxCodePoints} characters)`);
  if (BYTES.encode(clean).byteLength > maxBytes) return err(422, `${field} is too long`);
  return { ok: true, value: clean };
}

// ---------------------------------------------------------------------------
// HTML escaping — the single escape function for every SSR sink.

const HTML_ESCAPES: Record<string, string> = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&#39;",
};

export function escapeHtml(text: string): string {
  return text.replace(/[&<>"']/g, (c) => HTML_ESCAPES[c] ?? c);
}

// ---------------------------------------------------------------------------
// Payment-method atoms. The phishing/open-redirect gate: the tip page only
// ever links to URLs composed from these validated pieces.

// Underscore included: test-mode Payment Links look like /test_<code>.
const STRIPE_URL = /^https:\/\/(?:buy|donate)\.stripe\.com\/[A-Za-z0-9_]{1,64}$/;
const REVOLUT_USERNAME = /^[a-z0-9][a-z0-9._-]{2,31}$/;
const MOBILEPAY_BOX_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
// Monzo.me handles go in the URL *path*, so the charset gate is what keeps a
// `/` or `..` out of the composed link. Single-character handles are real
// (monzo.me/a resolves), hence no 3-char floor like Revolut's.
const MONZO_USERNAME = /^[a-z0-9][a-z0-9._-]{0,29}$/;
const CURRENCY = /^[a-z]{3}$/;

/** Currencies whose minor unit equals the major unit (Stripe's list). */
export const ZERO_DECIMAL = new Set([
  "bif", "clp", "djf", "gnf", "jpy", "kmf", "krw", "mga", "pyg", "rwf",
  "ugx", "vnd", "vuv", "xaf", "xof", "xpf",
]);

export function amountBounds(currency: string): { min: number; max: number } {
  return ZERO_DECIMAL.has(currency) ? { min: 1, max: 10_000 } : { min: 100, max: 1_000_000 };
}

// ---------------------------------------------------------------------------
// Body parsing

export const MAX_BODY_BYTES = 8_192;

/** Raw request bytes → JSON object, with the same caps as the worker had. */
export function parseJsonBody(raw: Buffer | string | undefined): Result<Record<string, unknown>> {
  const text = raw === undefined ? "" : typeof raw === "string" ? raw : raw.toString("utf8");
  if (Buffer.byteLength(text, "utf8") > MAX_BODY_BYTES) return err(413, "request body too large");
  try {
    const parsed: unknown = JSON.parse(text);
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return err(422, "body must be a JSON object");
    }
    return { ok: true, value: parsed as Record<string, unknown> };
  } catch {
    return err(422, "invalid JSON");
  }
}

function rejectUnknownKeys(obj: Record<string, unknown>, allowed: readonly string[], where: string): Err | null {
  for (const key of Object.keys(obj)) {
    if (!allowed.includes(key)) return err(422, `unknown field "${key}" in ${where}`);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Profile validation (identical for create and update)

const PROFILE_KEYS = ["artistName", "message", "currency", "methods"] as const;
const METHOD_KEYS = ["stripeUrl", "revolutUsername", "mobilepayBoxId", "monzoUsername"] as const;

export function validateProfile(body: Record<string, unknown>): Result<JarProfile> {
  const unknown = rejectUnknownKeys(body, PROFILE_KEYS, "profile");
  if (unknown) return unknown;

  const artistName = textField(body["artistName"], "artistName", { maxCodePoints: 50, maxBytes: 200, required: true });
  if (!artistName.ok) return artistName;
  const message = textField(body["message"], "message", { maxCodePoints: 200, maxBytes: 800 });
  if (!message.ok) return message;

  const currencyRaw = body["currency"];
  if (typeof currencyRaw !== "string" || !CURRENCY.test(currencyRaw.toLowerCase().trim())) {
    return err(422, "currency must be a 3-letter code");
  }
  const currency = currencyRaw.toLowerCase().trim();

  const methodsRaw = body["methods"];
  if (typeof methodsRaw !== "object" || methodsRaw === null || Array.isArray(methodsRaw)) {
    return err(422, "methods must be an object");
  }
  const methodsObj = methodsRaw as Record<string, unknown>;
  const unknownMethod = rejectUnknownKeys(methodsObj, METHOD_KEYS, "methods");
  if (unknownMethod) return unknownMethod;

  const methods: JarProfile["methods"] = {};

  if (methodsObj["stripeUrl"] !== undefined) {
    const v = methodsObj["stripeUrl"];
    if (typeof v !== "string" || !STRIPE_URL.test(v.trim())) {
      return err(422, "stripeUrl must be a buy.stripe.com or donate.stripe.com payment link");
    }
    methods.stripeUrl = v.trim();
  }
  if (methodsObj["revolutUsername"] !== undefined) {
    const v = methodsObj["revolutUsername"];
    if (typeof v !== "string") return err(422, "revolutUsername must be a string");
    const lowered = v.trim().toLowerCase().replace(/^@/, "");
    if (!REVOLUT_USERNAME.test(lowered)) return err(422, "revolutUsername is not a valid Revolut username");
    methods.revolutUsername = lowered;
  }
  if (methodsObj["mobilepayBoxId"] !== undefined) {
    const v = methodsObj["mobilepayBoxId"];
    if (typeof v !== "string" || !MOBILEPAY_BOX_ID.test(v.trim().toLowerCase())) {
      return err(422, "mobilepayBoxId must be a MobilePay Box UUID");
    }
    // No currency lock: a Box always collects EUR (see methods.ts), whatever
    // the jar's own currency is. The tip form prices the tip accordingly.
    methods.mobilepayBoxId = v.trim().toLowerCase();
  }
  if (methodsObj["monzoUsername"] !== undefined) {
    const v = methodsObj["monzoUsername"];
    if (typeof v !== "string") return err(422, "monzoUsername must be a string");
    const lowered = v.trim().toLowerCase().replace(/^@/, "");
    if (!MONZO_USERNAME.test(lowered)) return err(422, "monzoUsername is not a valid Monzo.me handle");
    // Likewise unlocked: Monzo.me always collects GBP (see methods.ts).
    methods.monzoUsername = lowered;
  }

  if (!methods.stripeUrl && !methods.revolutUsername && !methods.mobilepayBoxId && !methods.monzoUsername) {
    return err(422, "at least one payment method is required");
  }

  return { ok: true, value: { artistName: artistName.value, message: message.value, currency, methods } };
}

// ---------------------------------------------------------------------------
// Tip validation (structure only — the tip endpoint checks method availability
// against the profile and applies per-jar rate limits)

const TIP_KEYS = ["method", "amountMinor", "name", "message", "turnstileToken"] as const;

export function validateTip(
  body: Record<string, unknown>,
  jarCurrency: string,
): Result<TipRequest & { turnstileToken: string }> {
  const unknown = rejectUnknownKeys(body, TIP_KEYS, "tip");
  if (unknown) return unknown;

  const method = body["method"];
  if (method !== "revolut" && method !== "mobilepay" && method !== "monzo") {
    return err(422, "method must be revolut, mobilepay or monzo");
  }

  // The amount is denominated in the currency the METHOD collects — EUR for a
  // MobilePay Box, GBP for Monzo — not necessarily the jar's. Bounds (and the
  // zero-decimal question) have to follow it, or a JPY jar would mis-scale a
  // MobilePay tip.
  const amount = body["amountMinor"];
  const { min, max } = amountBounds(methodCurrency(method, jarCurrency));
  if (typeof amount !== "number" || !Number.isSafeInteger(amount) || amount < min || amount > max) {
    return err(422, `amountMinor must be an integer between ${min} and ${max}`);
  }

  const name = textField(body["name"], "name", { maxCodePoints: 40, maxBytes: 160 });
  if (!name.ok) return name;
  // The deep-link note packs "name: message" — a colon in the name would
  // make that unparseable, so it is rejected outright (mirrored client-side).
  if (name.value.includes(":")) return err(422, "name must not contain a colon");

  const message = textField(body["message"], "message", { maxCodePoints: 200, maxBytes: 800 });
  if (!message.ok) return message;

  const token = body["turnstileToken"];
  if (typeof token !== "string" || token.length === 0 || token.length > 3_000) {
    return err(422, "turnstileToken is required");
  }

  return {
    ok: true,
    value: { method, amountMinor: amount, name: name.value, message: message.value, turnstileToken: token },
  };
}

/** jarId as it appears in URLs — reject junk before it ever touches Firestore. */
export function isValidJarId(id: string): boolean {
  return /^[0-9a-z]{20,32}$/.test(id);
}

/** deviceId as the app mints it (opaque install id) — a safe Firestore doc id. */
export function isValidDeviceId(id: string): boolean {
  return /^[A-Za-z0-9_-]{1,64}$/.test(id);
}
