import { describe, expect, it } from "vitest";
import {
  amountBounds,
  escapeHtml,
  isValidJarId,
  scrubText,
  validateProfile,
  validateRequestsConfig,
  validateRequestsQueue,
  validateTip,
} from "../src/validate";
import { methodCurrency } from "../src/methods";
import type { RequestsConfig } from "../src/types";

const baseProfile = {
  artistName: "Käärijä",
  message: "Thanks for the gig!",
  currency: "eur",
  methods: { revolutUsername: "mekedron" },
};

describe("escapeHtml", () => {
  it("escapes every dangerous character", () => {
    expect(escapeHtml(`<script>alert("x&y'z")</script>`)).toBe(
      "&lt;script&gt;alert(&quot;x&amp;y&#39;z&quot;)&lt;/script&gt;",
    );
  });
});

describe("scrubText", () => {
  it("strips bidi overrides and zero-width characters", () => {
    expect(scrubText("a‮b​c﻿d")).toBe("abcd");
  });
  it("replaces control characters with spaces and trims", () => {
    expect(scrubText("\x00hi\nthere\x1F")).toBe("hi there");
  });
  it("NFC-normalizes", () => {
    expect(scrubText("é")).toBe("é");
  });
});

describe("validateProfile", () => {
  it("accepts a valid profile and lowercases atoms", () => {
    const r = validateProfile({
      ...baseProfile,
      methods: {
        stripeUrl: "https://buy.stripe.com/abc123XYZ",
        revolutUsername: "@MekeDron",
        mobilepayBoxId: "A76B1E43-1958-483C-B602-DA5869F57212",
      },
    });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.value.methods.revolutUsername).toBe("mekedron");
      expect(r.value.methods.mobilepayBoxId).toBe("a76b1e43-1958-483c-b602-da5869f57212");
    }
  });

  it.each([
    "https://evil.com/abc",
    "https://buy.stripe.com/abc?x=1",
    "https://buy.stripe.com.evil.com/abc",
    "http://buy.stripe.com/abc",
    "https://buy.stripe.com/",
    "https://user@buy.stripe.com/abc",
    "https://buy.stripe.com/abc/def",
  ])("rejects non-allowlisted stripe URL %s", (stripeUrl) => {
    const r = validateProfile({ ...baseProfile, methods: { stripeUrl } });
    expect(r.ok).toBe(false);
  });

  it("accepts live and test-mode payment links", () => {
    for (const stripeUrl of [
      "https://buy.stripe.com/9AQ3cw2gO0uHeIM144",
      "https://donate.stripe.com/test_9AQ3cw2gO0uHeIM144",
      "https://buy.stripe.com/test_abc123XYZ",
    ]) {
      expect(validateProfile({ ...baseProfile, methods: { stripeUrl } }).ok).toBe(true);
    }
  });

  it("rejects free-form junk in usernames", () => {
    for (const bad of ["me kedron", "me/kedron", "<b>x</b>", "a", "x".repeat(33)]) {
      expect(validateProfile({ ...baseProfile, methods: { revolutUsername: bad } }).ok).toBe(false);
    }
  });

  it("accepts a MobilePay Box on a jar of any currency", () => {
    // The Box still collects EUR — that's methodCurrency's job, not a lock on
    // the jar. A USD jar may absolutely offer one.
    const r = validateProfile({
      ...baseProfile,
      currency: "usd",
      methods: { mobilepayBoxId: "a76b1e43-1958-483c-b602-da5869f57212" },
    });
    expect(r.ok).toBe(true);
  });

  it("accepts a Monzo handle on a GBP jar, stripping @ and casing", () => {
    const r = validateProfile({
      ...baseProfile,
      currency: "gbp",
      methods: { monzoUsername: "@Daniel" },
    });
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.value.methods.monzoUsername).toBe("daniel");
  });

  it("accepts Monzo on a jar of any currency", () => {
    const r = validateProfile({
      ...baseProfile,
      currency: "eur",
      methods: { monzoUsername: "daniel" },
    });
    expect(r.ok).toBe(true);
  });

  it("lets one jar offer Revolut, MobilePay and Monzo together", () => {
    // The whole point of unlocking the currency: three methods, three
    // currencies, one QR code.
    const r = validateProfile({
      ...baseProfile,
      currency: "eur",
      methods: {
        revolutUsername: "mekedron",
        mobilepayBoxId: "a76b1e43-1958-483c-b602-da5869f57212",
        monzoUsername: "daniel",
      },
    });
    expect(r.ok).toBe(true);
  });

  it("rejects Monzo handles that could escape the URL path", () => {
    for (const monzoUsername of ["dan/../evil", "dan iel", "", "dan?d=x", "-dan"]) {
      expect(validateProfile({ ...baseProfile, currency: "gbp", methods: { monzoUsername } }).ok).toBe(false);
    }
  });

  it("rejects unknown keys at both levels", () => {
    expect(validateProfile({ ...baseProfile, evil: 1 }).ok).toBe(false);
    expect(
      validateProfile({ ...baseProfile, methods: { revolutUsername: "mekedron", url: "https://x" } }).ok,
    ).toBe(false);
  });

  it("rejects over-limit names instead of truncating", () => {
    expect(validateProfile({ ...baseProfile, artistName: "x".repeat(51) }).ok).toBe(false);
  });

  it("counts artistName in CODE POINTS, not grapheme clusters — the unit the app's clamp must mirror", () => {
    // 25 flag emoji: 25 graphemes but exactly 50 code points and 200 UTF-8
    // bytes — the largest output the client's clamp may produce, sitting
    // exactly on both caps.
    expect(validateProfile({ ...baseProfile, artistName: "🇫🇮".repeat(25) }).ok).toBe(true);
    // One more flag is still only 26 graphemes, but 52 code points: refused.
    // A client clamping by grapheme believed this was safe (issue #20).
    expect(validateProfile({ ...baseProfile, artistName: "🇫🇮".repeat(26) }).ok).toBe(false);
  });

  it("scrubs ZWJ before counting, so a family emoji counts its people only", () => {
    // 👨‍👩‍👧‍👦 is 7 raw code points but 4 after the invisibles scrub strips its
    // three joiners: 12 families = 48 code points, under the 50 cap. A client
    // counting raw code points over-clamps here — the safe direction.
    expect(validateProfile({ ...baseProfile, artistName: "👨‍👩‍👧‍👦".repeat(12) }).ok).toBe(true);
    expect(validateProfile({ ...baseProfile, artistName: "👨‍👩‍👧‍👦".repeat(13) }).ok).toBe(false);
  });

  it("pins the message caps: 200 code points, 800 bytes", () => {
    // One guitar is 1 code point / 4 UTF-8 bytes: 200 of them sit exactly on
    // both caps at once (the byte cap is 4× the code-point cap everywhere).
    expect(validateProfile({ ...baseProfile, message: "🎸".repeat(200) }).ok).toBe(true);
    expect(validateProfile({ ...baseProfile, message: "🎸".repeat(201) }).ok).toBe(false);
  });

  it("requires at least one method", () => {
    expect(validateProfile({ ...baseProfile, methods: {} }).ok).toBe(false);
  });
});

