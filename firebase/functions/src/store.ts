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

let cached: Firestore | null = null;

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
  /** 90 days after last activity; expireJars deletes unowned jars past it. */
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

export function jarRef(firestore: Firestore, jarId: string): DocumentReference {
  return firestore.collection("jars").doc(jarId);
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
