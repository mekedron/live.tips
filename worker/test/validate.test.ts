import { describe, expect, it } from "vitest";
import {
  amountBounds,
  escapeHtml,
  isValidJarId,
  scrubText,
  validateProfile,
  validateTip,
} from "../src/validate";
import { methodCurrency } from "../src/methods";

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

  it("requires at least one method", () => {
    expect(validateProfile({ ...baseProfile, methods: {} }).ok).toBe(false);
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