describe("validateRequestsConfig", () => {
  const song = (over: Record<string, unknown> = {}) => ({ id: "s1", title: "Wonderwall", ...over });
  const base = {
    enabled: true,
    defaultPriceMinor: 300,
    methods: ["stripe", "revolut"],
    songs: [song()],
  };

  it("accepts a valid config", () => {
    const r = validateRequestsConfig({ ...base }, "eur");
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.value.songs[0]).toEqual({ id: "s1", title: "Wonderwall" });
      expect(r.value.methods).toEqual(["stripe", "revolut"]);
    }
  });

  it("keeps per-song artist, price override and stripe link", () => {
    const r = validateRequestsConfig({
      ...base,
      songs: [song({ artist: "Oasis", priceMinor: 500, stripeUrl: "https://buy.stripe.com/abc123" })],
    }, "eur");
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.value.songs[0]).toEqual({
        id: "s1", title: "Wonderwall", artist: "Oasis", priceMinor: 500,
        stripeUrl: "https://buy.stripe.com/abc123",
      });
    }
  });

  it("rejects unknown keys at both levels", () => {
    expect(validateRequestsConfig({ ...base, evil: 1 }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, songs: [song({ url: "https://x" })] }, "eur").ok).toBe(false);
  });

  it("caps the library at 100 songs", () => {
    const many = (n: number) => Array.from({ length: n }, (_, i) => song({ id: `s${i}` }));
    expect(validateRequestsConfig({ ...base, songs: many(100) }, "eur").ok).toBe(true);
    expect(validateRequestsConfig({ ...base, songs: many(101) }, "eur").ok).toBe(false);
  });

  it("rejects bad song ids and duplicates", () => {
    for (const id of ["", "a b", "x".repeat(33), "s/1", "ä"]) {
      expect(validateRequestsConfig({ ...base, songs: [song({ id })] }, "eur").ok).toBe(false);
    }
    expect(validateRequestsConfig({ ...base, songs: [song(), song()] }, "eur").ok).toBe(false);
  });

  it("caps titles at 60 code points and requires one", () => {
    expect(validateRequestsConfig({ ...base, songs: [song({ title: "x".repeat(60) })] }, "eur").ok).toBe(true);
    expect(validateRequestsConfig({ ...base, songs: [song({ title: "x".repeat(61) })] }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, songs: [song({ title: "" })] }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, songs: [song({ artist: "x".repeat(61) })] }, "eur").ok).toBe(false);
  });

  it("bounds prices against the JAR currency", () => {
    expect(validateRequestsConfig({ ...base, defaultPriceMinor: 99 }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, defaultPriceMinor: 1_000_001 }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, defaultPriceMinor: 3.5 }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, songs: [song({ priceMinor: 99 })] }, "eur").ok).toBe(false);
    // JPY is zero-decimal: 99 is a fine price there.
    expect(validateRequestsConfig({ ...base, defaultPriceMinor: 99, songs: [song({ priceMinor: 99 })] }, "jpy").ok).toBe(true);
  });

  it("routes stripeUrl through the payment-link allowlist", () => {
    for (const stripeUrl of ["https://evil.com/x", "https://buy.stripe.com/a/b", "http://buy.stripe.com/x"]) {
      expect(validateRequestsConfig({ ...base, songs: [song({ stripeUrl })] }, "eur").ok).toBe(false);
    }
  });

  it("requires at least one song and a real price when enabled", () => {
    expect(validateRequestsConfig({ ...base, songs: [] }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, defaultPriceMinor: 0 }, "eur").ok).toBe(false);
    // Disabled configs may park an empty library and a 0 default.
    expect(validateRequestsConfig({ ...base, enabled: false, defaultPriceMinor: 0, songs: [] }, "eur").ok).toBe(true);
  });

  it("rejects methods outside the fixed set, and repeats", () => {
    expect(validateRequestsConfig({ ...base, methods: ["paypal"] }, "eur").ok).toBe(false);
    expect(validateRequestsConfig({ ...base, methods: ["revolut", "revolut"] }, "eur").ok).toBe(false);
  });
});

