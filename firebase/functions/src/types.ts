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
  /**
   * Set only on song-request tips. `songTitle` is resolved by the SERVER from
   * requestsConfig — never fan input — so it may be packed into deep-link
   * notes and stored without re-sanitizing.
   */
  songId?: string;
  songTitle?: string;
}

// ---------------------------------------------------------------------------
// Song requests (#64). Both structures live as JarDoc SIBLINGS of `profile`,
// never inside it: profile is wholesale-replaced by createJar/updateJarProfile
// and the app's daily seen re-push, so anything nested there would be silently
// erased within 24 hours.

/** One entry of the artist-published song library. */
export interface RequestSong {
  id: string;
  title: string;
  artist?: string;
  /** Per-song price override, in the JAR's currency; else defaultPriceMinor. */
  priceMinor?: number;
  /** Optional per-song Stripe Payment Link (same allowlist as the profile's). */
  stripeUrl?: string;
}

/** The artist's request offering — library, pricing, accepted methods. */
export interface RequestsConfig {
  enabled: boolean;
  /** In the jar's currency (requests are always priced in it). */
  defaultPriceMinor: number;
  /** Subset of ["stripe","revolut","mobilepay","monzo"]. */
  methods: string[];
  songs: RequestSong[];
}

/** Live open/queue state the app publishes while a show runs. */
export interface RequestsLive {
  /** 0 = closed; else a server-stamped now+12h deadline. */
  openUntilMs: number;
  updatedAtMs: number;
  /** Jar currency at publish time. */
  currency: string;
  /** songId → totals: t = totalMinor, c = count, s = queued/playing/skipped. */
  songs: Record<string, { t: number; c: number; s: "q" | "p" | "k" }>;
}
