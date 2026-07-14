/// Stripe webhook events — the pure logic (no Firestore, no network, so all
/// of it is unit-testable): signature verification, and the event → tip
/// mapping that decides what is allowed to reach an artist's queue.
///
/// The mapping is a port of the app's own filter (app/lib/data/tip_source.dart
/// `_tipOf` + app/lib/domain/tip.dart) and MUST keep its two paths disjoint:
///
///  * Online (QR): a Checkout Session against the artist's OWN tip-jar
///    payment link, paid. Anything else in the account is not ours.
///  * In person (tap): a card-PRESENT Charge. The trap this guards: a
///    Checkout payment ALSO emits charge.succeeded, so accepting charges
///    without the card_present discriminator would count every QR tip twice
///    under two ids (cs_…, ch_…) that no dedupe could tie together.
///
/// Privacy invariant, stated here because the privacy policy states it too:
/// an artist may run other business through the same Stripe account, and
/// events that are not tip-jar payments (or card-present taps) are IGNORED —
/// mapped to null, never written to Firestore, never logged with contents.

import { createHmac, timingSafeEqual } from "node:crypto";
import type { RequestLinkEntry } from "./stripe-store";
import { scrubText } from "./validate";

/** The event types the webhook endpoint subscribes to — the exact set the
 * app used to poll (see StripeRequests._tipEventTypes). */
export const TIP_EVENT_TYPES = [
  "checkout.session.completed",
  "checkout.session.async_payment_succeeded",
  "charge.succeeded",
] as const;

// ---------------------------------------------------------------------------
// Signature verification — Stripe's v1 scheme, hand-rolled like every other
// credential check in this codebase: HMAC-SHA256 over `${t}.${payload}` with
// the endpoint's signing secret, compared in constant time.

/** How far a signed timestamp may sit from our clock. Stripe's own SDK
 * default (5 min); beyond it a captured request could be replayed forever. */
export const SIGNATURE_TOLERANCE_MS = 5 * 60_000;

export interface StripeSignature {
  /** Signed UNIX seconds. */
  t: number;
  /** All v1 candidates — Stripe sends several while a secret is rolled. */
  v1: string[];
}

/** `t=1712...,v1=hex[,v1=hex]` → parts, or null for anything malformed. */
export function parseStripeSignature(header: unknown): StripeSignature | null {
  if (typeof header !== "string" || header.length === 0 || header.length > 4_096) return null;
  let t: number | null = null;
  const v1: string[] = [];
  for (const part of header.split(",")) {
    const eq = part.indexOf("=");
    if (eq < 0) continue;
    const key = part.slice(0, eq).trim();
    const value = part.slice(eq + 1).trim();
    if (key === "t" && /^\d{1,12}$/.test(value)) t = Number(value);
    else if (key === "v1" && /^[0-9a-f]{64}$/.test(value)) v1.push(value);
  }
  if (t === null || v1.length === 0) return null;
  return { t, v1 };
}

/**
 * True iff the header signs exactly these payload bytes, with this secret,
 * at a timestamp within tolerance of nowMs. An unverifiable request is the
 * caller's cue to answer 400 and touch nothing.
 */
export function verifyStripeSignature(
  payload: string,
  header: unknown,
  secret: string,
  nowMs: number,
): boolean {
  if (!secret) return false; // fail closed, like a missing Turnstile secret
  const sig = parseStripeSignature(header);
  if (sig === null) return false;
  if (Math.abs(nowMs - sig.t * 1000) > SIGNATURE_TOLERANCE_MS) return false;
  const expected = createHmac("sha256", secret).update(`${sig.t}.${payload}`, "utf8").digest();
  let match = false;
  for (const candidate of sig.v1) {
    const presented = Buffer.from(candidate, "hex");
    // Same length by construction (the parser pinned 64 hex chars).
    if (timingSafeEqual(presented, expected)) match = true;
  }
  return match;
}

// ---------------------------------------------------------------------------
// Event → tip mapping

