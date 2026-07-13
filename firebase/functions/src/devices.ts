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
///    confirmed link code or approved login request would otherwise mint a
///    fresh POST-watermark token through the unauthenticated collect
///    handlers), AND revokes refresh tokens server-side, so stolen sessions
///    die within the ID-token hour and cannot renew. The
///    caller's own token predates the watermark too — the calling client
///    must silently re-authenticate right after (its refresh credential is
///    gone, its provider session is not).
///
/// TWO QR flows live here, and they are mirror images. Keep them straight:
///
///  - ADD A DEVICE (linkCodes, linkcodes.ts): the SIGNED-IN device shows the
///    QR, the NEW device scans it, the signed-in device confirms.
///    pending→claimed→confirmed→used.
///  - SIGN IN ON A SHARED DEVICE (loginRequests, loginrequests.ts): the
///    UNSIGNED device (a bar's tablet) shows the QR, the artist's SIGNED-IN
///    phone scans and approves it, the tablet collects the token.
///    pending→approved→used.
///
/// In both, the QR carries only an id and the token is only collectable by the
/// device holding a nonce that never appeared in the QR — see each pure module
/// for why a photographed QR is useless.

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
import {
  decideApprove,
  decideCollect as decideLoginCollect,
  decideDescribe,
  isValidLoginRequestId,
  LOGIN_DEVICE_NAME_MAX,
  LOGIN_DEVICE_PLATFORM_MAX,
  loginDeviceField,
  loginRequestExpiryMs,
  newCollectNonce,
  newDisplayCode,
  newLoginRequestId,
  parseLoginCode,
  type LoginRequestSnapshot,
  type LoginRequestStatus,
} from "./loginrequests";
import { IP_HASH_SALT } from "./params";
import {
  bumpQuota,
  db,
  devicesCol,
  deviceRef,
  LINK_COLLECTS_PER_IP_PER_HOUR,
  LINK_REDEEMS_PER_IP_PER_HOUR,
  linkCodeRef,
  LOGIN_COLLECTS_PER_IP_PER_HOUR,
  LOGIN_CREATES_PER_IP_PER_HOUR,
  LOGIN_DESCRIBES_PER_IP_PER_HOUR,
  loginRequestRef,
  loginRequestsCol,
  securityRef,
  type LinkCodeDoc,
  type LoginRequestDoc,
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

/**
 * Apply a rejection's side effects (expire / burn an attempt) inside the tx.
 * Shared by both QR flows: LinkDecision and LoginDecision are deliberately the
 * same shape, and 'expired' means the same thing in both status machines.
 */
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
// The OTHER QR flow: signing in on a shared, unsigned-in device (the tablet
// behind the bar that four artists take turns on). Mirror image of the four
// handlers above — here the UNSIGNED device shows the QR and the SIGNED-IN
// phone approves. Nothing about a login request is client-readable: the tablet
// has no uid, so rules grant loginRequests nothing at all and both sides learn
// everything from these callable returns.

function loginSnapshotOf(snap: DocumentSnapshot): LoginRequestSnapshot {
  const doc = snap.data() as LoginRequestDoc;
  return {
    status: doc.status as LoginRequestStatus,
    expiresAtMs: doc.expiresAt.toMillis(),
    attempts: doc.attempts ?? 0,
  };
}

/**
 * Resolve what the phone sent — a 22-char requestId out of the QR, or the
 * 8-char displayCode a human typed — to the request's document.
 *
 * The displayCode is not a document id and carries no uniqueness constraint,
 * so it is QUERIED, and an ambiguous answer is treated as no answer: expired
 * requests linger until the hourly sweep, so a code could in principle (p ≈
 * 1e-5 across a day's traffic at 40 bits) match a live request and a dead one.
 * Refusing the ambiguous case costs a live tablet one QR rotation and removes
 * any chance of approving the wrong request.
 */
async function resolveLoginRequest(
  firestore: Firestore,
  raw: unknown,
  nowMs: number,
): Promise<DocumentReference> {
  const parsed = parseLoginCode(raw);
  // Malformed codes answer exactly like unknown ones (anti-enumeration).
  if (parsed === null) throw new HttpsError("not-found", "not found");
  if (parsed.kind === "requestId") return loginRequestRef(firestore, parsed.value);

  const matches = await loginRequestsCol(firestore)
    .where("displayCode", "==", parsed.value)
    .limit(5)
    .get();
  const live = matches.docs.filter((d) => {
    const doc = d.data() as LoginRequestDoc;
    return doc.status === "pending" && doc.expiresAt.toMillis() > nowMs;
  });
  if (live.length !== 1) throw new HttpsError("not-found", "not found");
  return live[0]!.ref;
}

/**
 * Step 1, on the SHARED TABLET — unauthenticated (that is the whole point:
 * this device has no account yet), therefore salted-IP rate-limited.
 *
 * Mints a 128-bit requestId (the QR payload), a 128-bit collectNonce (returned
 * to this tablet ONLY, stored as sha256, never in the QR — it is what stops a
 * photographed QR from being collectable by the photographer), and an 8-char
 * displayCode for the artist whose camera will not focus in a dark bar.
 * TTL 60 s: the tablet should re-mint every ~45 s.
 *
 * Never log the requestId, the nonce, or the displayCode.
 */
export async function createLoginRequestHandler(
  request: CallableRequest,
): Promise<{ requestId: string; displayCode: string; collectNonce: string; expiresAtMs: number }> {
  const data = dataObject(request);
  const name = loginDeviceField(data["deviceName"], LOGIN_DEVICE_NAME_MAX);
  const platform = loginDeviceField(data["devicePlatform"], LOGIN_DEVICE_PLATFORM_MAX);
  // Required: the approver's whole safety check is reading what they are about
  // to sign in to. An unnamed request would present as "sign in… somewhere?".
  if (name === null) throw new HttpsError("invalid-argument", "deviceName is required");
  if (platform === null) throw new HttpsError("invalid-argument", "devicePlatform is required");

  const firestore = db();
  await bumpIpQuota(firestore, request, "login-create", LOGIN_CREATES_PER_IP_PER_HOUR);

  const now = Date.now();
  const requestId = newLoginRequestId();
  const collectNonce = newCollectNonce();
  const expiresAtMs = loginRequestExpiryMs(now);
  const doc: LoginRequestDoc = {
    status: "pending",
    createdAtMs: now,
    expiresAt: Timestamp.fromMillis(expiresAtMs),
    displayCode: newDisplayCode(),
    deviceName: name,
    devicePlatform: platform,
    collectNonceHash: sha256Hex(collectNonce),
    attempts: 0,
  };
  // create(), not set(): a requestId collision (2^-128) must fail, not merge.
  await loginRequestRef(firestore, requestId).create(doc);
  return { requestId, displayCode: doc.displayCode, collectNonce, expiresAtMs };
}

/**
 * Step 2, on the artist's PHONE (signed in) — what the QR scan hits first, so
 * the human can be shown WHAT they are about to sign in to ("Sign in on Bar
 * tablet (iPad)?") before they approve anything.
 *
 * Returns the device's own (untrusted, scrubbed) label and nothing else: not
 * the status, not the approver, not the nonce, not the displayCode. Unknown,
 * expired, already-approved and already-used requests are all the same
 * 'not-found' — a code that has been used up must not be distinguishable from
 * one that never existed. Counts an attempt, because this is the surface a
 * displayCode-guesser would hammer.
 */
export async function describeLoginRequestHandler(
  request: CallableRequest,
): Promise<{ deviceName: string | null; devicePlatform: string | null; expiresAtMs: number }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);
  await bumpIpQuota(firestore, request, "login-describe", LOGIN_DESCRIBES_PER_IP_PER_HOUR);

  const ref = await resolveLoginRequest(firestore, data["code"], Date.now());
  const outcome = await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { failed: "not-found" as const };
    const state = loginSnapshotOf(snap);
    const decision = decideDescribe(state, Date.now());
    if (!decision.ok) {
      applyRejection(tx, ref, state, decision);
      return { failed: "not-found" as const };
    }
    tx.update(ref, { attempts: state.attempts + 1 });
    const doc = snap.data() as LoginRequestDoc;
    return {
      failed: false as const,
      deviceName: doc.deviceName ?? null,
      devicePlatform: doc.devicePlatform ?? null,
      expiresAtMs: state.expiresAtMs,
    };
  });

  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  return {
    deviceName: outcome.deviceName,
    devicePlatform: outcome.devicePlatform,
    expiresAtMs: outcome.expiresAtMs,
  };
}

