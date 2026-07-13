/// Device management + QR add-device linking, as callables.
///
/// Two revocation layers, honestly separated:
///  - revokeDevice flips users/{uid}/devices/{id}.revoked — a COOPERATIVE
///    signal only. The target app observes its own doc and signs out; a
///    hostile client can simply ignore it. It exists for the common case
///    ("my old phone is in a drawer"), not the hostile one.
///  - revokeAllOtherDevices is the real kill switch: it stamps the
///    sessionsValidAfterMs watermark (rules cut every pre-watermark ID token
///    off users/** immediately) AND revokes refresh tokens server-side, so
///    stolen sessions die within the ID-token hour and cannot renew. The
///    caller's own token predates the watermark too — the calling client
///    must silently re-authenticate right after (its refresh credential is
///    gone, its provider session is not).
///
/// The link-code handshake lives in linkcodes.ts (pure) + these handlers;
/// see that file for the pending→claimed→confirmed→used lifecycle and why a
/// photographed QR is useless.

import { getAuth } from "firebase-admin/auth";
import { Timestamp } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { ipQuotaKey, sha256Hex, verifySecret } from "./auth";
import { dataObject, requireUid } from "./jars";
import {
  isAnonymousProvider,
  isValidLinkCode,
  linkCodeExpiryMs,
  MAX_LIVE_LINK_CODES,
  newLinkCode,
  newLinkNonce,
  REQUESTER_NAME_MAX,
  REQUESTER_PLATFORM_MAX,
  requesterField,
  decideCollect,
  decideConfirm,
  decideRedeem,
  type LinkCodeSnapshot,
  type LinkCodeStatus,
  type LinkDecision,
} from "./linkcodes";
import { IP_HASH_SALT } from "./params";
import {
  bumpQuota,
  db,
  devicesCol,
  deviceRef,
  LINK_COLLECTS_PER_IP_PER_HOUR,
  LINK_REDEEMS_PER_IP_PER_HOUR,
  linkCodeRef,
  securityRef,
  type LinkCodeDoc,
} from "./store";
import { isValidDeviceId } from "./validate";

import type {
  DocumentReference,
  DocumentSnapshot,
  Firestore,
  Transaction,
} from "firebase-admin/firestore";

// ---------------------------------------------------------------------------
// Shared guards

/**
 * Auth + a permanent sign-in method. Anonymous callers are rejected with
 * 'failed-precondition': an anonymous account minted onto a second device
 * (or with all sessions revoked) has no credential to ever sign in with
 * again, so these operations would be a data-loss footgun for them.
 */
function requireNonAnonymousUid(request: CallableRequest): string {
  const uid = requireUid(request);
  const provider = request.auth?.token.firebase?.sign_in_provider;
  if (isAnonymousProvider(provider)) {
    throw new HttpsError("failed-precondition", "link a permanent sign-in method first");
  }
  return uid;
}

/**
 * The callable-side twin of the rules' notRevoked(): a token minted before
 * the account's sessionsValidAfterMs watermark may not drive the device
 * surface either — otherwise a stolen (revoked) session could confirm its
 * own link code and mint a fresh custom token, outliving the revocation.
 */
async function requireFreshSession(
  firestore: Firestore,
  uid: string,
  request: CallableRequest,
): Promise<void> {
  const snap = await securityRef(firestore, uid).get();
  const watermark = snap.get("sessionsValidAfterMs") as number | undefined;
  if (watermark === undefined) return; // never revoked — no penalty
  const authTime = request.auth?.token.auth_time; // seconds
  if (typeof authTime !== "number" || authTime * 1000 < watermark) {
    throw new HttpsError("unauthenticated", "session revoked — sign in again");
  }
}

function requireLinkCode(data: Record<string, unknown>): string {
  const code = data["code"];
  // Malformed codes answer exactly like missing ones (anti-enumeration).
  if (typeof code !== "string" || !isValidLinkCode(code)) {
    throw new HttpsError("not-found", "not found");
  }
  return code;
}

/** Salted per-IP quota, failing closed on a missing salt like createJar. */
async function bumpIpQuota(
  firestore: Firestore,
  request: CallableRequest,
  scope: string,
  limit: number,
): Promise<void> {
  const salt = IP_HASH_SALT.value();
  if (!salt) throw new HttpsError("internal", "server misconfigured");
  const ip = request.rawRequest.ip ?? "unknown";
  const now = Date.now();
  const allowed = await bumpQuota(
    firestore, ipQuotaKey(ip, salt, scope), Math.floor(now / 3_600_000), limit, 2 * 3_600_000,
  );
  if (!allowed) throw new HttpsError("resource-exhausted", "too many attempts, try later");
}

function snapshotOf(snap: DocumentSnapshot): LinkCodeSnapshot {
  const doc = snap.data() as LinkCodeDoc;
  return {
    status: doc.status as LinkCodeStatus,
    expiresAtMs: doc.expiresAt.toMillis(),
    attempts: doc.attempts ?? 0,
  };
}

