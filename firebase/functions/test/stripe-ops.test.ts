import { describe, expect, it } from "vitest";
import {
  PROXY_OPS,
  nextPageCursor,
  parseProxyRequest,
  sanitizeCardPresentCharge,
  sanitizeCheckoutSession,
} from "../src/stripe-ops";
import { isValidBandId, isValidPaymentLinkId } from "../src/stripe-store";

describe("parseProxyRequest — the allowlist boundary", () => {
  it("rejects any operation that is not on the list — no passthrough, ever", () => {
    for (const op of [
      undefined, null, 42, "", "listEvents", "get", "POST /v1/payouts", "refunds",
      "createTipJar ", "checkkey", "webhook_endpoints",
    ]) {
      const r = parseProxyRequest(op, {});
      expect(r.ok).toBe(false);
      if (!r.ok) expect(r.error).toBe("unknown operation");
    }
    expect(PROXY_OPS).toEqual([
      "checkKey", "createTipJar", "updateTipJarDetails", "deactivatePaymentLink",
      "createSongLink", "updateSongLink", "deactivateSongLink",
      "listTips", "listTaps",
    ]);
  });

  it("rejects non-object params and unknown fields inside them", () => {
    expect(parseProxyRequest("checkKey", "params").ok).toBe(false);
    expect(parseProxyRequest("checkKey", []).ok).toBe(false);
    expect(parseProxyRequest("checkKey", { path: "payouts" }).ok).toBe(false);
    expect(parseProxyRequest("listTips", { limit: 10, expand: "everything" }).ok).toBe(false);
  });

  it("checkKey takes no params at all", () => {
    expect(parseProxyRequest("checkKey", undefined)).toEqual({ ok: true, value: { op: "checkKey" } });
    expect(parseProxyRequest("checkKey", {})).toEqual({ ok: true, value: { op: "checkKey" } });
  });

  it("createTipJar validates and scrubs its fields", () => {
    const r = parseProxyRequest("createTipJar", {
      currency: " EUR ",
      displayName: "  Ana‮ & Co  ",
      thankYouMessage: "Thank you! 🎶",
    });
    expect(r).toEqual({
      ok: true,
      value: { op: "createTipJar", currency: "eur", displayName: "Ana & Co", thankYouMessage: "Thank you! 🎶" },
    });
  });

  it("createTipJar rejects bad currency, missing/overlong text", () => {
    expect(parseProxyRequest("createTipJar", { currency: "euro", displayName: "A", thankYouMessage: "t" }).ok).toBe(false);
    expect(parseProxyRequest("createTipJar", { currency: "eur", thankYouMessage: "t" }).ok).toBe(false);
    expect(parseProxyRequest("createTipJar", { currency: "eur", displayName: "", thankYouMessage: "t" }).ok).toBe(false);
    expect(parseProxyRequest("createTipJar", { currency: "eur", displayName: "x".repeat(51), thankYouMessage: "t" }).ok).toBe(false);
    expect(parseProxyRequest("createTipJar", { currency: "eur", displayName: "A", thankYouMessage: "x".repeat(201) }).ok).toBe(false);
  });

  it("updateTipJarDetails pins its Stripe id shapes", () => {
    const good = { productId: "prod_ABC123", paymentLinkId: "plink_XYZ789", displayName: "Ana", thankYouMessage: "ty" };
    expect(parseProxyRequest("updateTipJarDetails", good).ok).toBe(true);
    expect(parseProxyRequest("updateTipJarDetails", { ...good, productId: "price_ABC" }).ok).toBe(false);
    expect(parseProxyRequest("updateTipJarDetails", { ...good, productId: "prod_../../evil" }).ok).toBe(false);
    expect(parseProxyRequest("updateTipJarDetails", { ...good, paymentLinkId: "plink_has spaces" }).ok).toBe(false);
  });

  it("deactivatePaymentLink accepts only a plink_… id", () => {
    expect(parseProxyRequest("deactivatePaymentLink", { paymentLinkId: "plink_XYZ789" })).toEqual({
      ok: true,
      value: { op: "deactivatePaymentLink", paymentLinkId: "plink_XYZ789" },
    });
    expect(parseProxyRequest("deactivatePaymentLink", { paymentLinkId: "pl_nope" }).ok).toBe(false);
    expect(parseProxyRequest("deactivatePaymentLink", {}).ok).toBe(false);
  });

  it("createSongLink validates and scrubs its fields", () => {
    const r = parseProxyRequest("createSongLink", {
      songId: "song_Abc-123",
      title: "  Wonder‮wall  ",
      priceMinor: 500,
      currency: " EUR ",
    });
    expect(r).toEqual({
      ok: true,
      value: { op: "createSongLink", songId: "song_Abc-123", title: "Wonderwall", priceMinor: 500, currency: "eur" },
    });
  });

  it("createSongLink pins the songId shape: 1-32 of A-Za-z0-9_-, nothing else", () => {
    const base = { title: "t", priceMinor: 500, currency: "eur" };
    for (const songId of ["s", "a".repeat(32), "A-b_9"]) {
      expect(parseProxyRequest("createSongLink", { ...base, songId }).ok).toBe(true);
    }
    for (const songId of [undefined, null, 42, "", "a".repeat(33), "a/b", "a b", "sång", "../evil"]) {
      expect(parseProxyRequest("createSongLink", { ...base, songId }).ok).toBe(false);
    }
  });

  it("createSongLink bounds the title at 1-60 code points, scrubbed not truncated", () => {
    const base = { songId: "s1", priceMinor: 500, currency: "eur" };
    expect(parseProxyRequest("createSongLink", { ...base, title: "x".repeat(60) }).ok).toBe(true);
    expect(parseProxyRequest("createSongLink", { ...base, title: "x".repeat(61) }).ok).toBe(false);
    expect(parseProxyRequest("createSongLink", { ...base, title: "" }).ok).toBe(false);
    expect(parseProxyRequest("createSongLink", { ...base }).ok).toBe(false);
    expect(parseProxyRequest("createSongLink", { ...base, title: 42 }).ok).toBe(false);
    // 60 EMOJI code points fit — the cap counts points, not UTF-16 units.
    expect(parseProxyRequest("createSongLink", { ...base, title: "🎸".repeat(60) }).ok).toBe(true);
  });

  it("createSongLink bounds the price: positive integer minor units, capped", () => {
    const base = { songId: "s1", title: "t", currency: "eur" };
    expect(parseProxyRequest("createSongLink", { ...base, priceMinor: 1 }).ok).toBe(true);
    expect(parseProxyRequest("createSongLink", { ...base, priceMinor: 100_000_000 }).ok).toBe(true);
    for (const priceMinor of [undefined, null, 0, -500, 1.5, "500", 100_000_001, NaN, Infinity, Number.MAX_SAFE_INTEGER + 2]) {
      expect(parseProxyRequest("createSongLink", { ...base, priceMinor }).ok).toBe(false);
    }
  });

  it("createSongLink rejects bad currency and unknown fields", () => {
    const base = { songId: "s1", title: "t", priceMinor: 500 };
    for (const currency of [undefined, "euro", "e", 42, ""]) {
      expect(parseProxyRequest("createSongLink", { ...base, currency }).ok).toBe(false);
    }
    expect(parseProxyRequest("createSongLink", { ...base, currency: "eur", thankYouMessage: "ty" }).ok).toBe(false);
  });

  it("updateSongLink renames only: productId + title, nothing about price", () => {
    expect(parseProxyRequest("updateSongLink", { productId: "prod_ABC123", title: "New Title" })).toEqual({
      ok: true,
      value: { op: "updateSongLink", productId: "prod_ABC123", title: "New Title" },
    });
    expect(parseProxyRequest("updateSongLink", { productId: "price_ABC", title: "t" }).ok).toBe(false);
    expect(parseProxyRequest("updateSongLink", { productId: "prod_../evil", title: "t" }).ok).toBe(false);
    expect(parseProxyRequest("updateSongLink", { productId: "prod_ABC123" }).ok).toBe(false);
    expect(parseProxyRequest("updateSongLink", { productId: "prod_ABC123", title: "x".repeat(61) }).ok).toBe(false);
    // Prices are immutable on Stripe — a price change is deactivate+create,
    // so this op must not even accept the field.
    expect(parseProxyRequest("updateSongLink", { productId: "prod_ABC123", title: "t", priceMinor: 900 }).ok).toBe(false);
  });

  it("deactivateSongLink accepts only a plink_… id and keeps no other fields", () => {
    expect(parseProxyRequest("deactivateSongLink", { paymentLinkId: "plink_XYZ789" })).toEqual({
      ok: true,
      value: { op: "deactivateSongLink", paymentLinkId: "plink_XYZ789" },
    });
    expect(parseProxyRequest("deactivateSongLink", { paymentLinkId: "pl_nope" }).ok).toBe(false);
    expect(parseProxyRequest("deactivateSongLink", {}).ok).toBe(false);
    expect(parseProxyRequest("deactivateSongLink", { paymentLinkId: "plink_XYZ789", songId: "s1" }).ok).toBe(false);
  });

  it("listTips defaults, clamps and validates its paging", () => {
    expect(parseProxyRequest("listTips", undefined)).toEqual({
      ok: true, value: { op: "listTips", startingAfter: null, createdAfterMs: null, limit: 25 },
    });
    expect(parseProxyRequest("listTips", { startingAfter: "cs_test_abc", limit: 100 })).toEqual({
      ok: true, value: { op: "listTips", startingAfter: "cs_test_abc", createdAfterMs: null, limit: 100 },
    });
    for (const limit of [0, 101, 1.5, "25", -1]) {
      expect(parseProxyRequest("listTips", { limit }).ok).toBe(false);
    }
    expect(parseProxyRequest("listTips", { startingAfter: "evt_123" }).ok).toBe(false);
    expect(parseProxyRequest("listTips", { startingAfter: "cs_../x" }).ok).toBe(false);
  });

  it("listTaps defaults, clamps and validates its paging", () => {
    expect(parseProxyRequest("listTaps", undefined)).toEqual({
      ok: true, value: { op: "listTaps", startingAfter: null, createdAfterMs: null, limit: 25 },
    });
    expect(parseProxyRequest("listTaps", { startingAfter: "ch_3Qtest_abc", limit: 100 })).toEqual({
      ok: true, value: { op: "listTaps", startingAfter: "ch_3Qtest_abc", createdAfterMs: null, limit: 100 },
    });
    for (const limit of [0, 101, 1.5, "25", -1]) {
      expect(parseProxyRequest("listTaps", { limit }).ok).toBe(false);
    }
    expect(parseProxyRequest("listTaps", { limit: 10, expand: "everything" }).ok).toBe(false);
    expect(parseProxyRequest("listTaps", { startingAfter: "evt_123" }).ok).toBe(false);
    expect(parseProxyRequest("listTaps", { startingAfter: "ch_../x" }).ok).toBe(false);
  });

  it("the two cursors are NOT interchangeable: taps want ch_…, tips want cs_…", () => {
    expect(parseProxyRequest("listTaps", { startingAfter: "cs_test_abc" }).ok).toBe(false);
    expect(parseProxyRequest("listTips", { startingAfter: "ch_3Qtest_abc" }).ok).toBe(false);
  });

  it("createdAfterMs is a positive integer of milliseconds, on both lists", () => {
    for (const op of ["listTips", "listTaps"] as const) {
      const r = parseProxyRequest(op, { createdAfterMs: 1_752_000_000_000 });
      expect(r).toEqual({
        ok: true, value: { op, startingAfter: null, createdAfterMs: 1_752_000_000_000, limit: 25 },
      });
      for (const bad of [0, -1, -1_752_000_000_000, 1.5, 1_752_000_000_000.25, "1752000000000", true, {}, NaN, Infinity]) {
        expect(parseProxyRequest(op, { createdAfterMs: bad }).ok).toBe(false);
      }
      // null/absent both mean "no window".
      expect(parseProxyRequest(op, { createdAfterMs: null })).toEqual({
        ok: true, value: { op, startingAfter: null, createdAfterMs: null, limit: 25 },
      });
    }
  });
});

