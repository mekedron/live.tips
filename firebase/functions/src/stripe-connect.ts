/// stripeConnect / stripeDisconnect — where a cloud account hands us custody
/// of its Stripe restricted key, and takes it back.
///
/// The trust-model line this file draws (README.md states it in full): for a
/// signed-in cloud account, live.tips is now IN the Stripe path. The key
/// never reaches any device again — it is validated, probed, sealed with KMS
/// (stripe-crypto.ts) and stored server-only; Stripe pushes tips to our
/// webhook from here on and the app stops polling entirely. The local
/// no-account mode does not pass through here and keeps its key on-device.

import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { newJarId } from "./auth";
import { requireFreshSession, requireNonAnonymousUid } from "./devices";
import { dataObject } from "./jars";
import { kmsKeyWrapper } from "./kms";
import {
  StripeApi,
  StripeApiError,
  StripeNetworkError,
  STRIPE_API_VERSION,
  paymentLinkVisible,
  runKeyProbes,
  validateRestrictedKey,
  webhookUrlFor,
  type PermissionCheck,
} from "./stripe-api";
import { openSecret, sealSecret, type KeyWrapper } from "./stripe-crypto";
import { TIP_EVENT_TYPES } from "./stripe-events";
import {
  STRIPE_CONNECTS_PER_UID_PER_HOUR,
  isValidBandId,
  isValidPaymentLinkId,
  stripeConnectionRef,
  stripePointerRef,
  type StripeConnectionDoc,
  type StripePointerDoc,
} from "./stripe-store";
import { bumpQuota, db } from "./store";
import { isValidJarId } from "./validate";

/**
 * Where the artist's Stripe account will POST events: the Hosting rewrite in
 * front of the stripeWebhook function. A string param so emulators/staging
 * can point endpoints somewhere reachable.
 */
export const STRIPE_WEBHOOK_BASE = defineString("STRIPE_WEBHOOK_BASE", {
  default: "https://tip.live.tips/stripe/webhook",
});

// The probes themselves (KEY_PROBES / runKeyProbes / PermissionCheck) live
// in stripe-api.ts so the pure tests can pin the exact set without loading
// this module's Firestore/KMS graph.

// ---------------------------------------------------------------------------
// Shared plumbing

/** Stripe/network failures → callable errors, with no secrets in transit. */
export function stripeToHttpsError(e: unknown): HttpsError {
  if (e instanceof StripeApiError) {
    const details = { stripeStatus: e.status, stripeCode: e.code ?? null, stripeType: e.type ?? null, stripeParam: e.param ?? null };
    if (e.isAuthError) {
      return new HttpsError("failed-precondition", "Stripe rejected the stored key — reconnect with a fresh restricted key", details);
    }
    if (e.isPermissionError) return new HttpsError("permission-denied", e.message, details);
    if (e.status === 429) return new HttpsError("resource-exhausted", "Stripe is rate-limiting requests", details);
    if (e.status >= 500) return new HttpsError("unavailable", "Stripe is unavailable, try again", details);
    return new HttpsError("invalid-argument", e.message, details);
  }
  if (e instanceof StripeNetworkError) {
    return new HttpsError("unavailable", "could not reach Stripe, try again");
  }
  if (e instanceof HttpsError) return e;
  console.error("stripe surface: unexpected error", e);
  return new HttpsError("internal", "internal error");
}

function requireBandId(data: Record<string, unknown>): string {
  const bandId = data["bandId"];
  if (!isValidBandId(bandId)) throw new HttpsError("invalid-argument", "bandId is required");
  return bandId;
}

/** The KMS wrapper, or a clean 'internal' if the runtime is misconfigured —
 * never a path that stores anything unencrypted. */
function requireWrapper(): KeyWrapper {
  try {
    return kmsKeyWrapper();
  } catch (e) {
    console.error("stripeConnect: KMS unavailable", e);
    throw new HttpsError("internal", "server misconfigured");
  }
}

interface ConnectionLookup {
  connectionId: string;
  doc: StripeConnectionDoc;
}

/** The caller's connection for a band, via the pointer doc. */
export async function lookupConnection(uid: string, bandId: string): Promise<ConnectionLookup | null> {
  const firestore = db();
  const pointer = (await stripePointerRef(firestore, uid).get()).data() as StripePointerDoc | undefined;
  const connectionId = pointer?.connections?.[bandId];
  if (typeof connectionId !== "string" || !isValidJarId(connectionId)) return null;
  const snap = await stripeConnectionRef(firestore, connectionId).get();
  const doc = snap.data() as StripeConnectionDoc | undefined;
  // A dangling pointer (doc swept, partial delete) reads as not connected.
  if (!doc || doc.uid !== uid || doc.bandId !== bandId) return null;
  return { connectionId, doc };
}

