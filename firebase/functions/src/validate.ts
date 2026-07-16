/// Every byte an artist or fan can submit passes through this file.
/// Policy: validate atoms against strict patterns, reject over-limit input
/// (never truncate silently), and keep free text plain — no URLs are ever
/// accepted as free-form strings anywhere in the API.

import { methodCurrency } from "./methods";
import type { JarProfile, RequestsConfig, RequestsLive, RequestSong, TipRequest } from "./types";

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
// Song requests (#64): the artist-published config and live queue state.

/** Same shape as the app's install ids: URL-safe, a safe Firestore map key. */
export const SONG_ID = /^[A-Za-z0-9_-]{1,32}$/;

const REQUESTS_CONFIG_KEYS = ["enabled", "defaultPriceMinor", "methods", "songs"] as const;
const SONG_KEYS = ["id", "title", "artist", "priceMinor", "stripeUrl"] as const;
/** Requests may also be paid over Stripe; the relay POST still only ever sees
 * the three relay methods (a Stripe request never reaches it). */
const REQUEST_METHODS = ["stripe", "revolut", "mobilepay", "monzo"] as const;

export const MAX_REQUEST_SONGS = 100;
export const MAX_REQUEST_VOTES = 50;

export function validateRequestsConfig(
  body: Record<string, unknown>,
  jarCurrency: string,
): Result<RequestsConfig> {
  const unknown = rejectUnknownKeys(body, REQUESTS_CONFIG_KEYS, "requestsConfig");
  if (unknown) return unknown;

  const enabled = body["enabled"];
  if (typeof enabled !== "boolean") return err(422, "enabled must be a boolean");

  const { min, max } = amountBounds(jarCurrency);

  // Requests are priced in the JAR's currency (the config carries no currency
  // of its own), so every price bounds-checks against it.
  const defaultPrice = body["defaultPriceMinor"];
  if (typeof defaultPrice !== "number" || !Number.isSafeInteger(defaultPrice)) {
    return err(422, "defaultPriceMinor must be an integer");
  }
  // A disabled config may park a 0 default (nothing is purchasable through
  // it); an enabled one must carry a chargeable price.
  if ((enabled || defaultPrice !== 0) && (defaultPrice < min || defaultPrice > max)) {
    return err(422, `defaultPriceMinor must be between ${min} and ${max}`);
  }

  const methodsRaw = body["methods"];
  if (!Array.isArray(methodsRaw)) return err(422, "methods must be an array");
  const methods: string[] = [];
  for (const m of methodsRaw) {
    if (typeof m !== "string" || !(REQUEST_METHODS as readonly string[]).includes(m)) {
      return err(422, "methods must be a subset of stripe, revolut, mobilepay, monzo");
    }
    if (methods.includes(m)) return err(422, "methods must not repeat");
    methods.push(m);
  }

  const songsRaw = body["songs"];
  if (!Array.isArray(songsRaw)) return err(422, "songs must be an array");
  if (songsRaw.length > MAX_REQUEST_SONGS) {
    return err(422, `songs must not exceed ${MAX_REQUEST_SONGS} entries`);
  }
  if (enabled && songsRaw.length === 0) return err(422, "an enabled config needs at least one song");

  const songs: RequestSong[] = [];
  const seenIds = new Set<string>();
  for (const raw of songsRaw) {
    if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
      return err(422, "each song must be an object");
    }
    const songObj = raw as Record<string, unknown>;
    const unknownSong = rejectUnknownKeys(songObj, SONG_KEYS, "song");
    if (unknownSong) return unknownSong;

    const id = songObj["id"];
    if (typeof id !== "string" || !SONG_ID.test(id)) return err(422, "song id is not valid");
    // Duplicate ids would make the tip POST's lookup ambiguous.
    if (seenIds.has(id)) return err(422, "song ids must be unique");
    seenIds.add(id);

    const title = textField(songObj["title"], "title", { maxCodePoints: 60, maxBytes: 240, required: true });
    if (!title.ok) return title;
    const artist = textField(songObj["artist"], "artist", { maxCodePoints: 60, maxBytes: 240 });
    if (!artist.ok) return artist;

    const song: RequestSong = { id, title: title.value };
    if (artist.value) song.artist = artist.value;

    if (songObj["priceMinor"] !== undefined) {
      const price = songObj["priceMinor"];
      if (typeof price !== "number" || !Number.isSafeInteger(price) || price < min || price > max) {
        return err(422, `priceMinor must be an integer between ${min} and ${max}`);
      }
      song.priceMinor = price;
    }
    if (songObj["stripeUrl"] !== undefined) {
      // The same phishing gate every profile Stripe link passes.
      const v = songObj["stripeUrl"];
      if (typeof v !== "string" || !STRIPE_URL.test(v.trim())) {
        return err(422, "stripeUrl must be a buy.stripe.com or donate.stripe.com payment link");
      }
      song.stripeUrl = v.trim();
    }
    songs.push(song);
  }

  return { ok: true, value: { enabled, defaultPriceMinor: defaultPrice, methods, songs } };
}