describe("sanitizeCheckoutSession", () => {
  const session = {
    id: "cs_test_abc",
    object: "checkout.session",
    amount_total: 1500,
    currency: "eur",
    created: 1_752_000_000,
    livemode: true,
    payment_status: "paid",
    payment_intent: "pi_123",
    payment_link: {
      id: "plink_1",
      url: "https://buy.stripe.com/xyz",
      metadata: { managed_by: "live.tips", internal: "secret" },
    },
    custom_fields: [
      { key: "nickname", text: { value: "Maya" } },
      { key: "message", text: { value: "hi" } },
      { key: "vat_number", text: { value: "FI12345678" } },
    ],
    customer_details: { name: "Card Holder", email: "fan@example.com", phone: "+358401234567", address: { city: "Helsinki" } },
  };

  it("keeps exactly what Tip.fromCheckoutSession reads — and strips PII it does not", () => {
    const s = sanitizeCheckoutSession(session)!;
    expect(s).toEqual({
      id: "cs_test_abc",
      amount_total: 1500,
      currency: "eur",
      created: 1_752_000_000,
      livemode: true,
      payment_status: "paid",
      payment_intent: "pi_123",
      payment_link: { id: "plink_1", metadata: { managed_by: "live.tips" } },
      custom_fields: [
        { key: "nickname", text: { value: "Maya" } },
        { key: "message", text: { value: "hi" } },
      ],
      customer_details: { name: "Card Holder" },
    });
    expect(JSON.stringify(s)).not.toContain("fan@example.com");
    expect(JSON.stringify(s)).not.toContain("+358401234567");
  });

  it("drops unpaid sessions and junk entries entirely", () => {
    expect(sanitizeCheckoutSession({ ...session, payment_status: "unpaid" })).toBeNull();
    expect(sanitizeCheckoutSession(null)).toBeNull();
    expect(sanitizeCheckoutSession("cs_test")).toBeNull();
    expect(sanitizeCheckoutSession({ payment_status: "paid" })).toBeNull(); // no id
  });

  it("passes an unexpanded (string) payment_link through and unwraps pi objects", () => {
    const s = sanitizeCheckoutSession({ ...session, payment_link: "plink_1", payment_intent: { id: "pi_exp" } })!;
    expect(s["payment_link"]).toBe("plink_1");
    expect(s["payment_intent"]).toBe("pi_exp");
  });
});

