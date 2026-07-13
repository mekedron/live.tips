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
import type { LoginRequestStatus } from "./loginrequests";
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

/**
 * createLoginRequest per (salted) IP hash per hour — the shared-tablet QR.
 *
 * The arithmetic: a login request lives 60 s and the tablet re-mints its QR
 * every ~45 s, so ONE tablet standing on a bar all evening legitimately calls
 * this ~80 times an hour. A venue with two or three tablets behind one NAT (a
 * bar and its stage, a festival with a router) is an ordinary shape, and every
 * one of them is behind the same public IP: 3 × 80 = 240, plus retries after
 * flaky bar wifi. 300 covers that with room to spare and still stops anyone
 * from bulk-minting requests.
 *
 * A generous limit is cheap here because a login request is WORTHLESS without
 * a human approval — minting a million of them gets an attacker a million
 * documents that expire in a minute, not a single session. The quota exists to
 * bound Firestore writes, not to defend the account.
 */
export const LOGIN_CREATES_PER_IP_PER_HOUR = 300;

/**
 * describeLoginRequest + approveLoginRequest per (salted) IP hash per hour.
 * These are the surfaces a displayCode-guesser would hammer, so unlike the
 * create quota this one IS a security bound (see DISPLAY_CODE_LENGTH's
 * arithmetic in loginrequests.ts, which assumes exactly this number). A human
 * puts one account on one tablet: 120/h is already a hundred times a real
 * evening's traffic from one venue's wifi.
 */
export const LOGIN_DESCRIBES_PER_IP_PER_HOUR = 120;

/**
 * collectLoginToken per (salted) IP hash per hour. The tablet POLLS this for
 * the whole time its QR is on screen — i.e. all evening, not just during a
 * handshake (that is the difference from LINK_COLLECTS, where the joining
 * device only polls inside a live 2-min window). At the recommended ~5 s poll
 * interval that is ~720 calls/h per tablet; 2000 leaves room for two tablets
 * behind one NAT and a burst of retries.
 *
 * NOTE for the client: do NOT poll faster than a few seconds. Each collect
 * writes the same rateLimits/{ipHash} document, and Firestore sustains roughly
 * one write per second to a single doc — a 1 s poll from two tablets on one
 * wifi would start contending on that bucket, not on anything that matters.
 */
export const LOGIN_COLLECTS_PER_IP_PER_HOUR = 2000;

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
 * either), so only the revoke callables can flip them.
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
 * loginRequests/{requestId} — the MIRROR of linkCodes: here the UNSIGNED
 * device (a bar's shared tablet) shows the QR and the SIGNED-IN phone scans
 * and approves it. Top-level for the same reason as linkCodes (the tablet has
 * no uid to put in a path) but with a stricter rule: NO client read either.
 * The tablet is unauthenticated, so a client-readable collection would let
 * anyone enumerate live requests; both parties learn everything they need from
 * callable returns instead. See loginrequests.ts for the lifecycle.
 */
export interface LoginRequestDoc {
  status: LoginRequestStatus;
  createdAtMs: number;
  /** createdAtMs + 60 s; the hourly sweep (or a TTL policy) deletes past it. */
  expiresAt: Timestamp;
  /** The typable fallback (8 chars, unambiguous alphabet). Queried on. */
  displayCode: string;
  /** Untrusted self-description, shown to the human who approves. */
  deviceName?: string;
  devicePlatform?: string;
  /** Stamped by the approver; the uid the custom token will be minted for. */
  approvedUid?: string;
  /**
   * Stamped at approve. collectLoginToken refuses to mint when this predates
   * the approver's sessionsValidAfterMs watermark (a missing value fails
   * closed once a watermark exists): an approval by a since-revoked session
   * must not outlive revokeAllOtherDevices.
   */
  approvedAtMs?: number;
  /**
   * sha256 of the collect nonce. Always written at create (optional only so a
   * read of a malformed/legacy doc fails closed rather than throwing); the
   * nonce itself is never at rest and never in the QR.
   */
  collectNonceHash?: string;
  /** describe/approve calls + bad-nonce collects; ≥5 force-expires the request. */
  attempts: number;
}

export function jarRef(firestore: Firestore, jarId: string): DocumentReference {
  return firestore.collection("jars").doc(jarId);
}

export function linkCodeRef(firestore: Firestore, codeId: string): DocumentReference {
  return firestore.collection("linkCodes").doc(codeId);
}

export function loginRequestRef(firestore: Firestore, requestId: string): DocumentReference {
  return firestore.collection("loginRequests").doc(requestId);
}

export function loginRequestsCol(firestore: Firestore) {
  return firestore.collection("loginRequests");
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
