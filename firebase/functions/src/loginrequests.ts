/// QR sign-in-on-a-shared-device requests — the pure logic (no Firestore in
/// this file, so all of it is unit-testable). This is the MIRROR IMAGE of the
/// add-a-device link code in linkcodes.ts, and the two must never be confused:
///
///   linkCodes     — the SIGNED-IN device shows the QR, the NEW device scans.
///                   "Add my new phone to this account."
///   loginRequests — the UNSIGNED device (a bar's shared tablet) shows the QR,
///                   the SIGNED-IN device (the artist's own phone) scans.
///                   "Put my account on that tablet." (The Discord flow.)
///
/// Lifecycle of a login request:
///
///   pending  — the tablet minted it (createLoginRequest) and shows it as a QR
///   approved — the artist's phone scanned + confirmed (approveLoginRequest),
///              stamping the uid that is to be signed in
///   used     — the tablet traded requestId+collectNonce for a custom token
///              (collectLoginToken); single use, enforced by that transition
///   expired  — timed out (60 s), attempt-capped, or hourly-swept
///
/// Why the QR is safe to photograph, film, or screenshare
/// -----------------------------------------------------
/// The QR carries the requestId ONLY. It never carries the collectNonce: that
/// is minted at CREATE time and handed back to the tablet alone, over the
/// callable response. So:
///
///  * A requestId alone mints nothing. It becomes a token only after an
///    ALREADY-SIGNED-IN user approves it, and only for THAT user's uid.
///  * An attacker who photographs the QR and approves it does not steal the
///    artist's account — they can only offer to sign THEMSELVES in to that
///    tablet. (The tablet then shows their name, and they have handed a
///    stranger's tablet a session for their own account. A poor trade.)
///  * An attacker who steals the QR still cannot COLLECT the token: collect
///    requires the collectNonce, which only the tablet that created the
///    request has ever seen.
///
/// The residual risk is therefore a race, not a theft: an attacker watching
/// the tablet's QR could approve it with their own account before the artist
/// does, so the artist ends up looking at someone else's account on the
/// tablet. The tablet must always display WHO it just signed in as, and offer
/// a one-tap "not me — sign out". 60 s + single-use + rotation keeps that
/// window tiny; nothing about it leaks the artist's credentials.
///
/// The other direction — a hostile TABLET showing a QR that is really a login
/// request for a machine the attacker controls — is exactly what the approver
/// prompt is for: describeLoginRequest tells the phone the device label
/// ("Bar tablet (iPad)") BEFORE the human approves, and approving only ever
/// signs the approver in somewhere. It cannot hand the attacker the account.

import { randomBytes } from "node:crypto";
import { scrubText } from "./validate";

/**
 * A login request lives 60 SECONDS — a quarter of a link code's TTL. It is
 * shorter on purpose: the tablet sits in public with its QR permanently on
 * screen, so the QR is the one artefact of this system that strangers get to
 * look at all evening. The tablet re-mints (and re-renders) every ~45 s, and
 * a request that nobody approves inside a minute is worthless.
 */
export const LOGIN_REQUEST_TTL_MS = 60_000;

/** describe/approve calls + bad-nonce collects per request, then force-expire. */
export const MAX_LOGIN_ATTEMPTS = 5;

export const LOGIN_DEVICE_NAME_MAX = 40;
export const LOGIN_DEVICE_PLATFORM_MAX = 20;

/**
 * The typable fallback alphabet: 32 symbols, none of them confusable when read
 * off a screen across a bar and typed on a phone. 0/O and 1/I/l are all gone
 * (digits start at 2; the letters I and O are omitted), leaving
 * 8 digits + 24 letters = 32.
 */
export const DISPLAY_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";

/**
 * 8 characters from a 32-symbol alphabet = 8 × log2(32) = 40 bits ≈ 1.1e12
 * codes. Is 40 bits enough? The thing an attacker gains by guessing a live
 * displayCode is NOT an account — it is the ability to approve a stranger's
 * tablet with their OWN account (see the header). So this is a nuisance
 * bound, not a credential bound, and even so it holds comfortably:
 *
 *   - a guess is only useful against a PENDING, unexpired request, so the
 *     target set is however many tablets are showing a QR in that 60 s window
 *     (call it 10^3 across the whole product, wildly optimistic);
 *   - describe/approve are auth-required AND salted-IP quota'd
 *     (LOGIN_DESCRIBES_PER_IP_PER_HOUR = 120), so an attacker gets ~120
 *     guesses per hour per IP;
 *   - p(hit per guess) ≈ 10^3 / 2^40 ≈ 9e-10, so the expected number of
 *     guesses is ~1.1e9 → ~9e6 hours (a millennium) from one IP, and each hit
 *     buys them one wrong-account sign-in on one tablet.
 *
 * The per-request attempt cap (5) does not help against THIS attacker (they
 * guess different codes, not the same one) — it exists for the other
 * direction: it caps how many times anyone may hammer a request they already
 * know the id of, e.g. brute-forcing the 128-bit collectNonce. Five guesses
 * at 2^128 is not a plan.
 *
 * 6 chars (30 bits) would have made the guessing arithmetic uncomfortable
 * once a lot of tablets are live; 10 chars is a pain to type across a room.
 * 8 is the honest middle.
 */
