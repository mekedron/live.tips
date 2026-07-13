/// stripeWebhook — the receiver Stripe pushes tips to, one endpoint per
/// connected band, routed by the 128-bit connectionId in the path
/// (POST /stripe/webhook/{connectionId}, via the Hosting rewrite).
///
/// The endpoint is public by necessity, so the SIGNATURE IS THE AUTH: every
/// request must carry a valid Stripe-Signature over the exact raw bytes,
/// keyed by that connection's own signing secret. An unverifiable request is
/// rejected loudly (400 + a warn log naming the connection, never the
/// payload) and touches nothing. Behind the signature sits a per-uid write
/// quota, so even a signed flood cannot write unbounded Firestore.
///
/// Privacy: an artist may run other business through the same Stripe
/// account. Only events that are tip-jar payments (their payment link) or
/// card-present taps become tips; everything else is answered 200 and NOT
/// stored — the privacy policy states this, so this filter is a promise,
/// not an optimization.
///
/// Stripe times out at 20 s and retries non-2xx for days: the work here is a
/// signature check, one mapping, and one small transaction-free batch —
/// milliseconds — and duplicates are welcome because the write is idempotent
/// (doc id = the Stripe object id; ALREADY_EXISTS is a no-op 200).

import type { Request } from "firebase-functions/v2/https";
import type { Response } from "express";
import { Timestamp } from "firebase-admin/firestore";
import { kmsKeyWrapper } from "./kms";
import { openSecret } from "./stripe-crypto";
import { tipFromEvent, verifyStripeSignature } from "./stripe-events";
import {
  MAX_STRIPE_PENDING,
  STRIPE_PENDING_TTL_MS,
  STRIPE_TIPS_PER_UID_PER_HOUR,
  stripeConnectionRef,
  stripeTipsCol,
  type StripeConnectionDoc,
} from "./stripe-store";
import { bumpQuota, db } from "./store";
import { isValidJarId } from "./validate";

/** Events are a few KB; anything bigger than this is not one of ours. */
const MAX_EVENT_BYTES = 262_144;

/**
 * Per-instance cache of unsealed signing secrets. Safe because a
 * connection's whsec never changes in place — reconnecting mints a NEW
 * connectionId — and worth having because every tip otherwise pays a KMS
 * round trip. The RESTRICTED KEY is deliberately never cached anywhere.
 */
const secretCache = new Map<string, string>();

function send(res: Response, status: number, body: Record<string, unknown>): void {
  res.status(status).set("Cache-Control", "no-store").json(body);
}

export async function stripeWebhookHandler(req: Request, res: Response): Promise<void> {
  if (req.method !== "POST") {
    send(res, 405, { error: "method not allowed" });
    return;
  }
  // The rewrite forwards the original path (/stripe/webhook/:connectionId);
  // a direct function-URL call carries the same suffix after the function name.
  const match = req.path.match(/\/stripe\/webhook\/([^/]+)\/?$/) ?? req.path.match(/\/([^/]+)\/?$/);
  const connectionId = match?.[1] ?? "";
  // Junk ids and unknown connections get the same 404 (anti-enumeration);
  // Stripe disables an endpoint that 404s persistently, which is exactly
  // right for a connection that no longer exists.
  if (!isValidJarId(connectionId)) {
    send(res, 404, { error: "not found" });
    return;
  }

  const firestore = db();
  const snap = await stripeConnectionRef(firestore, connectionId).get();
  const connection = snap.data() as StripeConnectionDoc | undefined;
  if (!connection) {
    send(res, 404, { error: "not found" });
    return;
  }

  const raw = req.rawBody;
  if (!raw || raw.byteLength === 0 || raw.byteLength > MAX_EVENT_BYTES) {
    send(res, 400, { error: "bad request" });
    return;
  }

  let secret = secretCache.get(connectionId);
  if (secret === undefined) {
    try {
      secret = await openSecret(connection.webhookSecret, kmsKeyWrapper());
      secretCache.set(connectionId, secret);
    } catch (e) {
      // KMS down or the envelope is damaged: 500 so Stripe retries — the
      // tips are delayed, not dropped, and the log says which connection.
      console.error(`stripeWebhook: cannot open signing secret for ${connectionId}`, e instanceof Error ? e.message : "");
      send(res, 500, { error: "internal" });
      return;
    }
  }

  // The auth. Exact raw bytes, this connection's secret, bounded clock skew.
  // Never verified against any other connection's secret, so one artist's
  // events cannot be replayed into another's jar.
  if (!verifyStripeSignature(raw.toString("utf8"), req.get("Stripe-Signature"), secret, Date.now())) {
    console.warn(`stripeWebhook: signature verification FAILED for ${connectionId} — rejected`);
    send(res, 400, { error: "signature verification failed" });
    return;
  }

  let event: unknown;
  try {
    event = JSON.parse(raw.toString("utf8"));
  } catch {
    send(res, 400, { error: "invalid JSON" });
    return;
  }

  // Not a tip (not our payment link, not card-present, not a subscribed
  // type, malformed): acknowledged and FORGOTTEN. No doc, no log line with
  // contents — see the privacy note at the top.
  const mapped = tipFromEvent(event, connection.paymentLinkId);
  if (mapped === null) {
    send(res, 200, { received: true, tip: false });
    return;
  }

  // The flood valve. 429 (not 200) on purpose: Stripe retries with backoff
  // for days, so a legitimate burst lands in a later bucket instead of
  // vanishing, while a flood stays out of Firestore.
  const now = Date.now();
  const allowed = await bumpQuota(
    firestore,
    `stripe-tips-${connection.uid}`,
    Math.floor(now / 3_600_000),
    STRIPE_TIPS_PER_UID_PER_HOUR,
    2 * 3_600_000,
  );
  if (!allowed) {
    console.warn(`stripeWebhook: per-uid tip quota exceeded for ${connectionId} — deferred`);
    send(res, 429, { error: "too many tips right now" });
    return;
  }

  const col = stripeTipsCol(firestore, connection.uid, connection.bandId);
  const batch = firestore.batch();

  // Bounded queue, oldest goes — same policy as the relay's pendingTips
  // (tip.ts): the tip that just landed is the one the artist can still
  // thank someone for, and a swept QR tip remains visible in History.
  const existing = await col.orderBy("tsMs").select().get();
  const overflow = existing.size - (MAX_STRIPE_PENDING - 1);
  if (overflow > 0) {
    for (const doc of existing.docs.slice(0, overflow)) batch.delete(doc.ref);
  }

  // Idempotency: the doc id IS the Stripe object id (cs_…/ch_…), and
  // create() refuses to overwrite. A Stripe retry, a re-sent event, and the
  // completed/async_payment_succeeded pair for one session all collapse
  // onto the same id — ALREADY_EXISTS is a successful no-op.
  batch.create(col.doc(mapped.id), {
    ...mapped.tip,
    // Undelivered tips age out on schedule, whether or not a device ever
    // comes back — same sweep as the relay queue.
    expiresAt: Timestamp.fromMillis(now + STRIPE_PENDING_TTL_MS),
  });

  try {
    await batch.commit();
  } catch (e) {
    const code = (e as { code?: number | string }).code;
    if (code === 6 || code === "already-exists" /* ALREADY_EXISTS */) {
      send(res, 200, { received: true, duplicate: true });
      return;
    }
    console.error(`stripeWebhook: write failed for ${connectionId}`, e instanceof Error ? e.message : "");
    send(res, 500, { error: "internal" });
    return;
  }

  send(res, 200, { received: true });
}
