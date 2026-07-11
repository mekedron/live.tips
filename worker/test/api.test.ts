/// End-to-end route tests through SELF. Turnstile's siteverify is mocked with
/// fetchMock so tests run offline and deterministically.

import { SELF, fetchMock } from "cloudflare:test";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { createJar, uniqueIp } from "./helpers";

beforeAll(() => {
  fetchMock.activate();
  fetchMock.disableNetConnect();
});
afterEach(() => fetchMock.assertNoPendingInterceptors());

function mockTurnstile(success = true, times = 1) {
  fetchMock
    .get("https://challenges.cloudflare.com")
    .intercept({ path: "/turnstile/v0/siteverify", method: "POST" })
    .reply(200, { success })
    .times(times);
}

describe("plumbing", () => {
  it("healthz responds", async () => {
    const res = await SELF.fetch("https://api.live.tips/healthz");
    expect(res.status).toBe(200);
    expect(await res.text()).toBe("ok");
  });

  it("robots.txt disallows everything", async () => {
    const res = await SELF.fetch("https://api.live.tips/robots.txt");
    expect(await res.text()).toContain("Disallow: /");
  });
});

describe("jar lifecycle", () => {
  it("creates a jar and returns one-time credentials", async () => {
    const { jarId, secret, donateUrl } = await createJar();
    expect(jarId).toMatch(/^[0-9a-z]{26}$/);
    expect(secret).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(donateUrl).toBe(`https://live.tips/t/${jarId}`);
  });

  it("rejects invalid profiles with 422", async () => {
    const res = await SELF.fetch("https://api.live.tips/v1/jars", {
      method: "POST",
      headers: { "content-type": "application/json", "CF-Connecting-IP": uniqueIp() },
      body: JSON.stringify({ artistName: "Ada", currency: "eur", methods: { stripeUrl: "https://evil.com/x" } }),
    });
    expect(res.status).toBe(422);
  });

  it("updates with the right secret, rejects the wrong one", async () => {
    const { jarId, secret } = await createJar();
    const put = (bearer: string) =>
      SELF.fetch(`https://api.live.tips/v1/jars/${jarId}`, {
        method: "PUT",
        headers: { "content-type": "application/json", Authorization: `Bearer ${bearer}` },
        body: JSON.stringify({ artistName: "Ada L.", message: "", currency: "eur", methods: { revolutUsername: "mekedron" } }),
      });
    expect((await put("wrong-secret")).status).toBe(401);
    expect((await put(secret)).status).toBe(200);
  });

  it("seen requires auth and succeeds", async () => {
    const { jarId, secret } = await createJar();
    const seen = (bearer: string) =>
      SELF.fetch(`https://api.live.tips/v1/jars/${jarId}/seen`, {
        method: "POST",
        headers: { Authorization: `Bearer ${bearer}` },
      });
    expect((await seen("nope")).status).toBe(401);
    expect((await seen(secret)).status).toBe(204);
  });

  it("rotate-secret invalidates the old secret", async () => {
    const { jarId, secret } = await createJar();
    const res = await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}/rotate-secret`, {
      method: "POST",
      headers: { Authorization: `Bearer ${secret}` },
    });
    expect(res.status).toBe(200);
    const { secret: fresh } = await res.json<{ secret: string }>();
    const oldSeen = await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}/seen`, {
      method: "POST",
      headers: { Authorization: `Bearer ${secret}` },
    });
    expect(oldSeen.status).toBe(401);
    const newSeen = await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}/seen`, {
      method: "POST",
      headers: { Authorization: `Bearer ${fresh}` },
    });
    expect(newSeen.status).toBe(204);
  });

  it("deletes a jar; its donor page becomes the uniform 404", async () => {
    const { jarId, secret } = await createJar();
    const del = await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${secret}` },
    });
    expect(del.status).toBe(204);
    const page = await SELF.fetch(`https://live.tips/t/${jarId}`);
    expect(page.status).toBe(404);
    expect(await page.text()).toContain("isn't active");
  });
});

describe("donor page", () => {
  it("renders configured methods with strict headers", async () => {
    const { jarId } = await createJar();
    const res = await SELF.fetch(`https://live.tips/t/${jarId}`);
    expect(res.status).toBe(200);
    const csp = res.headers.get("Content-Security-Policy") ?? "";
    expect(csp).toContain("default-src 'none'");
    expect(csp).toMatch(/script-src 'sha256-[A-Za-z0-9+/=]+' https:\/\/challenges\.cloudflare\.com/);
    expect(res.headers.get("Cache-Control")).toBe("no-store");
    expect(res.headers.get("X-Robots-Tag")).toBe("noindex");
    const html = await res.text();
    expect(html).toContain("Ada Lovelace");
    expect(html).toContain("https://donate.stripe.com/testCode123");
    expect(html).toContain('data-method="revolut"');
    expect(html).toContain('data-method="mobilepay"');
  });

  it("offers Monzo as a button and a no-JS fallback link", async () => {
    const { jarId } = await createJar({
      currency: "gbp",
      methods: { monzoUsername: "daniel" },
    });
    const html = await (await SELF.fetch(`https://live.tips/t/${jarId}`)).text();
    expect(html).toContain('data-method="monzo"');
    // The <noscript>/error fallback: a bare profile link, no prefilled amount.
    expect(html).toContain('href="https://monzo.me/daniel"');
    expect(html).toContain("Amount (GBP)");
  });

  it("escapes hostile artist names — the stored-XSS gate", async () => {
    const { jarId } = await createJar({ artistName: `<script>alert("pwn")</script>` });
    const html = await (await SELF.fetch(`https://live.tips/t/${jarId}`)).text();
    expect(html).not.toContain(`<script>alert`);
    expect(html).toContain("&lt;script&gt;alert");
  });

  it("serves the uniform not-found page for unknown and malformed ids alike", async () => {
    const unknown = await SELF.fetch("https://live.tips/t/abcdefghjkmnpqrstvwxyz0123");
    const malformed = await SELF.fetch("https://live.tips/t/%3Cscript%3E");
    expect(unknown.status).toBe(404);
    expect(malformed.status).toBe(404);
    expect(await unknown.text()).toContain("isn't active");
    expect(await malformed.text()).toContain("isn't active");
  });
});