export const DISPLAY_CODE_LENGTH = 8;

export type LoginRequestStatus = "pending" | "approved" | "used" | "expired";

/** The slice of loginRequests/{requestId} the transition guards need. */
export interface LoginRequestSnapshot {
  status: LoginRequestStatus;
  expiresAtMs: number;
  attempts: number;
}

/**
 * 16 random bytes → 22-char unpadded base64url. 128 bits: the requestId is the
 * Firestore document id AND the payload of a QR that hangs in a public room,
 * so it must be unguessable and enumeration-proof, like jarIds and linkCodes.
 */
export function newLoginRequestId(): string {
  return randomBytes(16).toString("base64url");
}

/**
 * The tablet's proof that it is the machine that asked. Minted at CREATE time,
 * returned to the tablet once, stored only as sha256 — and, crucially, NEVER
 * put in the QR. It is what makes a photographed QR uncollectable.
 */
export function newCollectNonce(): string {
  return randomBytes(16).toString("base64url");
}

/**
 * 8 unbiased draws from the 32-symbol alphabet. Rejection is unnecessary here:
 * 256 % 32 == 0, so masking a random byte to 5 bits is already uniform.
 */
export function newDisplayCode(): string {
  const bytes = randomBytes(DISPLAY_CODE_LENGTH);
  let out = "";
  for (const b of bytes) out += DISPLAY_ALPHABET[b & 31];
  return out;
}

/** requestId as it appears on the wire — reject junk before Firestore. */
export function isValidLoginRequestId(value: string): boolean {
  return /^[A-Za-z0-9_-]{22}$/.test(value);
}

export function isValidDisplayCode(value: string): boolean {
  return /^[2-9A-HJ-NP-Z]{8}$/.test(value);
}

/**
 * What the human typed → the canonical displayCode. Case and the separators a
 * human adds by reflex ("A4KP-9TXM", "a4kp 9txm") are forgiven; a character
 * OUTSIDE the alphabet is not silently dropped — dropping a stray '0' would
 * shift every later character and turn a typo into a different valid code.
 * Returns null for anything that is not a well-formed code afterwards.
 */
export function normalizeDisplayCode(raw: unknown): string | null {
  if (typeof raw !== "string" || raw.length > 32) return null;
  const compact = raw.replace(/[\s-]/g, "").toUpperCase();
  return isValidDisplayCode(compact) ? compact : null;
}

/**
 * describe/approve accept EITHER form: the 22-char requestId straight out of
 * the QR, or the 8-char displayCode the artist typed because the camera would
 * not focus. The two shapes cannot collide (different lengths), so one
 * parameter can carry both without a mode flag the caller could get wrong.
 */
export type LoginCodeRef =
  | { kind: "requestId"; value: string }
  | { kind: "displayCode"; value: string };

export function parseLoginCode(raw: unknown): LoginCodeRef | null {
  if (typeof raw !== "string") return null;
  if (isValidLoginRequestId(raw)) return { kind: "requestId", value: raw };
  const display = normalizeDisplayCode(raw);
  return display === null ? null : { kind: "displayCode", value: display };
}

export function loginRequestExpiryMs(nowMs: number): number {
  return nowMs + LOGIN_REQUEST_TTL_MS;
}

/**
 * The tablet's self-description, as shown on the approver's phone ("Sign in on
 * **Bar tablet (iPad)**?"). Same treatment as linkcodes' requesterField:
 * scrubbed, then TRUNCATED rather than rejected — a device label loses nothing
 * by being shortened, and a rejection would only add a failure mode to a
 * handshake that has 60 seconds to live. Returns null for non-strings, absurd
 * lengths, and strings that scrub to nothing.
 *
 * It is UNTRUSTED text: the tablet names itself, and a hostile tablet will
 * name itself something reassuring. It is a recognition aid for the human, not
 * an authentication of the device — which is why approving can only ever sign
 * the approver in, never hand out anything they do not already have.
 */