/** What the webhook writes for the artist's devices to pick up — the cloud
 * cousin of PendingTipDoc, carrying the Stripe-only fields the app's Tip
 * model wants (livemode, the in-person discriminator, the dashboard link).
 * The handler adds expiresAt; everything here is pure data. */
export interface StripeTipData {
  tsMs: number;
  method: "stripe";
  amountMinor: number;
  currency: string;
  name: string;
  message: string;
  inPerson: boolean;
  livemode: boolean;
  paymentIntentId: string | null;
  /** Present iff this is a SONG REQUEST tip — a checkout through one of the
   * connection's requestLinks. Donations and taps carry neither key (absent,
   * not null, so the Firestore doc shape is unchanged for them). */
  songId?: string;
  songTitle?: string;
}

export interface MappedTip {
  /** The Stripe OBJECT id (cs_… / ch_…) — the Firestore doc id, which is
   * what makes retries and the completed/async pair idempotent. */
  id: string;
  tip: StripeTipData;
}

/** Fan text caps, matching the relay's tip form. Stripe already accepted the
 * payment, so over-limit text is truncated, never cause to drop a paid tip. */
const NAME_MAX_POINTS = 40;
const MESSAGE_MAX_POINTS = 200;
/** Song titles get the same treatment: the map entry was validated when the
 * link was minted, but the title still crosses onto a stage, so it goes
 * through the same scrub as text a fan typed. */
const SONG_TITLE_MAX_POINTS = 60;

function fanText(raw: unknown, maxCodePoints: number): string {
  if (typeof raw !== "string" || raw.length > maxCodePoints * 8) return "";
  const clean = scrubText(raw);
  const points = [...clean];
  return points.length <= maxCodePoints ? clean : points.slice(0, maxCodePoints).join("");
}