/**
 * Step 3, on the artist's PHONE: the human tap that turns a worthless QR into
 * a session. pending → approved, stamping the CALLER's uid — the only uid this
 * request can ever mint a token for.
 *
 * ANONYMOUS CALLERS ARE ALLOWED, deliberately, and this is the one place in
 * this file where that is true (contrast requireNonAnonymousUid above). A
 * guest account has no credential to sign in with anywhere; approving a login
 * request is the ONLY way it can ever reach a second screen, and the only way
 * an artist's jars survive a lost phone. Refusing anonymous here would protect
 * nobody and strand everybody. Approving cannot strand the caller either — it
 * hands out an additional session, it does not revoke the current one.
 *
 * A stale (post-revocation) session may not approve: requireFreshSession is
 * the same gate the rules apply to users/**, or a stolen session could laminate
 * itself onto a fresh device and outlive the revocation.
 */
export async function approveLoginRequestHandler(
  request: CallableRequest,
): Promise<{ ok: true }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const firestore = db();
  await requireFreshSession(firestore, uid, request);
  await bumpIpQuota(firestore, request, "login-approve", LOGIN_DESCRIBES_PER_IP_PER_HOUR);

  const ref = await resolveLoginRequest(firestore, data["code"], Date.now());
  const outcome = await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { failed: "not-found" as const };
    const state = loginSnapshotOf(snap);
    const decision = decideApprove(state, Date.now());
    if (!decision.ok) {
      applyRejection(tx, ref, state, decision);
      return { failed: "precondition" as const, message: decision.message };
    }
    // approvedAtMs is what collectLoginToken measures against the approver's
    // revocation watermark — an approval that predates a revokeAllOtherDevices
    // call must never mint after it.
    tx.update(ref, {
      status: "approved" satisfies LoginRequestStatus,
      approvedUid: uid,
      approvedAtMs: Date.now(),
      attempts: state.attempts + 1,
    });
    return { failed: false as const };
  });

  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (outcome.failed === "precondition") throw new HttpsError("failed-precondition", outcome.message);
  return { ok: true };
}