/** Apply a rejection's side effects (expire / burn an attempt) inside the tx. */
function applyRejection(
  tx: Transaction,
  ref: DocumentReference,
  state: LinkCodeSnapshot,
  decision: LinkDecision & { ok: false },
): void {
  const update: Record<string, unknown> = {};
  if (decision.countAttempt) update["attempts"] = state.attempts + 1;
  if (decision.expire) update["status"] = "expired";
  if (Object.keys(update).length > 0) tx.update(ref, update);
}

// ---------------------------------------------------------------------------
// The QR handshake

/**
 * Step 1, on the signed-in device (A). Mints a 128-bit code, caps an account
 * at 3 open codes, TTL 2 min. No nonce exists yet — it is minted at redeem
 * time and belongs to the redeeming device alone.
 * Returns {code, expiresAtMs}; A renders the code as a QR and listens on
 * linkCodes/{code} (owner read is allowed by rules) to show the requester.
 */
export async function createLinkCodeHandler(
  request: CallableRequest,
): Promise<{ code: string; expiresAtMs: number }> {
  const uid = requireNonAnonymousUid(request);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);

  const now = Date.now();
  // Cap open codes. Composite index (uid ASC, expiresAt ASC) in
  // firestore.indexes.json; status is filtered here (in-memory) to keep the
  // index two fields wide.
  const live = await firestore
    .collection("linkCodes")
    .where("uid", "==", uid)
    .where("expiresAt", ">", Timestamp.fromMillis(now))
    .get();
  const open = live.docs.filter((d) => {
    const status = d.get("status") as LinkCodeStatus;
    return status === "pending" || status === "claimed";
  }).length;
  if (open >= MAX_LIVE_LINK_CODES) {
    throw new HttpsError("resource-exhausted", "too many open link codes, wait a minute");
  }

  const code = newLinkCode();
  const expiresAtMs = linkCodeExpiryMs(now);
  const doc: LinkCodeDoc = {
    uid,
    status: "pending",
    createdAtMs: now,
    expiresAt: Timestamp.fromMillis(expiresAtMs),
    attempts: 0,
  };
  // create(), not set(): a codeId collision (2^-128) must fail, not merge.
  await linkCodeRef(firestore, code).create(doc);
  return { code, expiresAtMs };
}

/**
 * Step 2, on the NEW device (B) — unauthenticated, therefore IP-rate-limited
 * (salted hash) and attempt-capped per code. pending → claimed; mints the
 * redeem nonce, stores only its sha256, and returns the nonce to B. B then
 * polls collectLinkToken until A confirms.
 */
export async function redeemLinkCodeHandler(
  request: CallableRequest,
): Promise<{ nonce: string }> {
  const data = dataObject(request);
  const code = requireLinkCode(data);
  const name = requesterField(data["deviceName"], REQUESTER_NAME_MAX);
  const platform = requesterField(data["devicePlatform"], REQUESTER_PLATFORM_MAX);
  if (name === null) throw new HttpsError("invalid-argument", "deviceName is required");
  if (platform === null) throw new HttpsError("invalid-argument", "devicePlatform is required");

  const firestore = db();
  await bumpIpQuota(firestore, request, "link-redeem", LINK_REDEEMS_PER_IP_PER_HOUR);

  // Minted outside the transaction so retries commit one consistent hash.
  const nonce = newLinkNonce();
  const outcome = await firestore.runTransaction(async (tx) => {
    const ref = linkCodeRef(firestore, code);
    const snap = await tx.get(ref);
    if (!snap.exists) return { failed: "not-found" as const };
    const state = snapshotOf(snap);
    const decision = decideRedeem(state, Date.now());
    if (!decision.ok) {
      applyRejection(tx, ref, state, decision);
      return { failed: "precondition" as const, message: decision.message };
    }
    tx.update(ref, {
      status: "claimed" satisfies LinkCodeStatus,
      attempts: state.attempts + 1,
      requester: { name, platform },
      redeemNonceHash: sha256Hex(nonce),
    });
    return { failed: false as const };
  });

  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (outcome.failed === "precondition") throw new HttpsError("failed-precondition", outcome.message);
  return { nonce };
}

/**
 * Step 3, back on the signed-in device (A): the anti-phishing gate. Only the
 * code's owning uid may confirm, and only a claimed, unexpired code. Until
 * this tap, a scanned/photographed QR is parked — collect returns pending.
 */
export async function confirmLinkCodeHandler(
  request: CallableRequest,
): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const code = requireLinkCode(data);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);

  const outcome = await firestore.runTransaction(async (tx) => {
    const ref = linkCodeRef(firestore, code);
    const snap = await tx.get(ref);
    if (!snap.exists) return { failed: "not-found" as const };
    if ((snap.get("uid") as string) !== uid) return { failed: "denied" as const };
    const state = snapshotOf(snap);
    const decision = decideConfirm(state, Date.now());
    if (!decision.ok) {
      applyRejection(tx, ref, state, decision);
      return { failed: "precondition" as const, message: decision.message };
    }
    tx.update(ref, { status: "confirmed" satisfies LinkCodeStatus });
    return { failed: false as const };
  });

  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (outcome.failed === "denied") throw new HttpsError("permission-denied", "unauthorized");
  if (outcome.failed === "precondition") throw new HttpsError("failed-precondition", outcome.message);
  return { ok: true };
}