describe("sanitizeCardPresentCharge", () => {
  // A real /v1/charges item for a tap, carrying everything a charge drags
  // along that a tip must never see: the CARDHOLDER name off the chip, a
  // receipt email, the card fingerprint, the risk block.
  const charge = {
    id: "ch_3QTapAbc123",
    object: "charge",
    amount: 500,
    currency: "eur",
    created: 1_752_000_000,
    livemode: true,
    status: "succeeded",
    paid: true,
    payment_intent: "pi_tap123",
    billing_details: {
      name: "MARJA-LIISA VIRTANEN",
      email: "cardholder@example.com",
      phone: "+358501234567",
      address: { city: "Tampere", postal_code: "33100", line1: "Hämeenkatu 1" },
    },
    receipt_email: "receipts@example.com",
    outcome: { risk_level: "normal", seller_message: "Payment complete." },
    payment_method_details: {
      type: "card_present",
      card_present: {
        brand: "visa",
        last4: "4242",
        fingerprint: "Xt5EWLLDS7FJjR1c",
        read_method: "contactless_emv",
      },
    },
  };

  it("keeps exactly what Tip.fromCardPresentCharge reads, and nothing else", () => {
    expect(sanitizeCardPresentCharge(charge)).toEqual({
      id: "ch_3QTapAbc123",
      amount: 500,
      currency: "eur",
      created: 1_752_000_000,
      livemode: true,
      status: "succeeded",
      paid: true,
      payment_intent: "pi_tap123",
      payment_method_details: { type: "card_present" },
    });
  });

  it("strips the cardholder entirely — no name, email, phone, address, receipt, fingerprint or last4 survives", () => {
    const wire = JSON.stringify(sanitizeCardPresentCharge(charge));
    for (const pii of [
      "MARJA-LIISA VIRTANEN",
      "cardholder@example.com",
      "+358501234567",
      "Tampere", "33100", "Hämeenkatu 1",
      "receipts@example.com",
      "Xt5EWLLDS7FJjR1c",
      "4242",
    ]) {
      expect(wire).not.toContain(pii);
    }
    // A tap is anonymous on stage by design: the output carries no name key
    // at all, and no billing_details block for one to hide in.
    expect(wire).not.toContain("billing_details");
    expect(wire).not.toContain('"name"');
  });

  it("rejects the card-NOT-present charge behind every QR checkout — the double-count guard", () => {
    expect(sanitizeCardPresentCharge({
      ...charge,
      payment_method_details: { type: "card", card: { brand: "visa", last4: "4242" } },
    })).toBeNull();
  });

  it("rejects failed, unpaid and junk charges", () => {
    expect(sanitizeCardPresentCharge({ ...charge, status: "failed" })).toBeNull();
    expect(sanitizeCardPresentCharge({ ...charge, status: "pending" })).toBeNull();
    expect(sanitizeCardPresentCharge({ ...charge, paid: false })).toBeNull();
    expect(sanitizeCardPresentCharge({ ...charge, id: 42 })).toBeNull();
    expect(sanitizeCardPresentCharge(null)).toBeNull();
    expect(sanitizeCardPresentCharge(undefined)).toBeNull();
    expect(sanitizeCardPresentCharge("ch_123")).toBeNull();
    expect(sanitizeCardPresentCharge([charge])).toBeNull();
    expect(sanitizeCardPresentCharge({ status: "succeeded", paid: true })).toBeNull(); // no id
  });

  it("unwraps an expanded payment_intent object to its id", () => {
    const s = sanitizeCardPresentCharge({ ...charge, payment_intent: { id: "pi_exp" } })!;
    expect(s["payment_intent"]).toBe("pi_exp");
    const none = sanitizeCardPresentCharge({ ...charge, payment_intent: null })!;
    expect(none["payment_intent"]).toBeNull();
  });
});