describe("tips endpoint", () => {
  function postTip(jarId: string, body: Record<string, unknown>, ip = uniqueIp()) {
    return SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
      method: "POST",
      headers: { "content-type": "application/json", "CF-Connecting-IP": ip, Origin: "https://live.tips" },
      body: JSON.stringify({
        method: "revolut",
        amountMinor: 500,
        name: "Grace",
        message: "encore!",
        turnstileToken: "test-token",
        ...body,
      }),
    });
  }

  it("relays a valid tip and returns the composed redirect", async () => {
    const { jarId } = await createJar();
    mockTurnstile();
    const res = await postTip(jarId, {});
    expect(res.status).toBe(200);
    const data = await res.json<{ redirectUrl: string; delivered: boolean; queued: boolean }>();
    const url = new URL(data.redirectUrl);
    expect(url.origin).toBe("https://revolut.me");
    expect(url.searchParams.get("note")).toBe("Grace: encore!");
    expect(data.delivered).toBe(false); // nobody connected…
    expect(data.queued).toBe(true); // …so it waits for them
  });

  it("relays a Monzo tip to a major-unit monzo.me link", async () => {
    const { jarId } = await createJar({
      currency: "gbp",
      methods: { monzoUsername: "daniel" },
    });
    mockTurnstile();
    const res = await postTip(jarId, { method: "monzo", amountMinor: 750 });
    expect(res.status).toBe(200);
    const data = await res.json<{ redirectUrl: string }>();
    const url = new URL(data.redirectUrl);
    expect(url.origin).toBe("https://monzo.me");
    expect(url.pathname).toBe("/daniel/7.50"); // £7.50, not £750
    expect(url.searchParams.get("d")).toBe("Grace: encore!");
  });

  it("refuses a Monzo tip on a jar that has no Monzo handle", async () => {
    const { jarId } = await createJar(); // revolut + mobilepay only
    mockTurnstile();
    // Same "method not available" 422 an unconfigured Revolut/MobilePay gets.
    expect((await postTip(jarId, { method: "monzo" })).status).toBe(422);
  });

  it("rejects tips that fail Turnstile", async () => {
    const { jarId } = await createJar();
    mockTurnstile(false);
    expect((await postTip(jarId, {})).status).toBe(403);
  });

  it("rejects colons in names and bad amounts before Turnstile is even called", async () => {
    const { jarId } = await createJar();
    expect((await postTip(jarId, { name: "a:b" })).status).toBe(422);
    expect((await postTip(jarId, { amountMinor: 1 })).status).toBe(422);
    expect((await postTip(jarId, { amountMinor: "500" })).status).toBe(422);
  });

  it("rejects methods the jar does not offer", async () => {
    const { jarId } = await createJar({ methods: { stripeUrl: "https://buy.stripe.com/onlyCard" } });
    mockTurnstile();
    expect((await postTip(jarId, { method: "revolut" })).status).toBe(422);
  });

  it("rejects cross-origin form posts", async () => {
    const { jarId } = await createJar();
    const res = await SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
      method: "POST",
      headers: { "content-type": "application/json", Origin: "https://evil.example" },
      body: "{}",
    });
    expect(res.status).toBe(403);
  });

  it("applies the per-jar rate limit", async () => {
    const { jarId } = await createJar();
    for (let i = 0; i < 6; i++) {
      mockTurnstile();
      const res = await postTip(jarId, { amountMinor: 500 + i });
      expect(res.status).toBe(200);
    }
    mockTurnstile();
    const seventh = await postTip(jarId, { amountMinor: 700 });
    expect(seventh.status).toBe(429);
    expect(seventh.headers.get("Retry-After")).toBe("30");
  });
});

describe("admin", () => {
  it("requires the admin token", async () => {
    const res = await SELF.fetch("https://api.live.tips/admin/jars");
    expect(res.status).toBe(401);
  });

  it("lists jars and deletes them", async () => {
    const { jarId } = await createJar();
    const auth = { Authorization: "Bearer test-admin-token" };
    const list = await SELF.fetch("https://api.live.tips/admin/jars", { headers: auth });
    expect(list.status).toBe(200);
    const rows = await list.json<{ jarId: string; artistName: string }[]>();
    expect(rows.some((r) => r.jarId === jarId && r.artistName === "Ada Lovelace")).toBe(true);

    const del = await SELF.fetch(`https://api.live.tips/admin/jars/${jarId}`, { method: "DELETE", headers: auth });
    expect(del.status).toBe(204);
    expect((await SELF.fetch(`https://live.tips/t/${jarId}`)).status).toBe(404);
  });

  it("serves the dashboard page without auth but with CSP", async () => {
    const res = await SELF.fetch("https://api.live.tips/admin");
    expect(res.status).toBe(200);
    expect(res.headers.get("Content-Security-Policy")).toContain("script-src 'sha256-");
  });
});