function asObject(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

/** A settled amount must be a positive safe integer of minor units; anything
 * else marks the object malformed and the event is ignored, not clamped. */
function amountMinor(value: unknown): number | null {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0 ? value : null;
}

function currencyOf(value: unknown): string | null {
  return typeof value === "string" && /^[a-z]{3}$/i.test(value) ? value.toLowerCase() : null;
}

/** Expandable fields arrive as bare ids in webhook payloads; guard for both
 * shapes anyway, exactly like the app does. */
function idOf(value: unknown): string | null {
  if (typeof value === "string") return value;
  const obj = asObject(value);
  return obj && typeof obj["id"] === "string" ? obj["id"] : null;
}

function customField(session: Record<string, unknown>, key: string): string | null {
  const fields = session["custom_fields"];
  if (!Array.isArray(fields)) return null;
  for (const field of fields) {
    const f = asObject(field);
    if (!f || f["key"] !== key) continue;
    const text = asObject(f["text"]);
    if (text && typeof text["value"] === "string") return text["value"];
  }
  return null;
}

/**
 * Port of Tip.isCardPresentCharge: the discriminator itself
 * (`payment_method_details.type === "card_present"`), plus status/paid
 * belt-and-suspenders — charge.succeeded only fires for successful charges,
 * but a failed or unpaid object must never reach a stage even if Stripe's
 * event stream one day says otherwise.
 */
export function isCardPresentCharge(charge: Record<string, unknown>): boolean {
  const details = asObject(charge["payment_method_details"]);
  if (!details || details["type"] !== "card_present") return false;
  if (charge["status"] !== "succeeded") return false;
  return charge["paid"] === true;
}

/**
 * One verified event → the tip it represents, or null if it is not one of
 * this artist's tips (in which case the caller stores NOTHING).
 *
 * `paymentLinkId` is the tip-jar link recorded on the connection — stamped by
 * the createTipJar proxy op, or handed to stripeConnect for a pre-existing
 * jar. Null means no jar yet, so no checkout event can be ours. The
 * in-person path cannot be narrowed to a link (a tap has nothing of ours on
 * it) and rests on the documented assumption that the account is dedicated
 * to tips — same as the app's poller always has (docs/architecture.md).
 *
 * `requestLinks` is the OTHER recognizer, from the same connection doc: the
 * song-request links minted by createSongLink, keyed by plink id. A paid
 * session through one of them is a request tip carrying songId/songTitle.
 * Both matches are STRICT id lookups against links WE minted and recorded —
 * never `metadata.managed_by` alone, which would swallow any unrelated link
 * of the artist's that happened to carry (or forge) the flag.
 */
export function tipFromEvent(
  event: unknown,
  paymentLinkId: string | null,
  requestLinks: Record<string, RequestLinkEntry> = {},
): MappedTip | null {
  const evt = asObject(event);
  if (!evt || typeof evt["type"] !== "string") return null;
  const type = evt["type"];
  if (!(TIP_EVENT_TYPES as readonly string[]).includes(type)) return null;
  const object = asObject(asObject(evt["data"])?.["object"]);
  if (!object) return null;
  const id = object["id"];
  if (typeof id !== "string" || !/^[A-Za-z0-9_]{1,255}$/.test(id)) return null;

  const createdMs = typeof object["created"] === "number" && Number.isSafeInteger(object["created"]) && object["created"] > 0
    ? object["created"] * 1000
    : null;
  const amount = amountMinor(type.startsWith("checkout.session.") ? object["amount_total"] : object["amount"]);
  const currency = currencyOf(object["currency"]);
  if (createdMs === null || amount === null || currency === null) return null;

  if (type.startsWith("checkout.session.")) {
    // Ours means OUR payment link — the tip jar (a donation) or one of the
    // song-request links (a request, which is a donation plus a song). Both
    // are strict id matches; any other link is the artist's unrelated
    // business and is not stored. And paid: completed fires for async
    // payment methods before the money moves (payment_status "unpaid");
    // async_payment_succeeded re-sends the same session id once it has —
    // so gating on "paid" both drops non-payments and makes the pair
    // converge on one write.
    const link = object["payment_link"];
    const isDonation = paymentLinkId !== null && link === paymentLinkId;
    const request = !isDonation && typeof link === "string" ? requestLinks[link] : undefined;
    if (!isDonation && request === undefined) return null;
    if (object["payment_status"] !== "paid") return null;
    const customer = asObject(object["customer_details"]);
    const tip: StripeTipData = {
      tsMs: createdMs,
      method: "stripe",
      amountMinor: amount,
      currency,
      name: fanText(customField(object, "nickname") ?? customer?.["name"], NAME_MAX_POINTS),
      message: fanText(customField(object, "message"), MESSAGE_MAX_POINTS),
      inPerson: false,
      livemode: object["livemode"] === true,
      paymentIntentId: idOf(object["payment_intent"]),
    };
    if (request !== undefined) {
      // amount_total is votes × price, already multiplied by Stripe
      // (adjustable_quantity) — carried verbatim, no quantity parsing here.
      tip.songId = request.songId;
      // The title crosses onto a stage next to fan text, so it gets the
      // exact same scrub, even though it was validated when the link was
      // minted.
      tip.songTitle = fanText(request.title, SONG_TITLE_MAX_POINTS);
    }
    return { id, tip };
  }

  // charge.succeeded — the only other subscribed type. Card-present only;
  // the charge behind a QR checkout is card-NOT-present and was (or will be)
  // counted through its Checkout Session.
  if (!isCardPresentCharge(object)) return null;
  return {
    id,
    tip: {
      tsMs: createdMs,
      method: "stripe",
      amountMinor: amount,
      currency,
      // Deliberately nameless, like Tip.fromCardPresentCharge: a tap's
      // billing_details.name is the cardholder off the chip, not a name the
      // fan chose to put on a stage.
      name: "",
      message: "",
      inPerson: true,
      livemode: object["livemode"] === true,
      paymentIntentId: idOf(object["payment_intent"]),
    },
  };
}