describe("nextPageCursor — paging survives a fully-filtered page", () => {
  it("returns the last RAW item's id for both list shapes", () => {
    expect(nextPageCursor([{ id: "ch_1" }, { id: "ch_2" }])).toBe("ch_2");
    expect(nextPageCursor([{ id: "cs_1" }, { id: "cs_2" }])).toBe("cs_2");
  });

  it("returns null on empty, junk, or foreign-shaped ids", () => {
    expect(nextPageCursor([])).toBeNull();
    expect(nextPageCursor(undefined)).toBeNull();
    expect(nextPageCursor("nope")).toBeNull();
    expect(nextPageCursor([{ id: "ch_1" }, null])).toBeNull();
    expect(nextPageCursor([{ id: "ch_1" }, { id: 42 }])).toBeNull();
    expect(nextPageCursor([{ id: "evt_123" }])).toBeNull();
  });
});

describe("id validation", () => {
  it("isValidBandId accepts the app's acc_… ids and safe doc ids only", () => {
    expect(isValidBandId("acc_m3k9zq1a2b3c")).toBe(true);
    expect(isValidBandId("legacy")).toBe(true);
    expect(isValidBandId("")).toBe(false);
    expect(isValidBandId("a/b")).toBe(false);
    expect(isValidBandId("a".repeat(65))).toBe(false);
    expect(isValidBandId(42)).toBe(false);
  });

  it("isValidPaymentLinkId pins the plink_ shape", () => {
    expect(isValidPaymentLinkId("plink_1OurTipJarLink")).toBe(true);
    expect(isValidPaymentLinkId("plink_")).toBe(false);
    expect(isValidPaymentLinkId("price_123")).toBe(false);
    expect(isValidPaymentLinkId(undefined)).toBe(false);
  });
});
