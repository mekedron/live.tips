/// Device-facing jar lifecycle, as callables. Auth model ported from the
/// worker: the jar secret (sha256 at rest, timing-safe compare) remains the
/// root credential; a Firebase uid becomes a convenience principal once the
/// app claims the jar with it. All handlers require a signed-in caller
/// (anonymous auth counts — it is the app's transport identity).

import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { ipQuotaKey, newJarId, newSecret, sha256Hex, verifySecret } from "./auth";
import { DIRECT_HOPS, clientIp } from "./client-ip";
import { requireFreshSession } from "./devices";
import { IP_HASH_SALT } from "./params";
import {
  CREATES_PER_IP_PER_HOUR,
  CREATES_PER_UID_PER_DAY,
  DAY_MS,
  MAX_READER_UIDS,
  REQUESTS_PER_UID_PER_HOUR,
  bumpQuota,
  db,
  expiryTimestamp,
  jarAuthRef,
  jarRef,
  type JarDoc,
} from "./store";
import { isValidJarId, validateProfile, validateRequestsConfig, validateRequestsQueue } from "./validate";

import type { Firestore } from "firebase-admin/firestore";

export const TIP_URL_BASE = "https://tip.live.tips/t/";

export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "sign-in required");
  return uid;
}

export function dataObject(request: CallableRequest): Record<string, unknown> {
  const data: unknown = request.data;
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    throw new HttpsError("invalid-argument", "payload must be an object");
  }
  return data as Record<string, unknown>;
}

function requireJarId(data: Record<string, unknown>): string {
  const jarId = data["jarId"];
  // Malformed ids get the same answer as missing jars (anti-enumeration).
  if (typeof jarId !== "string" || !isValidJarId(jarId)) {
    throw new HttpsError("not-found", "not found");
  }
  return jarId;
}

/**
 * Owner-or-secret authorization for update/delete/seen: the caller either
 * owns the jar (ownerUid) or presents the jar secret. Returns the jar doc and
 * whether a valid jar secret was presented.
 *
 * `viaSecret` is what the callers gate the revocation watermark on. The jar
 * secret is the root credential and stands on its own — a caller holding it
 * need not be a fresh session. But the owner-uid path rides only the Firebase
 * session, and onCall accepts a still-valid ID token for up to ~1h after the
 * kill switch fired; so an owner-only caller must clear requireFreshSession
 * before it may mutate the jar (updateJarProfile could swap the payout
 * methods to a thief's). Computed independently of the ownerUid short-circuit
 * so an owner who ALSO presents the secret is credited the secret.
 */
async function authorizeJar(
  jarId: string,
  uid: string,
  secret: unknown,
): Promise<{ jar: JarDoc; viaSecret: boolean }> {
  const firestore = db();
  const [jarSnap, authSnap] = await firestore.getAll(jarRef(firestore, jarId), jarAuthRef(firestore, jarId));
  const jar = jarSnap?.data() as JarDoc | undefined;
  const secretHash = authSnap?.get("secretHash") as string | undefined;
  if (!jar || !secretHash) throw new HttpsError("not-found", "not found");
  const viaSecret = secret !== undefined && verifySecret(secret, secretHash);
  if (jar.ownerUid === uid) return { jar, viaSecret };
  if (viaSecret) return { jar, viaSecret };
  throw new HttpsError("permission-denied", "unauthorized");
}

// ---------------------------------------------------------------------------

export async function createJarHandler(
  request: CallableRequest,
): Promise<{ jarId: string; secret: string; tipUrl: string }> {
  const uid = requireUid(request);
  const data = dataObject(request);

  const profileRaw = data["profile"];
  if (typeof profileRaw !== "object" || profileRaw === null || Array.isArray(profileRaw)) {
    throw new HttpsError("invalid-argument", "profile must be an object");
  }
  const profile = validateProfile(profileRaw as Record<string, unknown>);
  if (!profile.ok) throw new HttpsError("invalid-argument", profile.error);
  const owned = data["owned"] === true;

  // Fails closed on a missing salt: the quota key is a salted hash of the
  // IP, and an unsalted one would be the IP itself in all but name. No
  // default salt, no jar.
  const salt = IP_HASH_SALT.value();
  if (!salt) throw new HttpsError("internal", "server misconfigured");

  const firestore = db();
  const now = Date.now();
  // NOT rawRequest.ip: the platform-appended header entry is the only
  // address a caller cannot write (see client-ip.ts).
  const ip = clientIp(request.rawRequest, DIRECT_HOPS);

  const uidAllowed = await bumpQuota(
    firestore, `create-uid-${uid}`, Math.floor(now / DAY_MS), CREATES_PER_UID_PER_DAY, 2 * DAY_MS,
  );
  const ipAllowed = uidAllowed && await bumpQuota(
    firestore, ipQuotaKey(ip, salt, "create"), Math.floor(now / 3_600_000), CREATES_PER_IP_PER_HOUR, 2 * 3_600_000,
  );
  if (!uidAllowed || !ipAllowed) {
    throw new HttpsError("resource-exhausted", "creation limit reached, try later");
  }

  const jarId = newJarId();
  const secret = newSecret();

  const jar: JarDoc = {
    profile: profile.value,
    // ownerUid stays null unless the app explicitly claims ownership; a
    // reader uid alone must not pin the jar to an account's lifetime.
    ownerUid: owned ? uid : null,
    readerUids: [uid],
    createdAtMs: now,
    lastSeenDay: Math.floor(now / DAY_MS),
    tipsDay: 0,
    tipsToday: 0,
    tipsTotal: 0,
    expiresAt: expiryTimestamp(now),
  };

  const batch = firestore.batch();
  // create(), not set(): a jarId collision (2^-128) must fail, not merge.
  batch.create(jarRef(firestore, jarId), jar);
  batch.create(jarAuthRef(firestore, jarId), { secretHash: sha256Hex(secret) });
  await batch.commit();

  return { jarId, secret, tipUrl: `${TIP_URL_BASE}${jarId}` };
}