/**
 * Step 4, back on the TABLET — unauthenticated, polled (~5 s; see
 * LOGIN_COLLECTS_PER_IP_PER_HOUR before polling faster). {requestId,
 * collectNonce}: while nobody has approved yet it answers {pending: true} (not
 * an error — this is the normal state of a tablet standing on a bar), and once
 * approved the transaction flips approved → used (single use IS that
 * transition) and only then mints a custom token for the approver's uid.
 *
 * The nonce is what makes the QR safe to photograph: only the tablet that
 * CREATED the request has ever seen it, so only that tablet can collect. Wrong
 * nonces burn attempts and force-expire the request at 5 — a leaked requestId
 * therefore buys 5 guesses at a 128-bit secret.
 *
 * Never log the token, the nonce, or the requestId.
 */
export async function collectLoginTokenHandler(
  request: CallableRequest,
): Promise<{ token?: string; pending?: true }> {
  const data = dataObject(request);
  const requestId = data["requestId"];
  // The tablet always holds the real id (it minted it); a displayCode is not
  // accepted here, so nobody can collect against a code they read off a screen.
  if (typeof requestId !== "string" || !isValidLoginRequestId(requestId)) {
    throw new HttpsError("not-found", "not found");
  }
  const nonce = data["collectNonce"];

  const firestore = db();
  await bumpIpQuota(firestore, request, "login-collect", LOGIN_COLLECTS_PER_IP_PER_HOUR);

  // Mint-before-burn, exactly like collectLinkTokenHandler (see the comment
  // there): a failed mint must leave the request 'approved' and retryable,
  // not consumed by a token that never existed.
  const attempt = (consume: boolean) =>
    firestore.runTransaction(async (tx) => {
      const ref = loginRequestRef(firestore, requestId);
      const snap = await tx.get(ref);
      if (!snap.exists) return { failed: "not-found" as const };
      const state = loginSnapshotOf(snap);
      const storedHash = snap.get("collectNonceHash") as string | undefined;
      const nonceMatches = typeof storedHash === "string" && verifySecret(nonce, storedHash);
      const decision = decideLoginCollect(state, Date.now(), nonceMatches);
      if (!decision.ok) {
        applyRejection(tx, ref, state, decision);
        return { failed: "precondition" as const, message: decision.message };
      }
      if (decision.pending) return { failed: false as const, pending: true as const };
      const approvedUid = snap.get("approvedUid") as string | undefined;
      // An 'approved' doc with no approvedUid cannot happen (one transaction
      // writes both); if it ever did, mint nothing.
      if (typeof approvedUid !== "string" || approvedUid.length === 0) {
        return { failed: "precondition" as const, message: "request is not collectable" };
      }
      // The same watermark gate as collectLinkToken (see there for the full
      // argument): an approval stamped before the approver's revocation
      // watermark was made by a session the revocation killed, so it may not
      // mint. Missing approvedAtMs fails closed once a watermark exists.
      const security = await tx.get(securityRef(firestore, approvedUid));
      const watermark = security.get("sessionsValidAfterMs") as number | undefined;
      if (watermark !== undefined) {
        const approvedAtMs = snap.get("approvedAtMs") as number | undefined;
        if (typeof approvedAtMs !== "number" || approvedAtMs < watermark) {
          tx.update(ref, { status: "expired" satisfies LoginRequestStatus });
          return { failed: "precondition" as const, message: "request expired" };
        }
      }
      if (consume) tx.update(ref, { status: "used" satisfies LoginRequestStatus });
      return { failed: false as const, uid: approvedUid };
    });

  const outcome = await attempt(false);
  if (outcome.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (outcome.failed === "precondition") throw new HttpsError("failed-precondition", outcome.message);
  if ("pending" in outcome) return { pending: true };

  const token = await getAuth().createCustomToken(outcome.uid);

  const burned = await attempt(true);
  if (burned.failed === "not-found") throw new HttpsError("not-found", "not found");
  if (burned.failed === "precondition") throw new HttpsError("failed-precondition", burned.message);
  if ("pending" in burned) {
    throw new HttpsError("failed-precondition", "request is not collectable");
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
 * The real kill switch, in four moves:
 *  1. sessionsValidAfterMs = now — rules instantly shut every pre-now ID
 *     token out of users/** (and this surface, via requireFreshSession);
 *  2. every live QR grant dies: link codes this uid owns and login requests
 *     it approved flip to 'expired'. The watermark alone cannot reach them —
 *     collect* is unauthenticated and mints POST-watermark tokens, so a code
 *     the stolen session already confirmed (or a request it approved) would
 *     otherwise walk straight through the revocation;
 *  3. every device doc except currentDeviceId gets revoked:true (the
 *     cooperative sign-out signal, plus honest UI state);
 *  4. admin revokeRefreshTokens(uid) — stolen sessions cannot renew, so they
 *     die for good when their current ID token expires (≤1h).
 * The CALLER is caught by 1 and 4 as well: their client must silently
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

  // Move 2: the grant sweep. linkCodes rides the same (uid ASC, expiresAt
  // ASC) composite index as createLinkCode, status filtered in-memory;
  // loginRequests is a single equality on approvedUid (auto-indexed, no
  // composite needed) — the field only exists once someone approved, and a
  // uid stamps at most a handful before the hourly sweep deletes them.
  const [ownedCodes, approvedLogins] = await Promise.all([
    firestore
      .collection("linkCodes")
      .where("uid", "==", uid)
      .where("expiresAt", ">", Timestamp.fromMillis(now))
      .get(),
    loginRequestsCol(firestore).where("approvedUid", "==", uid).get(),
  ]);
  const grants = firestore.batch();
  for (const doc of ownedCodes.docs) {
    const status = doc.get("status") as LinkCodeStatus;
    if (status === "pending" || status === "claimed" || status === "confirmed") {
      grants.update(doc.ref, { status: "expired" satisfies LinkCodeStatus });
    }
  }
  for (const doc of approvedLogins.docs) {
    if ((doc.get("status") as LoginRequestStatus) === "approved") {
      grants.update(doc.ref, { status: "expired" satisfies LoginRequestStatus });
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
  return { ok: true, revokedCount };
}
