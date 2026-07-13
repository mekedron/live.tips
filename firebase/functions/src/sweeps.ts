/// Scheduled cleanup — the ports of the JarDO alarm. Firestore has no per-doc
/// alarms, so the TTLs the worker enforced with setAlarm() become periodic
/// queries over expiresAt fields.

import { Timestamp, type Firestore, type Query } from "firebase-admin/firestore";
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
 * Undelivered tips are the only thing at rest with a fan's name on it, so
 * they age out on schedule whether or not the artist ever comes back.
 * Every 10 minutes + the 1h TTL keeps fan text at rest ≤ ~70 minutes.
 */
export async function sweepPendingTipsHandler(): Promise<void> {
  const firestore = db();
  const swept = await deleteByQuery(
    firestore,
    firestore.collectionGroup("pendingTips").where("expiresAt", "<", Timestamp.now()),
  );
  if (swept > 0) console.log(`sweepPendingTips: deleted ${swept} expired pending tips`);
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

/** Quota buckets outlive their usefulness after ~2h; clear them hourly. */
export async function sweepRateLimitsHandler(): Promise<void> {
  const firestore = db();
  const swept = await deleteByQuery(
    firestore,
    firestore.collection("rateLimits").where("expiresAt", "<", Timestamp.now()),
  );
  if (swept > 0) console.log(`sweepRateLimits: deleted ${swept} stale buckets`);
}