describe("validateRequestsQueue", () => {
  it("accepts live totals and rejects out-of-range or junk entries", () => {
    const r = validateRequestsQueue({ s1: { t: 900, c: 3, s: "q" }, s2: { t: 0, c: 0, s: "k" } });
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.value["s1"]).toEqual({ t: 900, c: 3, s: "q" });

    expect(validateRequestsQueue({ "bad id": { t: 0, c: 0, s: "q" } }).ok).toBe(false);
    expect(validateRequestsQueue({ s1: { t: -1, c: 0, s: "q" } }).ok).toBe(false);
    expect(validateRequestsQueue({ s1: { t: 100_000_001, c: 0, s: "q" } }).ok).toBe(false);
    expect(validateRequestsQueue({ s1: { t: 0, c: 10_001, s: "q" } }).ok).toBe(false);
    expect(validateRequestsQueue({ s1: { t: 0, c: 0, s: "x" } }).ok).toBe(false);
    expect(validateRequestsQueue({ s1: { t: 0, c: 0, s: "q", extra: 1 } }).ok).toBe(false);
  });

  it("caps the queue at 150 entries", () => {
    const entries = (n: number) =>
      Object.fromEntries(Array.from({ length: n }, (_, i) => [`s${i}`, { t: 0, c: 0, s: "q" }]));
    expect(validateRequestsQueue(entries(150)).ok).toBe(true);
    expect(validateRequestsQueue(entries(151)).ok).toBe(false);
  });
});

