import type { JarDO } from "./jar-do";
import type { RegistryDO } from "./registry-do";

export interface Env {
  JAR: DurableObjectNamespace<JarDO>;
  REGISTRY: DurableObjectNamespace<RegistryDO>;
  TURNSTILE_SITE_KEY: string;
  TURNSTILE_SECRET: string;
  ADMIN_TOKEN: string;
  // Beta bindings — treated as optional so tests and a binding outage
  // degrade to the Durable Object quotas instead of failing open/closed.
  CREATE_LIMITER?: RateLimit;
  TIPS_LIMITER?: RateLimit;
}

/** Everything the relay knows about an artist. Plain text only. */
export interface JarProfile {
  artistName: string;
  message: string;
  /** Lowercase ISO-4217, e.g. "eur". */
  currency: string;
  methods: {
    /** Full validated Stripe Payment Link URL (buy|donate).stripe.com only. */
    stripeUrl?: string;
    revolutUsername?: string;
    mobilepayBoxId?: string;
    monzoUsername?: string;
  };
}

export type TipMethod = "revolut" | "mobilepay" | "monzo";

/** What the donor form submits (after validation). */
export interface TipRequest {
  method: TipMethod;
  amountMinor: number;
  name: string;
  message: string;
}

/** What the artist's device receives over the WebSocket. */
export interface TipEvent {
  type: "tip";
  /**
   * Stamped once, when the tip arrives. A queued tip keeps the same id across
   * every redelivery attempt, so the app's dedupe-by-id makes replay safe.
   */
  id: string;
  ts: number;
  method: TipMethod;
  amountMinor: number;
  currency: string;
  name: string;
  message: string;
}

/** Row the admin view sees — metadata and counters, never tip content. */
export interface RegistryRow {
  jarId: string;
  artistName: string;
  methods: string;
  createdAt: number;
  lastSeenDay: number;
  tipsToday: number;
  tipsTotal: number;
}
