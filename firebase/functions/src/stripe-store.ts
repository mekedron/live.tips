/// Firestore layout for cloud Stripe connections. Four places, and the rules
/// pin each one:
///
///   stripeConnections/{connectionId}        server-only, ALWAYS. Holds the
///                                            envelope-encrypted restricted
///                                            key + webhook signing secret
///                                            (see stripe-crypto.ts). The
///                                            connectionId is 128-bit random
///                                            and doubles as the webhook
///                                            URL's routing token.
///   users/{uid}/private/stripe               server-only pointer:
///                                            { connections: {bandId: id} } —
///                                            how the callables find a band's
///                                            connection without a query.
///   users/{uid}/bands/{bandId}/stripeTips/…  the delivery queue the artist's
///                                            devices listen to — the cloud
///                                            cousin of jars/*/pendingTips,
///                                            same delivery-is-deletion
///                                            contract, doc id = the Stripe
///                                            object id (cs_…/ch_…).
///   processedEvents/{objectId}               server-only dedupe tombstones:
///                                            the tip doc above dies on
///                                            delivery, so this is the record
///                                            that still answers a Stripe
///                                            redelivery afterwards (see
///                                            stripe-webhook.ts).

import type { DocumentReference, Firestore, CollectionReference } from "firebase-admin/firestore";
import type { Envelope } from "./stripe-crypto";

// ---------------------------------------------------------------------------
// Quotas and caps

/**
 * Webhook tip writes per uid per hour, across all of the account's bands.
 * The signature is the authentication; this is the flood valve behind it —
 * a compromised artist account (or a malicious artist self-flooding their
 * own real Stripe account with micro-payments) must not be able to write
 * unbounded Firestore. 600/h is ten tips a minute sustained, several times
 * the busiest real set; over it the webhook answers 429 so Stripe RETRIES
 * later — a legitimate burst is delayed into the next bucket, never lost.
 */
export const STRIPE_TIPS_PER_UID_PER_HOUR = 600;

/** stripeProxy calls per uid per hour — History paging plus settings churn
 * is dozens; hundreds is a script. */
export const STRIPE_PROXY_PER_UID_PER_HOUR = 300;

/** stripeConnect attempts per uid per hour: connecting is a once-per-band
 * act, and each attempt costs Stripe probes + KMS + webhook churn. */
export const STRIPE_CONNECTS_PER_UID_PER_HOUR = 10;

/**
 * Queue bound per band, like MAX_PENDING on a jar: over it the oldest goes —
 * it was about to expire anyway, and unlike a relay tip a swept QR tip is
 * still recoverable through History (and a tap through the Stripe
 * dashboard). Undelivered docs also age out after PENDING_TTL_MS via the
 * same sweep as pendingTips.
 */
export const MAX_STRIPE_PENDING = 60;

/** The relay's PENDING_TTL_MS (store.ts), restated as a literal so this
 * module stays import-pure for tests: 1h is long enough for a set break,
 * short enough that the queue never becomes a second tip history (History
 * is the proxy's job). */
export const STRIPE_PENDING_TTL_MS = 60 * 60_000;

/**
 * How long a processed-event tombstone (processedEvents/{objectId}) outlives
 * its tip. Stripe delivers at-least-once and retries for up to 3 days, so an
 * event already answered 200 can arrive again long after the tip was
 * collected and its doc deleted; 4 days keeps the dedupe alive comfortably
 * past the whole retry window before the sweep reclaims the tombstone.
 */
export const STRIPE_PROCESSED_TTL_MS = 4 * 24 * 3_600_000;

/**
 * How many song-request links one connection may accumulate — a LIFETIME cap,
 * because deactivated links stay in the map (see StripeConnectionDoc.
 * requestLinks). 200 is a generous set list several times over; past it the
 * createSongLink op refuses rather than let the connection doc grow without
 * bound (it is read on every webhook delivery).
 */
export const MAX_REQUEST_LINKS = 200;

// ---------------------------------------------------------------------------
// Ids

/** Band ids as the app mints them (`acc_<base36><base36>`) — kept loose
 * enough for future shapes, tight enough to be a safe doc id and quota key. */
export function isValidBandId(id: unknown): id is string {
  return typeof id === "string" && /^[A-Za-z0-9_-]{1,64}$/.test(id);
}

/** Payment link ids, `plink_…`. */
export function isValidPaymentLinkId(id: unknown): id is string {
  return typeof id === "string" && /^plink_[A-Za-z0-9]{1,64}$/.test(id);
}

// ---------------------------------------------------------------------------
// Document shapes

/**
 * stripeConnections/{connectionId}. A Firestore dump of this document is
 * worthless by design: both secrets are envelopes whose DEKs only Cloud KMS
 * can unwrap, and only the functions' service account may ask it to.
 */
export interface StripeConnectionDoc {
  uid: string;
  bandId: string;
  /** rk_live_… / rk_test_…, sealed. */
  key: Envelope;
  livemode: boolean;
  /** The endpoint registered on the ARTIST'S account, and its whsec, sealed. */
  webhookEndpointId: string;
  webhookSecret: Envelope;
  /**
   * The tip-jar payment link whose checkout events are tips. Null until a
   * jar exists; stamped by the createTipJar proxy op (or provided to
   * stripeConnect for a pre-existing jar). Checkout events for any OTHER
   * link — the artist's unrelated business — are ignored, never stored.
   */
  paymentLinkId: string | null;
  /**
   * Song-request payment links, keyed by plink_… id — the webhook's OTHER
   * recognizer: a checkout event for a key in this map is a request tip for
   * that song (stripe-events.ts). Entries are written by the createSongLink
   * proxy op and NEVER removed, only capped (MAX_REQUEST_LINKS): a
   * deactivated link can still settle async payments started before it went
   * dark, and dropping the entry would strand those paid requests as
   * not-ours — same reasoning that keeps paymentLinkId after
   * deactivatePaymentLink.
   */
  requestLinks?: Record<string, RequestLinkEntry>;
  createdAtMs: number;
}

/** One song's request link: what the webhook needs to label the tip. */
export interface RequestLinkEntry {
  songId: string;
  title: string;
}

/** users/{uid}/private/stripe — the per-account pointer. */
export interface StripePointerDoc {
  connections?: Record<string, string>;
}

/** One queued tip: StripeTipData (stripe-events.ts) + the sweep deadline. */
export function stripeConnectionRef(firestore: Firestore, connectionId: string): DocumentReference {
  return firestore.collection("stripeConnections").doc(connectionId);
}

export function stripePointerRef(firestore: Firestore, uid: string): DocumentReference {
  return firestore.collection("users").doc(uid).collection("private").doc("stripe");
}

export function stripeTipsCol(firestore: Firestore, uid: string, bandId: string): CollectionReference {
  return firestore
    .collection("users").doc(uid)
    .collection("bands").doc(bandId)
    .collection("stripeTips");
}

/** processedEvents/{objectId} — the webhook's dedupe tombstone, keyed like
 * the tip doc by the Stripe OBJECT id (cs_…/ch_…) so the completed/
 * async_payment_succeeded pair stays collapsed even after delivery. */
export function processedEventRef(firestore: Firestore, objectId: string): DocumentReference {
  return firestore.collection("processedEvents").doc(objectId);
}
