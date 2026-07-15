/// Where a cloud account's fan tip lands (#71) — the ONE destination router
/// shared by the relay POST (tip.ts) and the Stripe webhook
/// (stripe-webhook.ts), so both money paths can never disagree about what
/// "a set is running" means.
///
/// A routed tip is written straight into the account's own collections:
///
///   * a set is running for the tip's band →
///       users/{uid}/bands/{bandId}/sessions/{sessionId}/tips/{tipId}
///     — the same subcollection every device already ingests from, in the
///     exact wire shape the leader's own _publish writes
///     (app/lib/state/cloud_session_coordinator.dart);
///   * otherwise →
///       users/{uid}/bands/{bandId}/relayTips/{tipId}
///     — the band's durable archive, the shape appendRelayHistory writes
///     (app/lib/data/repository/firestore_repository.dart). This is the
///     durability win: a tip that arrives while every device of the artist
///     is offline waits in History at the next launch instead of being
///     swept unseen.
///
/// Neither destination has a cap or a TTL. The old queues (pendingTips,
/// stripeTips) were consume-once relays whose 60-doc cap and 1-hour sweep
/// were a privacy promise for an UNAUTHENTICATED jar surface; these
/// collections are the artist's own tip history inside their own account,
/// which the app has archived without bound since the cloud mirrors landed.
/// Arrival is still bounded upstream — the per-jar rate transaction for
/// relay tips, the per-uid flood valve for Stripe tips.

import type { DocumentReference, Firestore } from "firebase-admin/firestore";
import type { StripeTipData } from "./stripe-events";

/**
 * How long past its lease a leader may stay silent before the session stops
 * counting as running — the server-side twin of the app's ONE definition of
 * liveness, CloudSessionCoordinator.staleMs / leaseAlive
 * (app/lib/state/cloud_session_coordinator.dart). `active: true` alone is a
 * lie a crashed tab leaves behind (only a clean stop clears it); the lease
 * is what actually decays. Change one, change both.
 */
export const SESSION_LEASE_STALE_MS = 2 * 60_000;

/** users/{uid}/live/current — written by the app's claim transaction. */
export function liveCurrentRef(firestore: Firestore, uid: string): DocumentReference {
  return firestore.collection("users").doc(uid).collection("live").doc("current");
}

export function sessionTipRef(
  firestore: Firestore,
  uid: string,
  bandId: string,
  sessionId: string,
  tipId: string,
): DocumentReference {
  return firestore
    .collection("users").doc(uid)
    .collection("bands").doc(bandId)
    .collection("sessions").doc(sessionId)
    .collection("tips").doc(tipId);
}

export function relayTipRef(
  firestore: Firestore,
  uid: string,
  bandId: string,
  tipId: string,
): DocumentReference {
  return firestore
    .collection("users").doc(uid)
    .collection("bands").doc(bandId)
    .collection("relayTips").doc(tipId);
}

/**
 * The sessionId of a set that is running for THIS band, or null. Pure — the
 * whole routing decision in one testable place. Everything on the doc is
 * treated as app-written but type-checked anyway (a malformed doc routes to
 * the archive, never throws a tip away):
 *
 *  * `active === true` — a cleanly stopped session must not capture tips
 *    into a finished set's page;
 *  * the lease is alive per [SESSION_LEASE_STALE_MS] — the app's own
 *    leaseAlive, so a crashed leader's session keeps receiving tips through
 *    the whole takeover window and an abandoned one decays on schedule;
 *  * `bandId` matches — a live set for ANOTHER band of the same account
 *    does not capture this jar's tips.
 */
export function liveSessionId(
  live: Record<string, unknown> | undefined,
  bandId: string,
  nowMs: number,
): string | null {
  if (live === undefined) return null;
  if (live["active"] !== true) return null;
  if (live["bandId"] !== bandId) return null;
  const sessionId = live["sessionId"];
  if (typeof sessionId !== "string" || sessionId.length === 0) return null;
  const leaseUntil = live["leaderLeaseUntilMs"];
  if (typeof leaseUntil !== "number" || leaseUntil <= nowMs - SESSION_LEASE_STALE_MS) return null;
  return sessionId;
}

