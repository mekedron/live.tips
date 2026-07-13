import { describe, expect, it } from "vitest";
import {
  KEY_PROBES,
  StripeApi,
  StripeApiError,
  formEncode,
  runKeyProbes,
  stripeErrorFrom,
  validateRestrictedKey,
  webhookUrlFor,
} from "../src/stripe-api";

// Invented keys, assembled rather than written out: a literal in real key
// SHAPE trips secret scanners even when the key is fiction, and a scanner
// that gets waved through on fixtures stops protecting the real thing.
const rk = (mode: "live" | "test") =>
  `rk_${mode}_51NxyzABCDEFGHJKLMNPQRSTUVWXYZ01234`;

const RK_LIVE = rk("live");
const RK_TEST = rk("test");

describe("validateRestrictedKey", () => {
  it("accepts restricted keys and reads livemode off the prefix", () => {
    expect(validateRestrictedKey(RK_LIVE)).toEqual({ ok: true, key: RK_LIVE, livemode: true });
    expect(validateRestrictedKey(`  ${RK_TEST}  `)).toEqual({ ok: true, key: RK_TEST, livemode: false });
  });

  it("refuses secret keys with a message that says why", () => {
    for (const sk of ["sk_live_abcdefghijklmnop", "sk_test_abcdefghijklmnop"]) {
      const verdict = validateRestrictedKey(sk);
      expect(verdict.ok).toBe(false);
      if (!verdict.ok) expect(verdict.error).toMatch(/secret keys are refused/);
    }
  });

  it("refuses publishable keys as a paste mistake", () => {
    const verdict = validateRestrictedKey("pk_live_abcdefghijklmnop");
    expect(verdict.ok).toBe(false);
    if (!verdict.ok) expect(verdict.error).toMatch(/publishable/);
  });

  it("refuses everything that is not the restricted-key shape", () => {
    for (const junk of [
      undefined, null, 42, "", "rk_", "rk_live_", "rk_live_short", "rk_prod_" + "a".repeat(30),
      "rk_live_has spaces in it!", "rk_live_" + "a".repeat(300), `${RK_LIVE}\nrk_extra`,
    ]) {
      expect(validateRestrictedKey(junk).ok).toBe(false);
    }
  });
});

describe("formEncode", () => {
  it("encodes Stripe's bracketed keys and reserved characters", () => {
    expect(formEncode({ "metadata[managed_by]": "live.tips", name: "Tips — Ana & Co" })).toBe(
      "metadata%5Bmanaged_by%5D=live.tips&name=Tips%20%E2%80%94%20Ana%20%26%20Co",
    );
    expect(formEncode({})).toBe("");
  });
});

describe("stripeErrorFrom", () => {
  it("lifts Stripe's public error fields", () => {
    const e = stripeErrorFrom(403, {
      error: { message: "key does not have access", code: "permissions", type: "invalid_request_error", param: "x" },
    });
    expect(e.status).toBe(403);
    expect(e.message).toBe("key does not have access");
    expect(e.code).toBe("permissions");
    expect(e.isPermissionError).toBe(true);
    expect(e.isAuthError).toBe(false);
  });

  it("copes with junk bodies and flags 401 as an auth error", () => {
    const e = stripeErrorFrom(401, "<html>");
    expect(e.message).toMatch(/HTTP 401/);
    expect(e.isAuthError).toBe(true);
    // The permission phrasing is also recognized without a 403 status.
    expect(new StripeApiError(400, "this key does not have the required permissions").isPermissionError).toBe(true);
  });
});

describe("KEY_PROBES — the cloud onboarding checklist", () => {
  it("pins the exact permission set: 5 probes, webhooks in, events OUT", () => {
    expect(KEY_PROBES.map((p) => p.path)).toEqual([
      "checkout/sessions",
      "charges",
      "payment_links",
      "products",
      "webhook_endpoints",
    ]);
    // Nothing polls for a cloud account — the key needs no Events read.
    expect(KEY_PROBES.some((p) => p.path === "events")).toBe(false);
  });
});

describe("runKeyProbes", () => {
  /** A Stripe that grants some resources and 403s the rest. */
  function fakeStripe(allowed: string[]): StripeApi {
    return new StripeApi("rk_test_fake", (async (url: RequestInfo | URL) => {
      const path = String(url).replace("https://api.stripe.com/v1/", "").split("?")[0]!;
      if (allowed.includes(path)) {
        return new Response(JSON.stringify({ object: "list", data: [] }), { status: 200 });
      }
      return new Response(
        JSON.stringify({ error: { message: `no access to ${path}`, type: "invalid_request_error" } }),
        { status: 403 },
      );
    }) as typeof fetch);
  }

  it("passes a key that can do everything", async () => {
    const checks = await runKeyProbes(fakeStripe(KEY_PROBES.map((p) => p.path)));
    expect(checks).toHaveLength(KEY_PROBES.length);
    expect(checks.every((c) => c.ok)).toBe(true);
  });

  it("names each missing permission instead of failing vaguely", async () => {
    const checks = await runKeyProbes(fakeStripe(["checkout/sessions", "charges", "payment_links", "products"]));
    const failed = checks.filter((c) => !c.ok);
    expect(failed).toHaveLength(1);
    expect(failed[0]!.label).toMatch(/Webhook Endpoints/);
    expect(failed[0]!.detail).toMatch(/no access to webhook_endpoints/);
  });
});

describe("webhookUrlFor", () => {
  it("joins base and connectionId, tolerating trailing slashes", () => {
    expect(webhookUrlFor("https://tip.live.tips/stripe/webhook", "abc123")).toBe(
      "https://tip.live.tips/stripe/webhook/abc123",
    );
    expect(webhookUrlFor("https://tip.live.tips/stripe/webhook///", "abc123")).toBe(
      "https://tip.live.tips/stripe/webhook/abc123",
    );
  });
});