/** Best-effort webhook-endpoint removal — cleanup in SOMEONE ELSE'S Stripe
 * dashboard must be attempted, but a revoked key must never block our own. */
async function tryDeleteEndpoint(api: StripeApi, endpointId: string, context: string): Promise<void> {
  try {
    await api.delete(`webhook_endpoints/${endpointId}`);
  } catch (e) {
    const status = e instanceof StripeApiError ? e.status : "network";
    console.warn(`${context}: could not delete webhook endpoint (${status}); it may remain on the artist's account`);
  }
}

// ---------------------------------------------------------------------------
// stripeConnect

export async function stripeConnectHandler(
  request: CallableRequest,
): Promise<{ ok: true; livemode: boolean; checks: PermissionCheck[] }> {
  // Cloud accounts only, as the header promises — enforced, not assumed. An
  // anonymous (guest) uid is unrecoverable by design: a key it sealed here,
  // and the live webhook endpoint with it, would be stranded with no
  // principal that could ever disconnect them.
  const uid = requireNonAnonymousUid(request);
  const data = dataObject(request);
  const bandId = requireBandId(data);

  const verdict = validateRestrictedKey(data["key"]);
  if (!verdict.ok) throw new HttpsError("invalid-argument", verdict.error);

  let paymentLinkId: string | null = null;
  if (data["paymentLinkId"] !== undefined) {
    if (!isValidPaymentLinkId(data["paymentLinkId"])) {
      throw new HttpsError("invalid-argument", "paymentLinkId must be a plink_… id");
    }
    paymentLinkId = data["paymentLinkId"];
  }

  const firestore = db();
  const now = Date.now();
  // Revocation watermark, callable-side like devices.ts: a stolen (revoked)
  // session must not hand us a key or re-point a webhook.
  await requireFreshSession(firestore, uid, request);
  const allowed = await bumpQuota(
    firestore, `stripe-connect-${uid}`, Math.floor(now / 3_600_000), STRIPE_CONNECTS_PER_UID_PER_HOUR, 2 * 3_600_000,
  );
  if (!allowed) throw new HttpsError("resource-exhausted", "too many connection attempts, try later");

  // The wrapper is resolved BEFORE any Stripe write: if KMS is down we must
  // find out while there is still nothing to clean up.
  const wrapper = requireWrapper();
  const api = new StripeApi(verdict.key);

  // Probe first — a key that cannot do the job is refused before anything is
  // stored or registered, with every missing permission spelled out.
  let checks: PermissionCheck[];
  try {
    checks = await runKeyProbes(api);
  } catch (e) {
    throw stripeToHttpsError(e);
  }
  if (!checks.every((c) => c.ok)) {
    throw new HttpsError("failed-precondition", "the key is missing permissions", { checks });
  }

  // Re-connecting replaces cleanly: remember the old connection so its
  // endpoint and ciphertext can go once the new one is in place.
  const existing = await lookupConnection(uid, bandId);
  if (existing && paymentLinkId === null && existing.doc.paymentLinkId !== null) {
    // Same account, fresh key: keep tracking the jar it already had. But a
    // reconnect can bring a DIFFERENT account's key, and carrying the old
    // account's link onto it would leave the webhook filtering every one of
    // the new account's checkout events out (stripe-events.ts) — the fan
    // paid, the tip evaporates, and nothing anywhere says why. So the link
    // survives only if the incoming key can see it; on Stripe's 404 the
    // field stays null and a jar gets created fresh, like a first connect.
    try {
      if (await paymentLinkVisible(api, existing.doc.paymentLinkId)) {
        paymentLinkId = existing.doc.paymentLinkId;
      }
    } catch (e) {
      throw stripeToHttpsError(e);
    }
  }

  // Register the receiver on the ARTIST'S account. The endpoint's signing
  // secret is returned exactly once, here; it goes straight into an envelope.
  const connectionId = newJarId();
  let endpoint: Record<string, unknown>;
  try {
    const params: Record<string, string> = {
      url: webhookUrlFor(STRIPE_WEBHOOK_BASE.value(), connectionId),
      // Pinned so event payloads keep the shapes stripe-events.ts parses,
      // whatever the account's default version does.
      api_version: STRIPE_API_VERSION,
      description: "live.tips — live tip feed (delete by disconnecting Stripe in the app)",
      "metadata[managed_by]": "live.tips",
    };
    TIP_EVENT_TYPES.forEach((type, i) => {
      params[`enabled_events[${i}]`] = type;
    });
    endpoint = await api.post("webhook_endpoints", params);
  } catch (e) {
    throw stripeToHttpsError(e);
  }
  const endpointId = endpoint["id"];
  const signingSecret = endpoint["secret"];
  if (typeof endpointId !== "string" || typeof signingSecret !== "string" || signingSecret.length === 0) {
    throw new HttpsError("internal", "Stripe returned an unusable webhook endpoint");
  }

  // From here to the commit, a failure would strand the endpoint we just
  // registered in the artist's dashboard — so seal-and-store rolls it back.
  try {
    const doc: StripeConnectionDoc = {
      uid,
      bandId,
      key: await sealSecret(verdict.key, wrapper),
      livemode: verdict.livemode,
      webhookEndpointId: endpointId,
      webhookSecret: await sealSecret(signingSecret, wrapper),
      paymentLinkId,
      createdAtMs: now,
    };
    const batch = firestore.batch();
    batch.create(stripeConnectionRef(firestore, connectionId), doc);
    batch.set(stripePointerRef(firestore, uid), { connections: { [bandId]: connectionId } }, { merge: true });
    if (existing) batch.delete(stripeConnectionRef(firestore, existing.connectionId));
    await batch.commit();
  } catch (e) {
    await tryDeleteEndpoint(api, endpointId, "stripeConnect(rollback)");
    console.error("stripeConnect: seal/store failed after endpoint registration", e instanceof Error ? e.message : "");
    throw new HttpsError("internal", "could not store the connection, nothing was kept");
  }

  // Only now is the old endpoint litter — remove it, tolerating everything:
  // the new key usually manages the same account; fall back to the old key
  // (the artist may have connected a different account this time).
  if (existing) {
    try {
      await api.delete(`webhook_endpoints/${existing.doc.webhookEndpointId}`);
    } catch {
      try {
        const oldKey = await openSecret(existing.doc.key, wrapper);
        await tryDeleteEndpoint(new StripeApi(oldKey), existing.doc.webhookEndpointId, "stripeConnect");
      } catch {
        console.warn("stripeConnect: old webhook endpoint could not be removed with either key");
      }
    }
  }

  return { ok: true, livemode: verdict.livemode, checks };
}

