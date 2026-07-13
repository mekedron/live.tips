/// Device-facing jar lifecycle, as callables. Auth model ported from the
/// worker: the jar secret (sha256 at rest, timing-safe compare) remains the
/// root credential; a Firebase uid becomes a convenience principal once the
/// app claims the jar with it. All handlers require a signed-in caller
/// (anonymous auth counts — it is the app's transport identity).

import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { ipQuotaKey, newJarId, newSecret, sha256Hex, verifySecret } from "./auth";
import { IP_HASH_SALT } from "./params";
import {
  CREATES_PER_IP_PER_HOUR,
  CREATES_PER_UID_PER_DAY,
  DAY_MS,
  MAX_READER_UIDS,
  bumpQuota,
  db,
  expiryTimestamp,
  jarAuthRef,
  jarRef,
  type JarDoc,
} from "./store";
import { isValidJarId, validateProfile } from "./validate";

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
 * owns the jar (ownerUid) or presents the jar secret. Returns the jar doc.
 */
async function authorizeJar(
  jarId: string,
  uid: string,
  secret: unknown,
): Promise<JarDoc> {
  const firestore = db();
  const [jarSnap, authSnap] = await firestore.getAll(jarRef(firestore, jarId), jarAuthRef(firestore, jarId));
  const jar = jarSnap?.data() as JarDoc | undefined;
  const secretHash = authSnap?.get("secretHash") as string | undefined;
  if (!jar || !secretHash) throw new HttpsError("not-found", "not found");
  if (jar.ownerUid === uid) return jar;
  if (secret !== undefined && verifySecret(secret, secretHash)) return jar;
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
  const ip = request.rawRequest.ip ?? "unknown";

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

  await authorizeJar(jarId, uid, data["secret"]);
  const now = Date.now();
  await jarRef(db(), jarId).update({
    profile: profile.value,
    lastSeenDay: Math.floor(now / DAY_MS),
    expiresAt: expiryTimestamp(now),
  });
  return { ok: true };
}

export async function deleteJarHandler(request: CallableRequest): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const jarId = requireJarId(data);
  await authorizeJar(jarId, uid, data["secret"]);
  // Recursive: the jar doc, private/{auth,rate}, and any pending tips go
  // together — nothing under a deleted jar may survive it.
  await db().recursiveDelete(jarRef(db(), jarId));
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
  const jar = await authorizeJar(jarId, uid, data["secret"]);

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