export function loginDeviceField(raw: unknown, maxCodePoints: number): string | null {
  if (typeof raw !== "string" || raw.length > maxCodePoints * 8) return null;
  const clean = scrubText(raw);
  if (clean.length === 0) return null;
  const points = [...clean];
  return points.length <= maxCodePoints ? clean : points.slice(0, maxCodePoints).join("");
}

// ---------------------------------------------------------------------------
// Status-transition guards. Pure: the handlers run these inside a Firestore
// transaction and translate the verdicts into writes + HttpsErrors. Same
// vocabulary as linkcodes.ts on purpose — one shape of decision, two flows.

export type LoginDecision =
  | { ok: true; pending?: boolean }
  | { ok: false; expire: boolean; countAttempt: boolean; message: string };

const OK: LoginDecision = { ok: true };

function reject(
  message: string,
  opts: { expire?: boolean; countAttempt?: boolean } = {},
): LoginDecision {
  return { ok: false, expire: opts.expire === true, countAttempt: opts.countAttempt === true, message };
}

/** Only live statuses may be flipped to 'expired' — never rewrite 'used'. */
function expirable(status: LoginRequestStatus): boolean {
  return status === "pending" || status === "approved";
}

/**
 * describeLoginRequest: pending + unexpired + under the cap. A request that is
 * already approved is NOT describable — the phone has nothing left to decide,
 * and answering would leak that a given code is live. Counts an attempt: this
 * is the surface a code-guesser would hammer, so it must burn the same budget
 * approve does.
 */
export function decideDescribe(req: LoginRequestSnapshot, nowMs: number): LoginDecision {
  if (req.expiresAtMs <= nowMs) return reject("request expired", { expire: expirable(req.status) });
  if (req.status !== "pending") return reject("request is no longer open");
  if (req.attempts >= MAX_LOGIN_ATTEMPTS) return reject("too many attempts", { expire: true });
  return OK;
}

/**
 * approveLoginRequest: pending + unexpired + under the cap → approved.
 *
 * Deliberately open to ANONYMOUS callers, unlike createLinkCode and
 * revokeAllOtherDevices. The reasoning is the exact inverse of theirs: those
 * two would STRAND a guest account (a second device, or a token revocation,
 * leaves an anonymous uid with no credential to come back with). This one is
 * the only rope a guest account has — approving a login request is how a
 * no-account artist gets themselves onto a second screen at all, and the only
 * way their jars survive a drowned phone. Refusing anonymous here would not
 * protect them from anything; it would just delete them.
 *
 * A request may be approved once. A second approver does not get to overwrite
 * approvedUid out from under the first (that would be a way to swap which
 * account lands on the tablet after the human already looked at the name).
 */
export function decideApprove(req: LoginRequestSnapshot, nowMs: number): LoginDecision {
  if (req.expiresAtMs <= nowMs) return reject("request expired", { expire: expirable(req.status) });
  if (req.status === "approved") return reject("request already approved");
  if (req.status !== "pending") return reject("request is no longer open");
  if (req.attempts >= MAX_LOGIN_ATTEMPTS) return reject("too many attempts", { expire: true });
  return OK;
}

/**
 * collectLoginToken: approved + unexpired + matching collectNonce → used, and
 * only then is a custom token minted. A still-PENDING request with the RIGHT
 * nonce is the poll case — the tablet asking "has anyone approved me yet?" —
 * and answers {ok, pending} instead of an error, so the tablet needs no string
 * matching to keep waiting.
 *
 * The nonce is checked BEFORE the pending/approved split, so a caller without
 * the nonce cannot even learn whether a request has been approved: they burn
 * an attempt and get the same failure either way. Five wrong nonces
 * force-expire the request, so a leaked requestId buys at most 5 guesses at a
 * 128-bit secret.
 */
export function decideCollect(
  req: LoginRequestSnapshot,
  nowMs: number,
  nonceMatches: boolean,
): LoginDecision {
  if (req.expiresAtMs <= nowMs) return reject("request expired", { expire: expirable(req.status) });
  if (req.status !== "pending" && req.status !== "approved") {
    return reject("request is not collectable");
  }
  if (req.attempts >= MAX_LOGIN_ATTEMPTS) return reject("too many attempts", { expire: true });
  if (!nonceMatches) {
    return reject("invalid nonce", {
      countAttempt: true,
      expire: req.attempts + 1 >= MAX_LOGIN_ATTEMPTS,
    });
  }
  if (req.status === "pending") return { ok: true, pending: true };
  return OK;
}