describe("validateTip", () => {
  const tip = {
    method: "revolut",
    amountMinor: 500,
    name: "Ada",
    message: "great show",
    turnstileToken: "tok",
  };

  it("accepts a valid tip", () => {
    expect(validateTip({ ...tip }, "eur").ok).toBe(true);
  });

  it("rejects a colon in the name", () => {
    const r = validateTip({ ...tip, name: "Ada: hi" }, "eur");
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.status).toBe(422);
  });

  it("enforces currency-aware amount bounds", () => {
    expect(validateTip({ ...tip, amountMinor: 99 }, "eur").ok).toBe(false);
    expect(validateTip({ ...tip, amountMinor: 1_000_001 }, "eur").ok).toBe(false);
    expect(validateTip({ ...tip, amountMinor: 5.5 }, "eur").ok).toBe(false);
    expect(validateTip({ ...tip, amountMinor: 50 }, "jpy").ok).toBe(true);
    expect(amountBounds("jpy")).toEqual({ min: 1, max: 10_000 });
  });

  it("bounds the amount by the METHOD's currency, not the jar's", () => {
    // A JPY jar is zero-decimal: ¥50 is a valid Revolut tip there. But a
    // MobilePay Box collects EUR, so the same 50 means €0.50 — under the €1
    // floor — and must be refused. Bounding by the jar would have let it in.
    expect(validateTip({ ...tip, method: "revolut", amountMinor: 50 }, "jpy").ok).toBe(true);
    expect(validateTip({ ...tip, method: "mobilepay", amountMinor: 50 }, "jpy").ok).toBe(false);
    expect(validateTip({ ...tip, method: "mobilepay", amountMinor: 500 }, "jpy").ok).toBe(true);
    // Monzo is GBP (two-decimal) on a JPY jar for the same reason.
    expect(validateTip({ ...tip, method: "monzo", amountMinor: 50 }, "jpy").ok).toBe(false);
    expect(validateTip({ ...tip, method: "monzo", amountMinor: 750 }, "jpy").ok).toBe(true);
  });

  it("requires a turnstile token and rejects unknown fields", () => {
    expect(validateTip({ ...tip, turnstileToken: "" }, "eur").ok).toBe(false);
    expect(validateTip({ ...tip, extra: true }, "eur").ok).toBe(false);
  });

  it("rejects votes on a plain tip", () => {
    expect(validateTip({ ...tip, votes: 2 }, "eur").ok).toBe(false);
  });
});

