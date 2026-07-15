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
/// twice over. The tip doc's id IS the Stripe object id and create() refuses
/// to overwrite; the processedEvents tombstone written beside it answers for
/// the id until Stripe's retry window is safely over. Since #71 the
/// tombstone is also what pins the DESTINATION: a mapped tip is written
/// straight into the account (the live session's tips subcollection, or the
/// band's relayTips archive — tip-destination.ts, the same router the relay
/// POST uses), and where a tip lands moves with the set — so a redelivery
/// must be answered by the tombstone, not by hoping create() meets the
/// first delivery's doc.

import type { Request } from "firebase-functions/v2/https";
import type { Response } from "express";
import { Timestamp } from "firebase-admin/firestore";
import { kmsKeyWrapper } from "./kms";
import { openSecret } from "./stripe-crypto";
import { tipFromEvent, verifyStripeSignature } from "./stripe-events";
import {
  STRIPE_PROCESSED_TTL_MS,
  STRIPE_TIPS_PER_UID_PER_HOUR,
  processedEventRef,
  stripeConnectionRef,
  type StripeConnectionDoc,
} from "./stripe-store";
import { recordTipNotification } from "./notifications";
import { bumpQuota, db } from "./store";
import { routedTipRef, stripeTipWire } from "./tip-destination";
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

  // Not a tip (not our payment link — tip jar or song-request link — not
  // card-present, not a subscribed type, malformed): acknowledged and
  // FORGOTTEN. No doc, no log line with contents — see the privacy note at
  // the top.
  const mapped = tipFromEvent(event, connection.paymentLinkId, connection.requestLinks ?? {});
  if (mapped === null) {
    send(res, 200, { received: true, tip: false });
    return;
  }

  // The dedupe that OUTLIVES the queue entry. The create() below refuses to
  // overwrite a live tip doc, but the queue's contract is delivery-is-
  // deletion, and Stripe delivers at-least-once: an event already answered
  // 200 can be redelivered days later, AFTER the tip was collected — and
  // would sail through create() onto the stage a second time. The tombstone
  // written beside every tip answers for the id until Stripe's retry window
  // is safely over. Checked before the quota so a redelivery is a cheap
  // duplicate 200, never a 429 that keeps Stripe re-sending it.
  const tombstoneRef = processedEventRef(firestore, mapped.id);
  if ((await tombstoneRef.get()).exists) {
    send(res, 200, { received: true, duplicate: true });
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

  // Where the tip lands (#71): the connection doc already carries the route
  // (uid + bandId), and the shared router picks the live session's tips
  // subcollection or the band's relayTips archive. No cap and no TTL —
  // these are the artist's own history, not a consume-once queue; the
  // flood valve above stays the write bound.
  const { ref: dest, live } = await routedTipRef(firestore, connection.uid, connection.bandId, mapped.id, now);
  const batch = firestore.batch();

  // Idempotency: the doc id IS the Stripe object id (cs_…/ch_…), and
  // create() refuses to overwrite. A Stripe retry, a re-sent event, and the
  // completed/async_payment_succeeded pair for one session all collapse
  // onto the same id — ALREADY_EXISTS is a successful no-op. (Deliveries far
  // enough apart to resolve DIFFERENT destinations are the tombstone check's
  // job above; only near-simultaneous races reach create(), and those see
  // the same destination.)
  batch.create(dest, stripeTipWire(mapped.id, mapped.tip, now));

  // The bell feed + push (notifications.ts), only when no set was running.
  // Riding THIS batch is what makes it exactly-once: when a redelivery race
  // loses to the tip's create(), the notification no-ops with it.
  recordTipNotification(firestore, connection.uid, connection.bandId, live, {
    tipId: mapped.id,
    amountMinor: mapped.tip.amountMinor,
    currency: mapped.tip.currency,
    name: mapped.tip.name,
    ...(mapped.tip.songId !== undefined ? { songId: mapped.tip.songId } : {}),
    ...(mapped.tip.songTitle !== undefined ? { songTitle: mapped.tip.songTitle } : {}),
  }, now, batch);

  // The other half of the tombstone check above: written in the SAME batch
  // as the tip, so either both land or neither. set(), not create() — when
  // two deliveries race past the check, the tip's create() is the arbiter
  // and the loser's whole batch no-ops as ALREADY_EXISTS. The sweep
  // reclaims it once Stripe cannot redeliver anymore.
  batch.set(tombstoneRef, {
    expiresAt: Timestamp.fromMillis(now + STRIPE_PROCESSED_TTL_MS),
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
