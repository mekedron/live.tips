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

/** What the tip form submits (after validation). */
export interface TipRequest {
  method: TipMethod;
  amountMinor: number;
  name: string;
  message: string;
}