describe("validateTip: song requests", () => {
  const config: RequestsConfig = {
    enabled: true,
    defaultPriceMinor: 300,
    methods: ["stripe", "revolut", "mobilepay", "monzo"],
    songs: [
      { id: "s1", title: "Wonderwall" },
      { id: "s2", title: "Hallelujah", priceMinor: 500 },
    ],
  };
  const req = { method: "revolut", songId: "s1", name: "Ada", message: "", turnstileToken: "tok" };

  it("prices the request server-side: (priceMinor ?? default) × votes", () => {
    const r = validateTip({ ...req }, "eur", config);
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.value.amountMinor).toBe(300); // default price, votes default 1
      expect(r.value.songId).toBe("s1");
      expect(r.value.songTitle).toBe("Wonderwall");
    }
    const o = validateTip({ ...req, songId: "s2", votes: 3 }, "eur", config);
    expect(o.ok).toBe(true);
    // The per-song override wins over the default.
    if (o.ok) expect(o.value.amountMinor).toBe(1500);
  });

  it("refuses a fan-sent amount alongside songId", () => {
    const r = validateTip({ ...req, amountMinor: 100 }, "eur", config);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.status).toBe(422);
  });

  it("bounds votes at 1–50, integers only", () => {
    expect(validateTip({ ...req, votes: 0 }, "eur", config).ok).toBe(false);
    expect(validateTip({ ...req, votes: 51 }, "eur", config).ok).toBe(false);
    expect(validateTip({ ...req, votes: 1.5 }, "eur", config).ok).toBe(false);
    expect(validateTip({ ...req, votes: 50 }, "eur", config).ok).toBe(true); // 300×50 = €150, in bounds
  });

  it("rejects a computed amount outside the currency bounds", () => {
    // 25 000 × 50 votes = 1 250 000 minor — over the €10 000 ceiling.
    const pricey: RequestsConfig = { ...config, songs: [{ id: "s1", title: "W", priceMinor: 25_000 }] };
    expect(validateTip({ ...req, votes: 50 }, "eur", pricey).ok).toBe(false);
    expect(validateTip({ ...req, votes: 40 }, "eur", pricey).ok).toBe(true);
  });

  it("rejects unknown songs, malformed ids and a missing config", () => {
    expect(validateTip({ ...req, songId: "nope" }, "eur", config).ok).toBe(false);
    expect(validateTip({ ...req, songId: "../x" }, "eur", config).ok).toBe(false);
    expect(validateTip({ ...req }, "eur", undefined).ok).toBe(false);
  });

  it("only sells through methods the artist listed", () => {
    const revolutOnly: RequestsConfig = { ...config, methods: ["revolut"] };
    expect(validateTip({ ...req, method: "mobilepay" }, "eur", revolutOnly).ok).toBe(false);
    expect(validateTip({ ...req }, "eur", revolutOnly).ok).toBe(true);
  });

  it("refuses methods that collect a different currency than the jar's", () => {
    // Requests are priced in the jar's currency. Monzo collects GBP, so on a
    // EUR jar the same number would bill the fan in the wrong currency.
    expect(validateTip({ ...req, method: "monzo" }, "eur", config).ok).toBe(false);
    expect(validateTip({ ...req, method: "monzo" }, "gbp", config).ok).toBe(true);
    // MobilePay collects EUR: fine on a EUR jar, refused on a GBP one.
    expect(validateTip({ ...req, method: "mobilepay" }, "eur", config).ok).toBe(true);
    expect(validateTip({ ...req, method: "mobilepay" }, "gbp", config).ok).toBe(false);
  });
});

describe("methodCurrency", () => {
  it("pins the fixed-currency methods and passes the jar's through otherwise", () => {
    expect(methodCurrency("mobilepay", "usd")).toBe("eur");
    expect(methodCurrency("monzo", "usd")).toBe("gbp");
    expect(methodCurrency("revolut", "usd")).toBe("usd");
  });
});

describe("isValidJarId", () => {
  it("accepts generated-shape ids and rejects junk", () => {
    expect(isValidJarId("abcdefghjkmnpqrstvwxyz0123")).toBe(true);
    expect(isValidJarId("short")).toBe(false);
    expect(isValidJarId("UPPERCASE0000000000000000")).toBe(false);
    expect(isValidJarId("../../../etc/passwd")).toBe(false);
  });
});