const QUEUE_ENTRY_KEYS = ["t", "c", "s"] as const;
export const MAX_QUEUE_ENTRIES = 150;
// One entry's bounds — shared with the server-side bump (tip-destination.ts),
// which clamps instead of rejecting: a fan's accepted tip must never be
// refused over a display aggregate's ceiling.
export const MAX_QUEUE_ENTRY_TOTAL = 100_000_000;
export const MAX_QUEUE_ENTRY_COUNT = 10_000;

/** The live per-song totals the app publishes (requestsLive.songs). */
export function validateRequestsQueue(
  body: Record<string, unknown>,
): Result<RequestsLive["songs"]> {
  if (Object.keys(body).length > MAX_QUEUE_ENTRIES) {
    return err(422, `queue must not exceed ${MAX_QUEUE_ENTRIES} entries`);
  }
  const songs: RequestsLive["songs"] = {};
  for (const [id, raw] of Object.entries(body)) {
    if (!SONG_ID.test(id)) return err(422, "queue song id is not valid");
    if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
      return err(422, "each queue entry must be an object");
    }
    const entry = raw as Record<string, unknown>;
    const unknown = rejectUnknownKeys(entry, QUEUE_ENTRY_KEYS, "queue entry");
    if (unknown) return unknown;
    const t = entry["t"];
    if (typeof t !== "number" || !Number.isSafeInteger(t) || t < 0 || t > MAX_QUEUE_ENTRY_TOTAL) {
      return err(422, `queue entry t must be an integer between 0 and ${MAX_QUEUE_ENTRY_TOTAL}`);
    }
    const c = entry["c"];
    if (typeof c !== "number" || !Number.isSafeInteger(c) || c < 0 || c > MAX_QUEUE_ENTRY_COUNT) {
      return err(422, `queue entry c must be an integer between 0 and ${MAX_QUEUE_ENTRY_COUNT}`);
    }
    const s = entry["s"];
    if (s !== "q" && s !== "p" && s !== "k") return err(422, "queue entry s must be q, p or k");
    songs[id] = { t, c, s };
  }
  return { ok: true, value: songs };
}

/**
 * The statuses-only publish (#71 Phase 3): on a routed jar the server computes
 * each entry's totals at tip-accept time, and the app's leader-published
 * verdicts shrink to this flat songId → "q" | "p" | "k" map — the full map
 * every time, so a cleared verdict ("q") and a status a race skipped both
 * converge on the next publish.
 */
export function validateRequestsStatuses(
  body: Record<string, unknown>,
): Result<Record<string, "q" | "p" | "k">> {
  if (Object.keys(body).length > MAX_QUEUE_ENTRIES) {
    return err(422, `statuses must not exceed ${MAX_QUEUE_ENTRIES} entries`);
  }
  const statuses: Record<string, "q" | "p" | "k"> = {};
  for (const [id, s] of Object.entries(body)) {
    if (!SONG_ID.test(id)) return err(422, "statuses song id is not valid");
    if (s !== "q" && s !== "p" && s !== "k") return err(422, "status must be q, p or k");
    statuses[id] = s;
  }
  return { ok: true, value: statuses };
}