export async function claimJarHandler(request: CallableRequest): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);
  const owned = data["owned"] === true;

  const firestore = db();
  const authSnap = await jarAuthRef(firestore, jarId).get();
  const secretHash = authSnap.get("secretHash") as string | undefined;
  if (!secretHash) throw new HttpsError("not-found", "not found");
  if (!verifySecret(data["secret"], secretHash)) {
    throw new HttpsError("unauthenticated", "unauthorized");
  }

  await firestore.runTransaction(async (tx) => {
    const ref = jarRef(firestore, jarId);
    const snap = await tx.get(ref);
    const jar = snap.data() as JarDoc | undefined;
    if (!jar) throw new HttpsError("not-found", "not found");
    const readers = jar.readerUids.includes(uid) ? jar.readerUids : [...jar.readerUids, uid];
    if (readers.length > MAX_READER_UIDS) {
      throw new HttpsError("resource-exhausted", "too many devices linked to this jar");
    }
    tx.update(ref, {
      readerUids: readers,
      ...(owned ? { ownerUid: uid } : {}),
    });
  });

  return { ok: true };
}

export async function updateJarProfileHandler(request: CallableRequest): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);

  const profileRaw = data["profile"];
  if (typeof profileRaw !== "object" || profileRaw === null || Array.isArray(profileRaw)) {
    throw new HttpsError("invalid-argument", "profile must be an object");
  }
  const profile = validateProfile(profileRaw as Record<string, unknown>);
  if (!profile.ok) throw new HttpsError("invalid-argument", profile.error);

  const { viaSecret } = await authorizeJar(jarId, uid, data["secret"]);
  // Owner-uid path rides only the Firebase session, which onCall accepts for
  // ~1h past the kill switch. Gate it on the revocation watermark so a revoked
  // session cannot swap the payout methods to a thief's. A secret-bearing
  // caller holds the root credential and is exempt.
  if (!viaSecret) await requireFreshSession(db(), uid, request);
  const now = Date.now();
  await jarRef(db(), jarId).update({
    profile: profile.value,
    lastSeenDay: Math.floor(now / DAY_MS),
    expiresAt: expiryTimestamp(now),
  });
  return { ok: true };
}

/**
 * How long one "open" lasts. Requests need a live publisher: the deadline is
 * long enough to survive a whole show without a re-open, and short enough
 * that a jar whose app died stops selling requests by the next day. Every
 * queue push while open re-arms it (a publishing leader is proof of life).
 */
export const REQUESTS_OPEN_MS = 12 * 3_600_000;

/**
 * Song requests (#64): publish the library/config, flip the open window, and
 * push live queue state — any subset per call. All writes are field-targeted
 * (dot paths), never a doc set: `open` alone must not clobber the queue, a
 * config push must not touch requestsLive, and NOTHING here touches profile,
 * lastSeenDay or expiresAt — keep-alive belongs to jarSeen and the daily
 * profile re-push, and a request flow that stamped it would keep abandoned
 * jars alive.
 */
