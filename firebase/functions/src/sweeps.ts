/// Scheduled cleanup — the ports of the JarDO alarm. Firestore has no per-doc
/// alarms, so the TTLs the worker enforced with setAlarm() become periodic
/// queries over expiresAt fields.

import { Timestamp, type Firestore, type Query } from "firebase-admin/firestore";
import { resumeAccountDeletions } from "./account";
import { db } from "./store";

const BATCH = 250;

async function deleteByQuery(firestore: Firestore, query: Query): Promise<number> {
  let total = 0;
  for (;;) {
    const snap = await query.limit(BATCH).get();
    if (snap.empty) return total;
    const batch = firestore.batch();
    for (const doc of snap.docs) batch.delete(doc.ref);
    await batch.commit();
    total += snap.size;
    if (snap.size < BATCH) return total;
  }
}

/**
 * Undelivered tips age out on schedule whether or not the artist ever comes
 * back. Two queues, one contract (delivery is deletion; the sweep is the
 * backstop): the relay's pendingTips — the only place fan text rests for a
 * NO-account artist, so every 10 minutes + the 1h TTL keeps it at rest
 * ≤ ~70 minutes — and the cloud accounts' stripeTips (stripe-store.ts),
 * same TTL, where a swept QR tip is still recoverable through History.
 *
 * Riding along: the webhook's processedEvents dedupe tombstones
 * (stripe-webhook.ts). Their TTL is days, not an hour — a tombstone must
 * outlive Stripe's retry window, or a redelivery re-stages a collected tip —
 * but once it passes they are garbage by the same expiresAt query.
 */
export async function sweepPendingTipsHandler(): Promise<void> {
  const firestore = db();
  const swept = await deleteByQuery(
    firestore,
    firestore.collectionGroup("pendingTips").where("expiresAt", "<", Timestamp.now()),
  );
  if (swept > 0) console.log(`sweepPendingTips: deleted ${swept} expired pending tips`);
  const stripeSwept = await deleteByQuery(
    firestore,
    firestore.collectionGroup("stripeTips").where("expiresAt", "<", Timestamp.now()),
  );
  if (stripeSwept > 0) console.log(`sweepPendingTips: deleted ${stripeSwept} expired stripe tips`);
  const tombstones = await deleteByQuery(
    firestore,
    firestore.collection("processedEvents").where("expiresAt", "<", Timestamp.now()),
  );
  if (tombstones > 0) console.log(`sweepPendingTips: deleted ${tombstones} expired event tombstones`);
}

/**
 * 90 days after the artist was last seen, an UNOWNED jar self-destructs —
 * profile, secret hash, rate doc and any pending tips together. Jars with
 * ownerUid live with the account instead (deleted via deleteJar / account
 * deletion), so they are excluded here.
 */
export async function expireJarsHandler(): Promise<void> {
  const firestore = db();
  let total = 0;
  for (;;) {
    const snap = await firestore
      .collection("jars")
      .where("ownerUid", "==", null)
      .where("expiresAt", "<", Timestamp.now())
      .limit(50)
      .get();
    if (snap.empty) break;
    for (const doc of snap.docs) await firestore.recursiveDelete(doc.ref);
    total += snap.size;
    if (snap.size < 50) break;
  }
  if (total > 0) console.log(`expireJars: deleted ${total} expired jars`);
}

/**
 * The QR handshake's scratch state. A link code lives 2 minutes; whatever
 * state it ends in (used, expired, abandoned mid-handshake) the doc is garbage
 * once expiresAt passes — it still names a device and hashes a nonce, so it
 * does not get to linger.
 */
export async function sweepLinkCodesHandler(): Promise<void> {
  const firestore = db();
  const codes = await deleteByQuery(
    firestore,
    firestore.collection("linkCodes").where("expiresAt", "<", Timestamp.now()),
  );
  if (codes > 0) console.log(`sweepLinkCodes: deleted ${codes} stale link codes`);
}

/**
 * How long a recorded deletion is left to the caller before the sweep takes
 * it over — comfortably longer than the callable's own run.
 */
const DELETION_GRACE_MS = 10 * 60_000;

/**
 * Deletions that were promised and not finished (account.ts). This is the
 * half of "fail-closed and resumable" that does not depend on the artist
 * coming back: the last stage deletes the Auth user, so a failure there — or a
 * process that died mid-run — leaves nobody who COULD ask again. The ledger
 * asks for them.
 */
export async function sweepAccountDeletionsHandler(): Promise<void> {
  const firestore = db();
  const finished = await resumeAccountDeletions(firestore, Date.now(), DELETION_GRACE_MS);
  if (finished > 0) console.log(`sweepAccountDeletions: finished ${finished} unfinished account deletions`);
}

/** Quota buckets outlive their usefulness after ~2h; clear them hourly. */
export async function sweepRateLimitsHandler(): Promise<void> {
  const firestore = db();
  const swept = await deleteByQuery(
    firestore,
    firestore.collection("rateLimits").where("expiresAt", "<", Timestamp.now()),
  );
  if (swept > 0) console.log(`sweepRateLimits: deleted ${swept} stale buckets`);
}
