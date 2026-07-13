/// The stripeProxy allowlist — the pure logic (no Firestore, no network, so
/// all of it is unit-testable). Five named operations, each the server-side
/// twin of a method in the app's StripeRequests
/// (app/lib/data/stripe/stripe_requests.dart), each validating its own
/// inputs; an unknown operation, an unknown field, or a malformed id is
/// rejected here, before the handler ever unseals a key. Notably ABSENT:
/// the events poll — cloud accounts get tips pushed by webhook, so nothing
/// here reads /v1/events, and nothing can be bent into "forward this path".

import { isValidPaymentLinkId } from "./stripe-store";
import { scrubText, type Result } from "./validate";

export type ProxyRequest =
  | { op: "checkKey" }
  | { op: "createTipJar"; currency: string; displayName: string; thankYouMessage: string }
  | { op: "updateTipJarDetails"; productId: string; paymentLinkId: string; displayName: string; thankYouMessage: string }
  | { op: "deactivatePaymentLink"; paymentLinkId: string }
  | { op: "listTips"; startingAfter: string | null; limit: number };

export const PROXY_OPS = [
  "checkKey",
  "createTipJar",
  "updateTipJarDetails",
  "deactivatePaymentLink",
  "listTips",
] as const;

const err = (error: string): { ok: false; status: number; error: string } => ({ ok: false, status: 422, error });

const PRODUCT_ID = /^prod_[A-Za-z0-9]{1,64}$/;
const SESSION_ID = /^cs_[A-Za-z0-9_]{1,128}$/;

const DISPLAY_NAME_MAX = 50;
const THANK_YOU_MAX = 200;

/** Scrub + cap, rejecting like the tip form does (a name that does not fit
 * should say so, not be silently shortened on a screen the artist prints). */
function textParam(
  raw: unknown,
  field: string,
  maxCodePoints: number,
  required: boolean,
): Result<string> {
  if (raw === undefined || raw === null) {
    return required ? err(`${field} is required`) : { ok: true, value: "" };
  }
  if (typeof raw !== "string") return err(`${field} must be a string`);
  if (raw.length > maxCodePoints * 8) return err(`${field} is too long`);
  const clean = scrubText(raw);
  if (required && clean.length === 0) return err(`${field} is required`);
  if ([...clean].length > maxCodePoints) return err(`${field} is too long (max ${maxCodePoints} characters)`);
  return { ok: true, value: clean };
}

function unknownKeys(params: Record<string, unknown>, allowed: readonly string[]): string | null {
  for (const key of Object.keys(params)) {
    if (!allowed.includes(key)) return key;
  }
  return null;
}

/** op + params → a typed request, or a rejection. Every operation's whole
 * input contract lives here so the tests can pin it without Firestore. */
export function parseProxyRequest(op: unknown, paramsRaw: unknown): Result<ProxyRequest> {
  if (typeof op !== "string" || !(PROXY_OPS as readonly string[]).includes(op)) {
    return err("unknown operation");
  }
  if (paramsRaw !== undefined && (typeof paramsRaw !== "object" || paramsRaw === null || Array.isArray(paramsRaw))) {
    return err("params must be an object");
  }
  const params = (paramsRaw ?? {}) as Record<string, unknown>;

  switch (op as ProxyRequest["op"]) {
    case "checkKey": {
      const stray = unknownKeys(params, []);
      if (stray !== null) return err(`unknown field "${stray}" in params`);
      return { ok: true, value: { op: "checkKey" } };
    }

    case "createTipJar": {
      const stray = unknownKeys(params, ["currency", "displayName", "thankYouMessage"]);
      if (stray !== null) return err(`unknown field "${stray}" in params`);
      const currency = params["currency"];
      if (typeof currency !== "string" || !/^[a-z]{3}$/.test(currency.toLowerCase().trim())) {
        return err("currency must be a 3-letter code");
      }
      const displayName = textParam(params["displayName"], "displayName", DISPLAY_NAME_MAX, true);
      if (!displayName.ok) return displayName;
      const thankYou = textParam(params["thankYouMessage"], "thankYouMessage", THANK_YOU_MAX, true);
      if (!thankYou.ok) return thankYou;
      return {
        ok: true,
        value: {
          op: "createTipJar",
          currency: currency.toLowerCase().trim(),
          displayName: displayName.value,
          thankYouMessage: thankYou.value,
        },
      };
    }

    case "updateTipJarDetails": {
      const stray = unknownKeys(params, ["productId", "paymentLinkId", "displayName", "thankYouMessage"]);
      if (stray !== null) return err(`unknown field "${stray}" in params`);
      const productId = params["productId"];
      if (typeof productId !== "string" || !PRODUCT_ID.test(productId)) return err("productId must be a prod_… id");
      if (!isValidPaymentLinkId(params["paymentLinkId"])) return err("paymentLinkId must be a plink_… id");
      const displayName = textParam(params["displayName"], "displayName", DISPLAY_NAME_MAX, true);
      if (!displayName.ok) return displayName;
      const thankYou = textParam(params["thankYouMessage"], "thankYouMessage", THANK_YOU_MAX, true);
      if (!thankYou.ok) return thankYou;
      return {
        ok: true,
        value: {
          op: "updateTipJarDetails",
          productId,
          paymentLinkId: params["paymentLinkId"] as string,
          displayName: displayName.value,
          thankYouMessage: thankYou.value,
        },
      };
    }

    case "deactivatePaymentLink": {
      const stray = unknownKeys(params, ["paymentLinkId"]);
      if (stray !== null) return err(`unknown field "${stray}" in params`);
      if (!isValidPaymentLinkId(params["paymentLinkId"])) return err("paymentLinkId must be a plink_… id");
      return { ok: true, value: { op: "deactivatePaymentLink", paymentLinkId: params["paymentLinkId"] as string } };
    }

    case "listTips": {
      const stray = unknownKeys(params, ["startingAfter", "limit"]);
      if (stray !== null) return err(`unknown field "${stray}" in params`);
      let startingAfter: string | null = null;
      if (params["startingAfter"] !== undefined && params["startingAfter"] !== null) {
        if (typeof params["startingAfter"] !== "string" || !SESSION_ID.test(params["startingAfter"])) {
          return err("startingAfter must be a cs_… id");
        }
        startingAfter = params["startingAfter"];
      }
      let limit = 25;
      if (params["limit"] !== undefined) {
        const raw = params["limit"];
        if (typeof raw !== "number" || !Number.isSafeInteger(raw) || raw < 1 || raw > 100) {
          return err("limit must be an integer between 1 and 100");
        }
        limit = raw;
      }
      return { ok: true, value: { op: "listTips", startingAfter, limit } };
    }
  }
}