export async function setJarRequestsHandler(request: CallableRequest): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);

  const configRaw = data["config"];
  const openRaw = data["open"];
  const queueRaw = data["queue"];
  if (configRaw === undefined && openRaw === undefined && queueRaw === undefined) {
    throw new HttpsError("invalid-argument", "one of config, open or queue is required");
  }
  if (openRaw !== undefined && typeof openRaw !== "boolean") {
    throw new HttpsError("invalid-argument", "open must be a boolean");
  }

  const { jar, viaSecret } = await authorizeJar(jarId, uid, data["secret"]);
  // Same watermark gate as updateJarProfile: a revoked owner-uid session must
  // not keep publishing (or re-pricing) the request catalogue. Secret-bearing
  // callers hold the root credential and are exempt.
  if (!viaSecret) await requireFreshSession(db(), uid, request);

  const now = Date.now();
  // Per-uid, not per-jar: the quota is about a runaway client, and a client
  // publishes for every jar it holds with the same loop.
  const allowed = await bumpQuota(
    db(), `jar-requests-${uid}`, Math.floor(now / 3_600_000), REQUESTS_PER_UID_PER_HOUR, 2 * 3_600_000,
  );
  if (!allowed) throw new HttpsError("resource-exhausted", "too many request updates, try later");

  const update: Record<string, unknown> = {};

  if (configRaw !== undefined) {
    if (typeof configRaw !== "object" || configRaw === null || Array.isArray(configRaw)) {
      throw new HttpsError("invalid-argument", "config must be an object");
    }
    // Prices are bounds-checked against the JAR's currency — requests are
    // always denominated in it.
    const config = validateRequestsConfig(configRaw as Record<string, unknown>, jar.profile.currency);
    if (!config.ok) throw new HttpsError("invalid-argument", config.error);
    update["requestsConfig"] = config.value;
  }

  if (queueRaw !== undefined) {
    if (typeof queueRaw !== "object" || queueRaw === null || Array.isArray(queueRaw)) {
      throw new HttpsError("invalid-argument", "queue must be an object");
    }
    const queue = validateRequestsQueue(queueRaw as Record<string, unknown>);
    if (!queue.ok) throw new HttpsError("invalid-argument", queue.error);
    update["requestsLive.songs"] = queue.value;
    update["requestsLive.currency"] = jar.profile.currency;
    update["requestsLive.updatedAtMs"] = now;
    // A queue push while open (or opened by this very call) re-arms the
    // deadline: a publishing leader is alive, so the window should not lapse
    // mid-show.
    if ((jar.requestsLive?.openUntilMs ?? 0) > now || openRaw === true) {
      update["requestsLive.openUntilMs"] = now + REQUESTS_OPEN_MS;
    }
  }

  if (openRaw !== undefined) {
    // After the queue block on purpose: an explicit open:false in the same
    // call wins over the queue's re-arm.
    update["requestsLive.openUntilMs"] = openRaw ? now + REQUESTS_OPEN_MS : 0;
    update["requestsLive.updatedAtMs"] = now;
  }

  await jarRef(db(), jarId).update(update);
  return { ok: true };
}

/**
 * The jar and everything under it — the doc, private/{auth,rate}, any pending
 * tips — in one move; nothing under a deleted jar may survive it, and the
 * public tip page dies with the doc. Exported: deleting an account walks its
 * bands' jars through this same door (account.ts), where there is no jar
 * secret to present and the caller is the server itself.
 */
export async function purgeJar(firestore: Firestore, jarId: string): Promise<void> {
  await firestore.recursiveDelete(jarRef(firestore, jarId));
}

export async function deleteJarHandler(request: CallableRequest): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);
  const { viaSecret } = await authorizeJar(jarId, uid, data["secret"]);
  // Same watermark gate as updateJarProfile: a revoked owner-uid session must
  // not be able to delete (deface) the artist's tip pages. Secret-bearing
  // callers are exempt.
  if (!viaSecret) await requireFreshSession(db(), uid, request);
  await purgeJar(db(), jarId);
  return { ok: true };
}

export async function rotateJarSecretHandler(request: CallableRequest): Promise<{ secret: string }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);

  // Rotation always requires the outgoing secret — owning uid is not enough,
  // matching the worker (the secret is the root credential).
  const firestore = db();
  const authSnap = await jarAuthRef(firestore, jarId).get();
  const secretHash = authSnap.get("secretHash") as string | undefined;
  if (!secretHash) throw new HttpsError("not-found", "not found");
  if (!verifySecret(data["secret"], secretHash)) {
    throw new HttpsError("unauthenticated", "unauthorized");
  }

  const secret = newSecret();
  const now = Date.now();
  const batch = firestore.batch();
  batch.update(jarAuthRef(firestore, jarId), { secretHash: sha256Hex(secret) });
  // Rotation revokes every other device's read access, like the worker's
  // rotate closed every socket: only the rotating caller stays linked.
  batch.update(jarRef(firestore, jarId), {
    readerUids: [uid],
    lastSeenDay: Math.floor(now / DAY_MS),
    expiresAt: expiryTimestamp(now),
  });
  await batch.commit();
  return { secret };
}

export async function jarSeenHandler(request: CallableRequest): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);
  const { jar, viaSecret } = await authorizeJar(jarId, uid, data["secret"]);
  // The lowest-value of the three (it only bumps the keep-alive clock), but
  // gated for the same reason and at trivial cost: jarSeen is the daily
  // re-push, not a hot path, and already reads two jar docs — one more read of
  // the watermark is proportionate, and a revoked session should not be able
  // to keep an abandoned jar alive. Secret-bearing callers are exempt.
  if (!viaSecret) await requireFreshSession(db(), uid, request);

  const now = Date.now();
  const today = Math.floor(now / DAY_MS);
  await jarRef(db(), jarId).update({
    lastSeenDay: today,
    expiresAt: expiryTimestamp(now),
    // A new day zeroes the daily counter; the next tip restarts it.
    ...(jar.tipsDay !== today ? { tipsDay: today, tipsToday: 0 } : {}),
  });
  return { ok: true };
}