/**
 * Step 4, on the new device (B) — unauthenticated. B polls this with
 * {code, nonce}: while the code is claimed-but-unconfirmed it answers
 * {pending: true}; once confirmed, the transaction flips confirmed → used
 * (single use enforced by that transition) and only then a custom token for
 * the owning uid is minted and returned. Wrong nonces burn attempts.
 */
export async function collectLinkTokenHandler(
  request: CallableRequest,
): Promise<{ token?: string; pending?: true }> {
  const data = dataObject(request);
  const code = requireLinkCode(data);
  const nonce = data["nonce"];

  const firestore = db();
  await bumpIpQuota(firestore, request, "link-collect", LINK_COLLECTS_PER_IP_PER_HOUR);

  const outcome = await firestore.runTransaction(async (tx) => {
    const ref = linkCodeRef(firestore, code);
    const snap = await tx.get(ref);
    if (!snap.exists) return { failed: "not-found" as const };
    const state = snapshotOf(snap);
    const storedHash = snap.get("redeemNonceHash") as string | undefined;
    const nonceMatches = typeof storedHash === "string" && verifySecret(nonce, storedHash);
    const decision = decideCollect(state, Date.now(), nonceMatches);
    if (!decision.ok) {
      applyRejection(tx, ref, state, decision);
      return { failed: "precondition" as const, message: decision.message };
    }
    if (decision.pending) return { failed: false as const, pending: true as const };
    tx.update(ref, { status: "used" satisfies LinkCodeStatus });
    return { failed: false as const, uid: snap.get("uid") as string };
  });

  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (outcome.failed === "precondition") throw new HttpsError("failed-precondition", outcome.message);
  if ("pending" in outcome) return { pending: true };
  const token = await getAuth().createCustomToken(outcome.uid);
  return { token };
}

// ---------------------------------------------------------------------------
// Revocation

function requireDeviceId(value: unknown): string {
  if (typeof value !== "string" || !isValidDeviceId(value)) {
    throw new HttpsError("invalid-argument", "deviceId is required");
  }
  return value;
}

/**
 * Cooperative single-device revocation: flips the flag the target device
 * watches and signs itself out on. It does NOT invalidate any Firebase
 * session — a hostile or offline client keeps its access until
 * revokeAllOtherDevices. Anonymous accounts may use it (they only ever have
 * the one device; revoking a stray doc is harmless).
 */
export async function revokeDeviceHandler(
  request: CallableRequest,
): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const deviceId = requireDeviceId(data["deviceId"]);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);

  try {
    await deviceRef(firestore, uid, deviceId).update({
      revoked: true,
      revokedAtMs: Date.now(),
    });
  } catch {
    throw new HttpsError("not-found", "not found");
  }
  return { ok: true };
}

/**
 * The real kill switch, in three moves:
 *  1. sessionsValidAfterMs = now — rules instantly shut every pre-now ID
 *     token out of users/** (and this surface, via requireFreshSession);
 *  2. every device doc except currentDeviceId gets revoked:true (the
 *     cooperative sign-out signal, plus honest UI state);
 *  3. admin revokeRefreshTokens(uid) — stolen sessions cannot renew, so they
 *     die for good when their current ID token expires (≤1h).
 * The CALLER is caught by 1 and 3 as well: their client must silently
 * re-authenticate immediately afterwards (fresh auth_time, fresh refresh
 * token). Non-anonymous only — an anonymous account cannot re-authenticate.
 */
export async function revokeAllOtherDevicesHandler(
  request: CallableRequest,
): Promise<{ ok: true; revokedCount: number }> {
  const uid = requireNonAnonymousUid(request);
  const data = dataObject(request);
  const currentDeviceId = requireDeviceId(data["currentDeviceId"]);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);

  const now = Date.now();
  // Watermark first: from this write on, every pre-existing token is out,
  // whatever happens to the rest of this handler.
  await securityRef(firestore, uid).set({ sessionsValidAfterMs: now }, { merge: true });

  const devices = await devicesCol(firestore, uid).get();
  let revokedCount = 0;
  let batch = firestore.batch();
  let inBatch = 0;
  for (const doc of devices.docs) {
    if (doc.id === currentDeviceId) continue;
    if (doc.get("revoked") === true) continue;
    batch.update(doc.ref, { revoked: true, revokedAtMs: now });
    revokedCount++;
    if (++inBatch === 400) {
      await batch.commit();
      batch = firestore.batch();
      inBatch = 0;
    }
  }
  if (inBatch > 0) await batch.commit();

  await getAuth().revokeRefreshTokens(uid);
  return { ok: true, revokedCount };
}