// ---------------------------------------------------------------------------
// listTips sanitization. The client gets exactly the fields its
// Tip.fromCheckoutSession reads, in Stripe's own shapes, and nothing else
// (no emails, no addresses, no payment-method detail Stripe may add later).

export function sanitizeCheckoutSession(item: unknown): Record<string, unknown> | null {
  if (typeof item !== "object" || item === null || Array.isArray(item)) return null;
  const session = item as Record<string, unknown>;
  if (typeof session["id"] !== "string") return null;
  // The app skips unpaid sessions; skipping them here keeps them off the
  // wire entirely.
  if (session["payment_status"] !== "paid") return null;

  const customFields: unknown[] = [];
  if (Array.isArray(session["custom_fields"])) {
    for (const field of session["custom_fields"]) {
      if (typeof field !== "object" || field === null) continue;
      const f = field as Record<string, unknown>;
      if (f["key"] !== "nickname" && f["key"] !== "message") continue;
      const text = f["text"];
      const value =
        typeof text === "object" && text !== null && typeof (text as Record<string, unknown>)["value"] === "string"
          ? (text as Record<string, unknown>)["value"]
          : null;
      customFields.push({ key: f["key"], text: { value } });
    }
  }

  const customer = session["customer_details"];
  const customerName =
    typeof customer === "object" && customer !== null && typeof (customer as Record<string, unknown>)["name"] === "string"
      ? (customer as Record<string, unknown>)["name"]
      : null;

  const paymentIntent = session["payment_intent"];
  const paymentIntentId =
    typeof paymentIntent === "string"
      ? paymentIntent
      : typeof paymentIntent === "object" && paymentIntent !== null && typeof (paymentIntent as Record<string, unknown>)["id"] === "string"
        ? (paymentIntent as Record<string, unknown>)["id"]
        : null;

  // Expanded by the request; pare the link to its id + the managed_by flag
  // that Tip.viaService reads.
  const link = session["payment_link"];
  let paymentLink: unknown = null;
  if (typeof link === "string") {
    paymentLink = link;
  } else if (typeof link === "object" && link !== null) {
    const l = link as Record<string, unknown>;
    const metadata = typeof l["metadata"] === "object" && l["metadata"] !== null ? (l["metadata"] as Record<string, unknown>) : {};
    paymentLink = {
      id: typeof l["id"] === "string" ? l["id"] : null,
      metadata: { managed_by: typeof metadata["managed_by"] === "string" ? metadata["managed_by"] : null },
    };
  }

  return {
    id: session["id"],
    amount_total: typeof session["amount_total"] === "number" ? session["amount_total"] : 0,
    currency: typeof session["currency"] === "string" ? session["currency"] : null,
    created: typeof session["created"] === "number" ? session["created"] : 0,
    livemode: session["livemode"] === true,
    payment_status: "paid",
    payment_intent: paymentIntentId,
    payment_link: paymentLink,
    custom_fields: customFields,
    customer_details: { name: customerName },
  };
}
