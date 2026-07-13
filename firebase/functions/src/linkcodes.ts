/// QR add-device link codes — the pure logic (no Firestore in this file, so
/// all of it is unit-testable). A link code is a short-lived (2 min),
/// single-use, four-step handshake between a signed-in device (A) and a new
/// device (B):
///
///   pending   — A minted the code (createLinkCode) and shows it as a QR
///   claimed   — B scanned it (redeemLinkCode) and holds the redeem nonce
///   confirmed — A approved the request on screen (confirmLinkCode)
///   used      — B traded code+nonce for a custom token (collectLinkToken)
///   expired   — timed out, attempt-capped, or hourly-swept
///
/// Anti-phishing shape: the nonce is minted at REDEEM time and returned only
/// to the redeeming device — it never appears in the QR. A photographed QR
/// (the code alone) is therefore useless twice over: redeeming it only parks
/// the code in 'claimed' until the owner taps confirm on the signed-in
/// device, and collecting the token requires the nonce that only the first
/// redeemer holds.

import { randomBytes } from "node:crypto";
import { scrubText } from "./validate";

/** A code lives 2 minutes — long enough to scan and tap, too short to shop around. */
export const LINK_CODE_TTL_MS = 2 * 60_000;

/** Redeem/collect attempts per code before it is force-expired. */
export const MAX_LINK_ATTEMPTS = 5;

/** Open (pending/claimed, unexpired) codes one account may hold at once. */
export const MAX_LIVE_LINK_CODES = 3;

export const REQUESTER_NAME_MAX = 40;
export const REQUESTER_PLATFORM_MAX = 20;

export type LinkCodeStatus = "pending" | "claimed" | "confirmed" | "used" | "expired";

/** The slice of linkCodes/{codeId} the transition guards need. */
export interface LinkCodeSnapshot {
  status: LinkCodeStatus;
  expiresAtMs: number;
  attempts: number;
}

/**
 * 16 random bytes → 22-char unpadded base64url. 128 bits: the code doubles
 * as the Firestore document id and travels inside a QR, so it must be
 * unguessable and enumeration-proof, like jarIds.
 */
export function newLinkCode(): string {
  return randomBytes(16).toString("base64url");
}

/** Same shape as the code; minted at redeem time, stored only as sha256. */
export function newLinkNonce(): string {
  return randomBytes(16).toString("base64url");
}

/** Code/nonce as they appear on the wire — reject junk before Firestore. */
export function isValidLinkCode(value: string): boolean {
  return /^[A-Za-z0-9_-]{22}$/.test(value);
}

/**
 * Anonymous accounts may not mint link codes or revoke all devices: an
 * anonymous account signed into a second device (or with its sessions
 * revoked) is unrecoverable — nothing exists to sign back in with. A missing
 * sign_in_provider claim fails closed as anonymous.
 */
export function isAnonymousProvider(provider: string | undefined): boolean {
  return provider === undefined || provider === "anonymous";
}

export function linkCodeExpiryMs(nowMs: number): number {
  return nowMs + LINK_CODE_TTL_MS;
}

/**
 * Requester name/platform as stored on the code doc for device A's confirm
 * screen: scrubbed like every other user string, then TRUNCATED to the cap
 * (unlike fan text, nothing is lost by shortening a device label; a rejection
 * would only add a failure mode to the handshake). Returns null for
 * non-strings, absurdly long input, and strings that scrub to nothing.
 */
export function requesterField(raw: unknown, maxCodePoints: number): string | null {
  if (typeof raw !== "string" || raw.length > maxCodePoints * 8) return null;
  const clean = scrubText(raw);
  if (clean.length === 0) return null;
  const points = [...clean];
  return points.length <= maxCodePoints ? clean : points.slice(0, maxCodePoints).join("");
}

// ---------------------------------------------------------------------------
// Status-transition guards. Pure: the handlers run these inside a Firestore
// transaction and translate the verdicts into writes + HttpsErrors.

export type LinkDecision =
  | { ok: true; pending?: boolean }
  | { ok: false; expire: boolean; countAttempt: boolean; message: string };

const OK: LinkDecision = { ok: true };

function reject(
  message: string,
  opts: { expire?: boolean; countAttempt?: boolean } = {},
): LinkDecision {
  return { ok: false, expire: opts.expire === true, countAttempt: opts.countAttempt === true, message };
}

/** Only live statuses may be flipped to 'expired' — never rewrite 'used'. */
function expirable(status: LinkCodeStatus): boolean {
  return status === "pending" || status === "claimed" || status === "confirmed";
}

/** redeemLinkCode: pending + unexpired + under the attempt cap → claimed. */
export function decideRedeem(code: LinkCodeSnapshot, nowMs: number): LinkDecision {
  if (code.expiresAtMs <= nowMs) return reject("code expired", { expire: expirable(code.status) });
  if (code.status !== "pending") return reject("code already redeemed");
  if (code.attempts >= MAX_LINK_ATTEMPTS) return reject("too many attempts", { expire: true });
  return OK;
}

/** confirmLinkCode: claimed + unexpired → confirmed. (Owner check is the handler's.) */
export function decideConfirm(code: LinkCodeSnapshot, nowMs: number): LinkDecision {
  if (code.expiresAtMs <= nowMs) return reject("code expired", { expire: expirable(code.status) });
  if (code.status === "pending") return reject("code has not been scanned yet");
  if (code.status !== "claimed") return reject("code is no longer confirmable");
  return OK;
}

/**
 * collectLinkToken: confirmed + unexpired + matching nonce → used. A claimed
 * (not-yet-confirmed) code with the RIGHT nonce is the poll case — device B
 * asking "has the owner tapped yet?" — and answers {ok, pending} instead of
 * an error, so the client needs no string matching to keep waiting. A wrong
 * nonce burns an attempt; the cap then force-expires the code, so even a
 * leaked codeId gives at most 5 guesses at a 128-bit nonce.
 *
 * The nonce is checked BEFORE the status, and that order is the security
 * property, not a detail. A stranger who photographed the QR holds the codeId
 * and nothing else; checking status first answered them "invalid nonce" for a
 * claimed/confirmed code but "code is not collectable" for a pending/used/
 * expired one — a handshake-progress oracle for the price of a photo, telling
 * them whether the owner has scanned or tapped yet. Now every nonce-less
 * caller is refused with the same message whatever the code is doing. (No
 * token was ever mintable either way: that needs the 128-bit nonce. This is
 * about what the failure LEAKS.)
 *
 * The side effects still respect the status machine: a terminal 'used' code is
 * never rewritten to 'expired' by a stranger's bad guess.
 */
export function decideCollect(
  code: LinkCodeSnapshot,
  nowMs: number,
  nonceMatches: boolean,
): LinkDecision {
  if (code.expiresAtMs <= nowMs) return reject("code expired", { expire: expirable(code.status) });
  if (code.attempts >= MAX_LINK_ATTEMPTS) {
    return reject("too many attempts", { expire: expirable(code.status) });
  }
  if (!nonceMatches) {
    return reject("invalid nonce", {
      countAttempt: true,
      expire: expirable(code.status) && code.attempts + 1 >= MAX_LINK_ATTEMPTS,
    });
  }
  if (code.status !== "claimed" && code.status !== "confirmed") {
    return reject("code is not collectable");
  }
  if (code.status === "claimed") return { ok: true, pending: true };
  return OK;
}
