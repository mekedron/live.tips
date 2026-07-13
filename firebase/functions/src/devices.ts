/// Device management + QR add-device linking, as callables.
///
/// Two revocation layers, honestly separated:
///  - revokeDevice flips users/{uid}/devices/{id}.revoked — a COOPERATIVE
///    signal only. The target app observes its own doc and signs out; a
///    hostile client can simply ignore it. It exists for the common case
///    ("my old phone is in a drawer"), not the hostile one.
///  - revokeAllOtherDevices is the real kill switch: it stamps the
///    sessionsValidAfterMs watermark (rules cut every pre-watermark ID token
///    off users/** immediately), expires the uid's open QR grants (a
///    confirmed link code would otherwise mint a fresh POST-watermark token
///    through the unauthenticated collect handler), AND revokes refresh
///    tokens server-side, so stolen sessions die within the ID-token hour and
///    cannot renew. The caller's own session dies with the rest — so the
///    handler mints it a fresh custom token AFTER the revoke and hands it
///    back, and the client signs straight back in with it. That is the whole
///    re-entry: no provider round-trip at the one moment the account's
///    credentials are down (#34).
///
/// ONE QR flow lives here — ADD A DEVICE (linkCodes, linkcodes.ts): the
/// SIGNED-IN device shows the QR, the NEW device scans it, the signed-in
/// device confirms. pending→claimed→confirmed→used. The venue tablet takes
/// the same route (it scans the artist's QR); there is no separate
/// unsigned-device ceremony.
///
/// The QR carries only the code and the token is only collectable by the
/// device holding a nonce that never appeared in the QR — see linkcodes.ts for
/// why a photographed QR is useless.

import { getAuth } from "firebase-admin/auth";
import { Timestamp } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { ipQuotaKey, sha256Hex, verifySecret } from "./auth";
import { DIRECT_HOPS, clientIp } from "./client-ip";
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
 * Exported: the cloud-Stripe custody surface is for signed-in cloud accounts
 * only — a guest uid that sealed a key there could never come back to
 * disconnect it.
 */