// ---------------------------------------------------------------------------
// stripeDisconnect

export async function stripeDisconnectHandler(request: CallableRequest): Promise<{ ok: true }> {
  // Same guard as connect: the custody surface is cloud accounts only.
  const uid = requireNonAnonymousUid(request);
  const data = dataObject(request);
  const bandId = requireBandId(data);
  const deactivateLink = data["deactivateLink"] === true;

  const firestore = db();
  // Same watermark as connect: a revoked session must not tear down (or
  // deactivate the link of) a connection the real owner still relies on.
  await requireFreshSession(firestore, uid, request);
  const existing = await lookupConnection(uid, bandId);
  if (existing === null) {
    // Nothing connected (or a previous disconnect half-finished): make sure
    // the pointer entry is gone and call it done — disconnect is idempotent.
    await stripePointerRef(firestore, uid).set(
      { connections: { [bandId]: FieldValue.delete() } }, { merge: true },
    );
    return { ok: true };
  }

  // Stripe-side cleanup is best effort THROUGHOUT: the artist may have
  // revoked the key in their dashboard already, and a dead key must never
  // leave our ciphertext lingering. Our side is cleaned up regardless.
  try {
    const key = await openSecret(existing.doc.key, requireWrapper());
    const api = new StripeApi(key);
    await tryDeleteEndpoint(api, existing.doc.webhookEndpointId, "stripeDisconnect");
    if (deactivateLink && existing.doc.paymentLinkId !== null) {
      try {
        await api.post(`payment_links/${existing.doc.paymentLinkId}`, { active: "false" });
      } catch {
        console.warn("stripeDisconnect: could not deactivate the payment link (key revoked?)");
      }
    }
  } catch (e) {
    console.warn("stripeDisconnect: could not open the stored key; cleaning up our side only", e instanceof Error ? e.message : "");
  }

  const batch = firestore.batch();
  batch.delete(stripeConnectionRef(firestore, existing.connectionId));
  batch.set(stripePointerRef(firestore, uid), { connections: { [bandId]: FieldValue.delete() } }, { merge: true });
  await batch.commit();
  return { ok: true };
}