// ---------------------------------------------------------------------------
// Tip validation (structure only — the tip endpoint checks method availability
// against the profile and applies per-jar rate limits)

// songId/votes stay OPTIONAL members of the strict key set: pages cached from
// before the requests feature keep POSTing plain tips unchanged.
const TIP_KEYS = ["method", "amountMinor", "name", "message", "turnstileToken", "songId", "votes"] as const;

export function validateTip(
  body: Record<string, unknown>,
  jarCurrency: string,
  requestsConfig?: RequestsConfig,
): Result<TipRequest & { turnstileToken: string }> {
  const unknown = rejectUnknownKeys(body, TIP_KEYS, "tip");
  if (unknown) return unknown;

  const method = body["method"];
  if (method !== "revolut" && method !== "mobilepay" && method !== "monzo") {
    return err(422, "method must be revolut, mobilepay or monzo");
  }

  let amountMinor: number;
  let songId: string | undefined;
  let songTitle: string | undefined;

  if (body["songId"] !== undefined) {
    // Request mode: the SERVER prices the tip from its own config — a fan-sent
    // amount is refused outright rather than reconciled.
    if (body["amountMinor"] !== undefined) {
      return err(422, "amountMinor must not accompany songId");
    }
    const idRaw = body["songId"];
    if (typeof idRaw !== "string" || !SONG_ID.test(idRaw)) return err(422, "songId is not valid");
    const song = requestsConfig?.songs.find((s) => s.id === idRaw);
    if (!requestsConfig || !song) return err(422, "unknown song");
    if (!requestsConfig.methods.includes(method)) {
      return err(422, "method not available for requests");
    }
    // Requests are priced in the jar's currency, so only methods that COLLECT
    // that currency may carry one: Stripe/Revolut always do, a MobilePay Box
    // only on a EUR jar, Monzo only on a GBP jar. Anything else would silently
    // charge the fan the same number in a different currency.
    if (methodCurrency(method, jarCurrency) !== jarCurrency) {
      return err(422, "method not available for requests in this currency");
    }
    let votes = 1;
    if (body["votes"] !== undefined) {
      const v = body["votes"];
      if (typeof v !== "number" || !Number.isSafeInteger(v) || v < 1 || v > MAX_REQUEST_VOTES) {
        return err(422, `votes must be an integer between 1 and ${MAX_REQUEST_VOTES}`);
      }
      votes = v;
    }
    const { min, max } = amountBounds(jarCurrency);
    amountMinor = (song.priceMinor ?? requestsConfig.defaultPriceMinor) * votes;
    if (amountMinor < min || amountMinor > max) {
      return err(422, `votes price the request outside ${min}–${max}`);
    }
    songId = idRaw;
    songTitle = song.title;
  } else {
    if (body["votes"] !== undefined) return err(422, "votes require a songId");
    // The amount is denominated in the currency the METHOD collects — EUR for
    // a MobilePay Box, GBP for Monzo — not necessarily the jar's. Bounds (and
    // the zero-decimal question) have to follow it, or a JPY jar would
    // mis-scale a MobilePay tip.
    const amount = body["amountMinor"];
    const { min, max } = amountBounds(methodCurrency(method, jarCurrency));
    if (typeof amount !== "number" || !Number.isSafeInteger(amount) || amount < min || amount > max) {
      return err(422, `amountMinor must be an integer between ${min} and ${max}`);
    }
    amountMinor = amount;
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
    value: {
      method,
      amountMinor,
      name: name.value,
      message: message.value,
      turnstileToken: token,
      // Absent keys, not undefined values: plain tips keep their exact shape
      // (and Firestore refuses undefined in any case).
      ...(songId !== undefined && songTitle !== undefined ? { songId, songTitle } : {}),
    },
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
