/// Minimal Stripe REST client for the functions that hold a cloud account's
/// restricted key — the server-side twin of the app's StripeClient
/// (app/lib/data/stripe/stripe_client.dart), same pinned API version so both
/// sides parse identical shapes. fetch + form encoding, no SDK: the surface
/// we use is five endpoints, and every byte that goes out is visible here.
///
/// Log hygiene: nothing in this file logs a key, a request body, or a
/// response body. Errors carry Stripe's public error fields only.

export const STRIPE_API_VERSION = "2024-06-20";
const STRIPE_BASE = "https://api.stripe.com/v1/";
const TIMEOUT_MS = 20_000;

// ---------------------------------------------------------------------------
// Key validation — pure, and the ONLY gate a key passes to reach storage.

/**
 * A restricted key and nothing else. The app already refuses `sk_` keys at
 * the paste box; the server refuses them again because the server is where
 * the promise lives: a secret key can move money (refunds, payouts,
 * transfers) and we will not custody one, however it arrives. Publishable
 * keys are refused as a paste mistake. The tail charset is Stripe's base58ish
 * alphanumeric; length bounds are generous but finite.
 */
const RESTRICTED_KEY = /^rk_(live|test)_[A-Za-z0-9]{16,247}$/;

export type KeyVerdict =
  | { ok: true; key: string; livemode: boolean }
  | { ok: false; error: string };

export function validateRestrictedKey(raw: unknown): KeyVerdict {
  if (typeof raw !== "string") return { ok: false, error: "key must be a string" };
  const key = raw.trim();
  if (key.startsWith("sk_")) {
    return { ok: false, error: "secret keys are refused — create a restricted key (rk_…) instead" };
  }
  if (key.startsWith("pk_")) {
    return { ok: false, error: "that is a publishable key — create a restricted key (rk_…) instead" };
  }
  if (!RESTRICTED_KEY.test(key)) {
    return { ok: false, error: "not a valid Stripe restricted key (rk_live_… or rk_test_…)" };
  }
  return { ok: true, key, livemode: key.startsWith("rk_live_") };
}

// ---------------------------------------------------------------------------
// Form encoding — Stripe's bracketed-key flavor. Pure, tested.

/** `{"a[b]": "c"}` → `a%5Bb%5D=c`. Callers spell the brackets themselves,
 * exactly like the app's StripeRequests does. */
export function formEncode(params: Record<string, string>): string {
  return Object.entries(params)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join("&");
}

// ---------------------------------------------------------------------------
// Errors

/** Stripe said no. Carries only Stripe's public error fields. */
export class StripeApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly code?: string,
    readonly type?: string,
    readonly param?: string,
  ) {
    super(message);
  }
  get isAuthError(): boolean {
    return this.status === 401;
  }
  get isPermissionError(): boolean {
    return this.status === 403 || this.message.includes("does not have the required permissions");
  }
}

/** The network said nothing usable (offline, timeout, DNS). */
export class StripeNetworkError extends Error {}

/** Pure: one Stripe error response body → a StripeApiError. */
export function stripeErrorFrom(status: number, body: unknown): StripeApiError {
  const error =
    typeof body === "object" && body !== null && !Array.isArray(body)
      ? ((body as Record<string, unknown>)["error"] as Record<string, unknown> | undefined) ?? {}
      : {};
  return new StripeApiError(
    status,
    typeof error["message"] === "string" ? error["message"] : `Stripe returned HTTP ${status}`,
    typeof error["code"] === "string" ? error["code"] : undefined,
    typeof error["type"] === "string" ? error["type"] : undefined,
    typeof error["param"] === "string" ? error["param"] : undefined,
  );
}

// ---------------------------------------------------------------------------
// The client

export class StripeApi {
  constructor(
    private readonly key: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  private headers(form: boolean): Record<string, string> {
    return {
      Authorization: `Bearer ${this.key}`,
      "Stripe-Version": STRIPE_API_VERSION,
      ...(form ? { "Content-Type": "application/x-www-form-urlencoded" } : {}),
    };
  }

  private async request(method: "GET" | "POST" | "DELETE", path: string, body?: string): Promise<Record<string, unknown>> {
    let res: Response;
    try {
      res = await this.fetchImpl(`${STRIPE_BASE}${path}`, {
        method,
        headers: this.headers(body !== undefined),
        body,
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
    } catch {
      throw new StripeNetworkError("request to Stripe failed");
    }
    let json: unknown = null;
    try {
      json = await res.json();
    } catch {
      // Non-JSON body: fall through to the status check below.
    }
    if (!res.ok) throw stripeErrorFrom(res.status, json);
    if (typeof json !== "object" || json === null || Array.isArray(json)) {
      throw new StripeApiError(res.status, "unexpected response from Stripe");
    }
    return json as Record<string, unknown>;
  }

  /** query values: string, or string[] for repeated keys (`types[]`). */
  get(path: string, query: Record<string, string | string[]> = {}): Promise<Record<string, unknown>> {
    const search = new URLSearchParams();
    for (const [k, v] of Object.entries(query)) {
      if (Array.isArray(v)) for (const item of v) search.append(k, item);
      else search.append(k, v);
    }
    const qs = search.toString();
    return this.request("GET", qs ? `${path}?${qs}` : path);
  }

  post(path: string, params: Record<string, string>): Promise<Record<string, unknown>> {
    return this.request("POST", path, formEncode(params));
  }

  delete(path: string): Promise<Record<string, unknown>> {
    return this.request("DELETE", path);
  }
}

// ---------------------------------------------------------------------------
// Key permission probes — the server-side mirror of the app's
// checkKeyPermissions. Read probes only; write permissions are exercised for
// real on first use (jar creation / endpoint registration), where errors
// surface with the missing permission spelled out.

export interface PermissionCheck {
  label: string;
  ok: boolean;
  detail?: string;
}

/** label + the GET that proves it. Exported so tests pin the exact set —
 * this list IS the app's onboarding checklist for cloud accounts. */
export const KEY_PROBES: readonly { label: string; path: string }[] = [
  // History, and the payload of checkout.session.* webhook events.
  { label: "Checkout Sessions — Read (see tips)", path: "checkout/sessions" },
  // The in-person tap path (charge.succeeded payloads).
  { label: "Charges — Read (in-person tap tips)", path: "charges" },
  { label: "Payment Links — Write (your tip link)", path: "payment_links" },
  { label: "Products & Prices — Write (the “Tip” item)", path: "products" },
  // NEW versus the on-device checklist: the server registers the tip feed
  // on the artist's account, so the key must be allowed to manage webhook
  // endpoints. (Events — Read is NO LONGER needed: nothing polls.)
  { label: "Webhook Endpoints — Write (live tip feed)", path: "webhook_endpoints" },
];

export async function runKeyProbes(api: StripeApi): Promise<PermissionCheck[]> {
  return Promise.all(
    KEY_PROBES.map(async ({ label, path }): Promise<PermissionCheck> => {
      try {
        await api.get(path, { limit: "1" });
        return { label, ok: true };
      } catch (e) {
        if (e instanceof StripeApiError) return { label, ok: false, detail: e.message };
        throw e; // network trouble is not a verdict on the key
      }
    }),
  );
}

/** Where one connection's events land: base + the 128-bit connectionId. */
export function webhookUrlFor(base: string, connectionId: string): string {
  return `${base.replace(/\/+$/, "")}/${connectionId}`;
}
