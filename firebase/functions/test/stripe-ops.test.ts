import { describe, expect, it } from "vitest";
import { PROXY_OPS, parseProxyRequest, sanitizeCheckoutSession } from "../src/stripe-ops";
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
    expect(PROXY_OPS).toEqual(["checkKey", "createTipJar", "updateTipJarDetails", "deactivatePaymentLink", "listTips"]);
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

  it("listTips defaults, clamps and validates its paging", () => {
    expect(parseProxyRequest("listTips", undefined)).toEqual({
      ok: true, value: { op: "listTips", startingAfter: null, limit: 25 },
    });
    expect(parseProxyRequest("listTips", { startingAfter: "cs_test_abc", limit: 100 })).toEqual({
      ok: true, value: { op: "listTips", startingAfter: "cs_test_abc", limit: 100 },
    });
    for (const limit of [0, 101, 1.5, "25", -1]) {
      expect(parseProxyRequest("listTips", { limit }).ok).toBe(false);
    }
    expect(parseProxyRequest("listTips", { startingAfter: "evt_123" }).ok).toBe(false);
    expect(parseProxyRequest("listTips", { startingAfter: "cs_../x" }).ok).toBe(false);
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