export function requireNonAnonymousUid(request: CallableRequest): string {
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
 * Exported: the cloud-Stripe callables enforce the same watermark (a revoked
 * session must not read tip history or re-point a webhook).
 */
export async function requireFreshSession(
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
  // NOT rawRequest.ip: the platform-appended header entry is the only
  // address a caller cannot write (see client-ip.ts).
  const ip = clientIp(request.rawRequest, DIRECT_HOPS);
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
  state: { attempts: number },
  decision: { expire: boolean; countAttempt: boolean },
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
    // confirmedAtMs is what collectLinkToken measures against the owner's
    // revocation watermark — a code confirmed before a revokeAllOtherDevices
    // call must never mint after it.
    tx.update(ref, { status: "confirmed" satisfies LinkCodeStatus, confirmedAtMs: Date.now() });
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
 * {pending: true}; once confirmed, a custom token for the owning uid is
 * minted and THEN the code flips confirmed → used. Wrong nonces burn
 * attempts.
 *
 * Mint-before-burn, deliberately: flipping to 'used' inside the validating
 * transaction burnt the code BEFORE createCustomToken ran, so a failed mint
 * (IAM misconfiguration, a transient Auth outage) consumed the code anyway —
 * "Try again" needed a whole fresh QR, and the phone watching the doc saw
 * 'used' and reported a sign-in that never happened. Single use still holds:
 * the burn transaction re-validates, so of two racing collectors exactly one
 * flips confirmed → used and returns its token; the loser's minted token is
 * discarded unreturned (never disclosed to anyone, so inert).
 */
export async function collectLinkTokenHandler(
  request: CallableRequest,
): Promise<{ token?: string; pending?: true }> {
  const data = dataObject(request);
  const code = requireLinkCode(data);
  const nonce = data["nonce"];

  const firestore = db();
  await bumpIpQuota(firestore, request, "link-collect", LINK_COLLECTS_PER_IP_PER_HOUR);

  /** The validating read, shared by both phases; [consume] adds the burn. */
  const attempt = (consume: boolean) =>
    firestore.runTransaction(async (tx) => {
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
      const uid = snap.get("uid") as string;
      // The kill switch must hold HERE too: a code confirmed BEFORE the
      // owner's sessionsValidAfterMs watermark was pre-positioned by a session
      // the revocation has since killed, and minting for it would hand that
      // session a fresh post-watermark token. revokeAllOtherDevices sweeps
      // such codes to 'expired'; this gate closes the race with a confirm
      // that lands after the sweep ran. A confirmed code with no
      // confirmedAtMs fails closed once a watermark exists.
      const security = await tx.get(securityRef(firestore, uid));
      const watermark = security.get("sessionsValidAfterMs") as number | undefined;
      if (watermark !== undefined) {
        const confirmedAtMs = snap.get("confirmedAtMs") as number | undefined;
        if (typeof confirmedAtMs !== "number" || confirmedAtMs < watermark) {
          tx.update(ref, { status: "expired" satisfies LinkCodeStatus });
          return { failed: "precondition" as const, message: "code expired" };
        }
      }
      if (consume) tx.update(ref, { status: "used" satisfies LinkCodeStatus });
      return { failed: false as const, uid };
    });

  // Phase 1: validate without consuming — wrong nonces still burn attempts.
  const outcome = await attempt(false);
  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (outcome.failed === "precondition") throw new HttpsError("failed-precondition", outcome.message);
  if ("pending" in outcome) return { pending: true };

  // Phase 2: mint. A throw here leaves the code 'confirmed' and retryable.
  const token = await getAuth().createCustomToken(outcome.uid);

  // Phase 3: burn, re-validated — only the winner returns its token, and
  // 'used' on the doc now MEANS a token was actually handed over.
  const burned = await attempt(true);
  if (burned.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (burned.failed === "precondition") throw new HttpsError("failed-precondition", burned.message);
  if ("pending" in burned) {
    // Cannot regress confirmed → claimed mid-flight; refuse rather than leak.
    throw new HttpsError("failed-precondition", "code is not collectable");
  }
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
 * The real kill switch, in five moves:
 *  1. sessionsValidAfterMs = now — rules instantly shut every pre-now ID
 *     token out of users/** (and this surface, via requireFreshSession);
 *  2. every live QR grant dies: the link codes this uid owns flip to
 *     'expired'. The watermark alone cannot reach them — collectLinkToken is
 *     unauthenticated and mints POST-watermark tokens, so a code the stolen
 *     session already confirmed would otherwise walk straight through the
 *     revocation;
 *  3. every device doc except currentDeviceId gets revoked:true (the
 *     cooperative sign-out signal, plus honest UI state);
 *  4. admin revokeRefreshTokens(uid) — stolen sessions cannot renew, so they
 *     die for good when their current ID token expires (≤1h);
 *  5. a custom token for the CALLER, minted LAST — the one credential in the
 *     world that postdates this revocation, handed to the one client we
 *     authenticated on the way in.
 *
 * The caller is caught by 1 and 4 like everyone else — that is what makes the
 * switch real — so move 5 is how it comes back: signInWithCustomToken, same
 * uid, auth_time of NOW, which is exactly what the watermark stamped in move 1
 * demands. The order is the point. Nothing is minted before the revoke, so
 * nothing survives it; and a handler that throws anywhere above returns no
 * token at all (#34). The client used to re-run an INTERACTIVE Apple/Google
 * sign-in here, at the one moment the account's credentials were down — and
 * signed the artist out when that round-trip did not come back.
 *
 * ANY signed-in account may call it, guests included: a server-minted token
 * needs no provider to redeem, which was the only reason anonymous callers
 * were ever turned away. requireFreshSession still guards the door, and the
 * token is only ever for request.auth.uid — the caller can revoke nobody's
 * sessions but its own, and gains nothing it could not already mint through
 * mintSessionToken (session-token.ts).
 */
export async function revokeAllOtherDevicesHandler(
  request: CallableRequest,
): Promise<{ ok: true; revokedCount: number; token: string }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const currentDeviceId = requireDeviceId(data["currentDeviceId"]);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);

  const now = Date.now();
  // Watermark first: from this write on, every pre-existing token is out,
  // whatever happens to the rest of this handler.
  await securityRef(firestore, uid).set({ sessionsValidAfterMs: now }, { merge: true });

  // Move 2: the grant sweep. It rides the same (uid ASC, expiresAt ASC)
  // composite index as createLinkCode, status filtered in-memory. A 'used'
  // code keeps its history: it already handed its token over, and the token
  // is what the watermark kills.
  const ownedCodes = await firestore
    .collection("linkCodes")
    .where("uid", "==", uid)
    .where("expiresAt", ">", Timestamp.fromMillis(now))
    .get();
  const grants = firestore.batch();
  for (const doc of ownedCodes.docs) {
    const status = doc.get("status") as LinkCodeStatus;
    if (status === "pending" || status === "claimed" || status === "confirmed") {
      grants.update(doc.ref, { status: "expired" satisfies LinkCodeStatus });
    }
  }
  await grants.commit();

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
  // Move 5, and only now that every credential this account had is dead: the
  // caller's way back in. Redeeming it is a plain API call on the client's own
  // origin — no provider page, no redirect, nothing to cancel.
  const token = await getAuth().createCustomToken(uid);
  return { ok: true, revokedCount, token };
}