/**
 * Resolve where a routed tip for users/{uid}/bands/{bandId} lands right now:
 * one read of live/current, then [liveSessionId] decides. The write itself
 * stays with the caller — the relay POST set()s (fresh uuid ids cannot
 * collide), the webhook create()s inside its tombstone batch (the Stripe
 * object id is the idempotency key).
 */
export async function routedTipRef(
  firestore: Firestore,
  uid: string,
  bandId: string,
  tipId: string,
  nowMs: number,
): Promise<{ ref: DocumentReference; live: boolean }> {
  const snap = await liveCurrentRef(firestore, uid).get();
  const sessionId = liveSessionId(snap.data() as Record<string, unknown> | undefined, bandId, nowMs);
  return sessionId !== null
    ? { ref: sessionTipRef(firestore, uid, bandId, sessionId, tipId), live: true }
    : { ref: relayTipRef(firestore, uid, bandId, tipId), live: false };
}

// ---------------------------------------------------------------------------
// Wire shapes. Both destinations speak the app's Tip.toJson format
// (app/lib/domain/tip.dart) plus the `updatedAtMs` the app writes alongside —
// decoded by Tip.fromJson on every device, ordered by `createdAt`. The
// builders below REPLICATE that serializer, omit-when-default semantics
// included, so a server-written doc is byte-identical to what the leader
// would have published for the same tip. Any drift here is a wire break.

/** What the relay POST knows about an accepted tip (tip.ts). */
export interface RelayTipInput {
  /** `relay_<uuid>` — Tip.relayTip's id scheme; doubles as the doc id. */
  id: string;
  tsMs: number;
  /** Wire value, e.g. "revolut" — never "stripe" on this path. */
  method: string;
  amountMinor: number;
  /** The currency the fan actually paid in (methodCurrency), like the queue. */
  currency: string;
  /** Possibly empty — the tip form's cleaned strings. Empty means absent on
   * the wire: the app's channel decode maps '' to null, and Tip.toJson drops
   * null keys. */
  name: string;
  message: string;
  /** Set together on song-request tips (#64); absent keys otherwise. */
  songId?: string;
  songTitle?: string;
}

/**
 * A relay tip as Tip.relayTip(...).toJson() serializes it: livemode/viaService
 * true, `method` always written (relay methods are never the stripe default),
 * `verified: false` always written (fan-declared money is unverified — the
 * mark-verified flow stays app-owned, #68).
 */
export function relayTipWire(tip: RelayTipInput, updatedAtMs: number): Record<string, unknown> {
  return {
    id: tip.id,
    amountMinor: tip.amountMinor,
    currency: tip.currency,
    createdAt: tip.tsMs,
    ...(tip.name !== "" ? { name: tip.name } : {}),
    ...(tip.message !== "" ? { message: tip.message } : {}),
    livemode: true,
    viaService: true,
    method: tip.method,
    verified: false,
    ...(tip.songId !== undefined && tip.songTitle !== undefined
      ? { songId: tip.songId, songTitle: tip.songTitle }
      : {}),
    updatedAtMs,
  };
}

/**
 * A Stripe tip as the app's own Tip.fromCheckoutSession /
 * Tip.fromCardPresentCharge would round-trip through toJson(): `method` and
 * `verified` are OMITTED (stripe and true are Tip's defaults — Stripe money
 * arrives verified), `inPerson` written only when true, `paymentIntentId`
 * when known. `id` is the Stripe object id (cs_… / ch_…) and must equal the
 * doc id.
 */
export function stripeTipWire(id: string, tip: StripeTipData, updatedAtMs: number): Record<string, unknown> {
  return {
    id,
    amountMinor: tip.amountMinor,
    currency: tip.currency,
    createdAt: tip.tsMs,
    ...(tip.name !== "" ? { name: tip.name } : {}),
    ...(tip.message !== "" ? { message: tip.message } : {}),
    livemode: tip.livemode,
    viaService: true,
    ...(tip.paymentIntentId !== null ? { paymentIntentId: tip.paymentIntentId } : {}),
    ...(tip.inPerson ? { inPerson: true } : {}),
    ...(tip.songId !== undefined ? { songId: tip.songId } : {}),
    ...(tip.songTitle !== undefined && tip.songTitle !== "" ? { songTitle: tip.songTitle } : {}),
    updatedAtMs,
  };
}
