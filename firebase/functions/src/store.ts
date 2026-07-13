/// Firestore data model + the shared invariants ported from the worker's
/// Durable Objects. One doc per jar (~1 KB of profile plus counters), a hashed
/// secret in a private subcollection, and — only while the artist's screen is
/// away — the handful of tips that have not reached it yet. Keeps NO tip
/// history: a pending tip is deleted when the app reads it, and swept unseen
/// after PENDING_TTL_MS regardless.

import { getApps, initializeApp } from "firebase-admin/app";
import {
  DocumentReference,
  Firestore,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import { sha256Hex } from "./auth";
import type { LinkCodeStatus } from "./linkcodes";
import type { JarProfile, TipRequest } from "./types";

export const DAY_MS = 86_400_000;
export const EXPIRE_DAYS = 90;
export const TIPS_PER_MINUTE = 6;
export const TIPS_PER_HOUR = 60;
export const DEDUPE_WINDOW_MS = 60_000;

/**
 * How long an undelivered tip waits for the artist's screen before it is
 * deleted unseen. The artist's device goes away for entirely ordinary
 * reasons — the phone locks, they tab over to MobilePay to check a payment,
 * they walk behind a wall — and a fan who has already paid must not lose their
 * message to any of that. Long enough to cover a set break; short enough that
 * the relay never becomes a tip history.
 */
export const PENDING_TTL_MS = 60 * 60_000;

/**
 * Hard cap on the queue. TIPS_PER_HOUR already bounds what can arrive inside
 * one TTL window, so this only bites if that quota is ever raised.
 */
export const MAX_PENDING = TIPS_PER_HOUR;

/** Jar-creation quota: max 20/hour per (salted) IP hash. */
export const CREATES_PER_IP_PER_HOUR = 20;
/** And 20/day per signed-in uid (incl. anonymous transport uids). */
export const CREATES_PER_UID_PER_DAY = 20;

/**
 * Per-IP tip burst guard. The worker enforced 12/min at the edge (a beta
 * rate-limit binding); here the same job is an hourly Firestore bucket. The
 * real per-jar quotas (6/min, 60/h) live in the private/rate transaction.
 */
export const TIPS_PER_IP_PER_HOUR = 120;

/** How many readers one jar can have (artist's own devices). */
export const MAX_READER_UIDS = 5;

/** QR link-code redemptions per (salted) IP hash per hour: a scan is a
 * once-per-new-device act, so a generous human budget is still tiny. */
export const LINK_REDEEMS_PER_IP_PER_HOUR = 30;

/** collectLinkToken calls per (salted) IP hash per hour. Deliberately roomy:
 * the joining device POLLS collect until the owner confirms (2 min windows,
 * ~1 poll/s worst case), so this only stops abuse, never a handshake. */
export const LINK_COLLECTS_PER_IP_PER_HOUR = 600;

let cached: Firestore | null = null;

/// The Admin SDK is initialized HERE, at module load, and unconditionally —
/// `getApps()` proved not to be a reliable guard in the deployed runtime
/// (every Firestore call came back `app/no-app`, which took the whole relay
/// down: no jar could be created, no tip delivered). Initializing eagerly and
/// tolerating the duplicate-app error is the only form that cannot fail.
try {
  initializeApp();
} catch (_) {
  // Already initialized (warm instance, or a second module copy) — fine.
}

export function db(): Firestore {
  if (cached === null) {
    if (getApps().length === 0) initializeApp();
    cached = getFirestore();
  }
  return cached;
}

// ---------------------------------------------------------------------------
// Document shapes

export interface JarDoc {
  profile: JarProfile;
  /** Set only when the app claimed the jar with {owned: true}. */
  ownerUid: string | null;
  readerUids: string[];
  createdAtMs: number;
  lastSeenDay: number;
  /** The UTC day tipsToday counts for; a stale tipsDay means tipsToday is 0. */
  tipsDay: number;
  tipsToday: number;
  tipsTotal: number;
  /** 90 days after the ARTIST was last seen (jarSeen / profile update /
   * secret rotation — never a fan tip); expireJars deletes unowned jars
   * past it. */
  expiresAt: Timestamp;
}

export interface RateDoc {
  minute: number;
  minuteCount: number;
  hour: number;
  hourCount: number;
  recentSigs: { sig: string; tsMs: number }[];
}

export interface PendingTipDoc {
  tsMs: number;
  method: string;
  amountMinor: number;
  /** The currency the fan actually paid in — EUR for a Box, GBP for Monzo. */
  currency: string;
  name: string;
  message: string;
  expiresAt: Timestamp;
}

/**
 * users/{uid}/devices/{deviceId} — one doc per app install. Created and
 * updated by the APP writing Firestore directly (name, platform, model?,
 * createdAtMs, lastSeenAtMs), EXCEPT `revoked`/`revokedAtMs`: the rules pin
 * those client-side (create must say revoked:false, update may never change
 * either), so only the callables can flip them. Two callables do: the revoke
 * pair sets the flag, and confirmLinkCode clears it — the artist, on a device
 * still signed in, re-admitting this one (#36). Nothing else, ever.
 */
export interface DeviceDoc {
  name: string;
  platform: string;
  model?: string;
  createdAtMs: number;
  lastSeenAtMs: number;
  revoked: boolean;
  revokedAtMs?: number;
}

/**
 * users/{uid}/private/security — function-written revocation watermark.
 * Rules deny every client write and gate the whole users/** subtree on
 * `auth_time * 1000 >= sessionsValidAfterMs`, so ID tokens minted before a
 * revokeAllOtherDevices call lose Firestore access immediately (not after
 * their remaining ≤1h of cryptographic validity).
 */
export interface SecurityDoc {
  sessionsValidAfterMs: number;
}

/**
 * linkCodes/{codeId} — QR add-device handshake state. TOP-LEVEL on purpose:
 * the redeeming device is unauthenticated and callables must reach the doc
 * without a uid in the path. Only the owning uid may READ one (rules); every
 * write is function-mediated; the redeeming device never reads the doc at
 * all — it learns via callable returns. See linkcodes.ts for the lifecycle.
 */
export interface LinkCodeDoc {
  uid: string;
  status: LinkCodeStatus;
  createdAtMs: number;
  /** createdAtMs + 2 min; the hourly sweep (or a TTL policy) deletes past it. */
  expiresAt: Timestamp;
  /** Redeems + bad-nonce collects; ≥5 force-expires the code. */
  attempts: number;
  /** Set at redeem: what device A's confirm screen shows. */
  requester?: { name: string; platform: string };
  /**
   * Set at redeem: the deviceId B calls itself. The confirm clears `revoked`
   * on users/{uid}/devices/{requesterDeviceId} — the ONE thing that re-admits
   * a device the account revoked (#36). Unverified by construction (redeem is
   * unauthenticated), which is safe: it can only ever name a doc under the
   * owner's own uid, and only the owner's confirm acts on it.
   */
  requesterDeviceId?: string;
  /** sha256 of the redeem nonce; the nonce itself is never at rest. */
  redeemNonceHash?: string;
  /**
   * Stamped at confirm. collectLinkToken refuses to mint when this predates
   * the owner's sessionsValidAfterMs watermark (a missing value fails closed
   * once a watermark exists): a code confirmed by a since-revoked session
   * must not outlive revokeAllOtherDevices.
   */
  confirmedAtMs?: number;
}

/**
 * accountDeletions/{uid} — the ledger of an account deletion in flight
 * (account.ts). TOP-LEVEL on purpose: a deletion's whole point is that
 * users/{uid} and the Auth user stop existing, so the record of what has
 * already been erased cannot live under either. Server-only; the account
 * that asked is being deleted and has nothing to read here.
 */
export interface AccountDeletionDoc {
  uid: string;
  requestedAtMs: number;
  /** Stages already finished, so a resume never redoes a Stripe round-trip. */
  done: string[];
  attempts: number;
  lastErrorAtMs?: number;
  lastError?: string;
  /**
   * Webhook endpoints on the artist's OWN Stripe account that we could not
   * remove (they revoked the key first, Stripe was down). Named, never
   * silently dropped: the app tells the artist to delete them by hand.
   */
  strandedEndpoints?: string[];
}

export function jarRef(firestore: Firestore, jarId: string): DocumentReference {
  return firestore.collection("jars").doc(jarId);
}

export function accountDeletionRef(firestore: Firestore, uid: string): DocumentReference {
  return firestore.collection("accountDeletions").doc(uid);
}

export function userRef(firestore: Firestore, uid: string): DocumentReference {
  return firestore.collection("users").doc(uid);
}

export function bandsCol(firestore: Firestore, uid: string) {
  return firestore.collection("users").doc(uid).collection("bands");
}

export function linkCodeRef(firestore: Firestore, codeId: string): DocumentReference {
  return firestore.collection("linkCodes").doc(codeId);
}

export function deviceRef(firestore: Firestore, uid: string, deviceId: string): DocumentReference {
  return firestore.collection("users").doc(uid).collection("devices").doc(deviceId);
}

export function devicesCol(firestore: Firestore, uid: string) {
  return firestore.collection("users").doc(uid).collection("devices");
}

export function securityRef(firestore: Firestore, uid: string): DocumentReference {
  return firestore.collection("users").doc(uid).collection("private").doc("security");
}

export function jarAuthRef(firestore: Firestore, jarId: string): DocumentReference {
  return jarRef(firestore, jarId).collection("private").doc("auth");
}

export function jarRateRef(firestore: Firestore, jarId: string): DocumentReference {
  return jarRef(firestore, jarId).collection("private").doc("rate");
}

export function expiryTimestamp(nowMs: number): Timestamp {
  return Timestamp.fromMillis(nowMs + EXPIRE_DAYS * DAY_MS);
}

/**
 * An unowned jar past its expiry is gone even if the daily sweep has not
 * reached it yet — anti-enumeration demands the URL dies on schedule, not on
 * the sweeper's clock. Account-owned jars live with the account.
 */
export function jarIsLive(doc: JarDoc | undefined, nowMs: number): doc is JarDoc {
  if (!doc) return false;
  if (doc.ownerUid === null && doc.expiresAt.toMillis() <= nowMs) return false;
  return true;
}

// ---------------------------------------------------------------------------
// Dedupe signature

/**
 * Identical repeats inside the window are accepted but not relayed — the
 * sender learns nothing, the stage stays clean. The signature is HASHED
 * before it touches storage so fan name/message text is never written at
 * rest via this path (the whole point of the relay). `\u0000` separates the
 * fields so `|` inside a name/message can't forge a collision.
 */
export function dedupeSignature(tip: TipRequest): string {
  return sha256Hex(`${tip.method}\u0000${tip.amountMinor}\u0000${tip.name}\u0000${tip.message}`);
}

// ---------------------------------------------------------------------------
// Generic bucketed quota over rateLimits/{key}

/**
 * Increment-and-check for the rateLimits collection. `bucket` is an hour
 * number for IP quotas and a day number for the per-uid creation quota; the
 * field keeps the model's `hourBucket` name either way. Returns false when
 * the caller is over `limit` for the current bucket. Docs carry an expiresAt
 * so the hourly sweep (or a Firestore TTL policy) clears them.
 */
export async function bumpQuota(
  firestore: Firestore,
  key: string,
  bucket: number,
  limit: number,
  ttlMs: number,
): Promise<boolean> {
  const ref = firestore.collection("rateLimits").doc(key);
  return firestore.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() as { hourBucket?: number; count?: number } | undefined;
    const count = data && data.hourBucket === bucket ? (data.count ?? 0) : 0;
    if (count >= limit) return false;
    tx.set(ref, {
      hourBucket: bucket,
      count: count + 1,
      expiresAt: Timestamp.fromMillis(Date.now() + ttlMs),
    });
    return true;
  });
}
