/// The tip POST's quota-vs-Turnstile ordering, driven through the real
/// handler with the store and siteverify mocked.
///
/// The production failure this pins down: `bumpQuota` ran BEFORE Turnstile
/// verification, keyed on a spoofable `req.ip` — so 120 unauthenticated junk
/// POSTs carrying `X-Forwarded-For: <a venue's NAT>` exhausted that address's
/// hourly bucket and 429'd every real fan in the bar, at the cost of zero
/// Turnstile solves. The quota now spends only after Turnstile vouches for
/// the request, and its key derives from the platform-appended header entry.

import { beforeEach, describe, expect, it, vi } from "vitest";
import { ipQuotaKey } from "../src/auth";

// ---------------------------------------------------------------------------
// Module mocks, in the collect-token.test.ts mold: constants keep their
// meaning, functions the paths under test never reach are absent on purpose.

const bumpQuota = vi.fn<(...args: unknown[]) => Promise<boolean>>();

vi.mock("../src/store", () => ({
  db: () => ({}),
  jarRef: (_db: unknown, jarId: string) => ({
    get: async () => ({ data: () => jar }),
    path: `jars/${jarId}`,
  }),
  jarIsLive: (doc: unknown) => doc !== undefined,
  bumpQuota: (...args: unknown[]) => bumpQuota(...args),
  TIPS_PER_IP_PER_HOUR: 120,
}));

vi.mock("../src/params", () => ({
  IP_HASH_SALT: { value: () => "test-salt" },
  TURNSTILE_SECRET: { value: () => "test-secret" },
  TURNSTILE_SITE_KEY: { value: () => "test-sitekey" },
}));

const verifyTurnstile = vi.fn<(...args: unknown[]) => Promise<boolean>>();
vi.mock("../src/turnstile", () => ({
  verifyTurnstile: (...args: unknown[]) => verifyTurnstile(...args),
}));

import { tipHandler } from "../src/tip";

// ---------------------------------------------------------------------------

const JAR_ID = "j".repeat(26); // valid jarId shape
const CLIENT = "203.0.113.9"; // the address the platform saw
const FORGED = "198.51.100.66"; // the venue's NAT, as typed by the attacker
const CDN = "216.239.36.53"; // the Hosting hop Cloud Run appended

const jar = {
  profile: {
    artistName: "Ana",
    message: "",
    currency: "eur",
    methods: { revolutUsername: "ana" },
  },
};

/** A POST /t/:jarId/tips as Cloud Run hands it over: the forged entry the
 * attacker sent on the left, the platform-appended chain on the right. */
function tipPost(xff: string): never {
  const body = { method: "revolut", amountMinor: 500, name: "", message: "", turnstileToken: "tok" };
  return {
    path: `/t/${JAR_ID}/tips`,
    method: "POST",
    protocol: "https",
    get: (header: string) => (header === "host" ? "tip.live.tips" : undefined),
    rawBody: Buffer.from(JSON.stringify(body)),
    headers: { "x-forwarded-for": xff },
    socket: { remoteAddress: "169.254.8.129" },
  } as never;
}

function fakeRes() {
  const res = {
    statusCode: 0,
    body: undefined as Record<string, unknown> | undefined,
    status(code: number) { this.statusCode = code; return this; },
    set() { return this; },
    send(payload: string) { this.body = JSON.parse(payload) as Record<string, unknown>; },
  };
  return res;
}

beforeEach(() => {
  bumpQuota.mockReset();
  verifyTurnstile.mockReset();
});

describe("tip POST: no quota spent without a Turnstile pass", () => {
  it("a failed verification consumes NO one's bucket — griefing costs a real solve", async () => {
    verifyTurnstile.mockResolvedValue(false);
    const res = fakeRes();

    await tipHandler(tipPost(`${FORGED}, ${CLIENT}, ${CDN}`), res as never);

    expect(res.statusCode).toBe(403);
    expect(bumpQuota).not.toHaveBeenCalled();
  });

  it("verification runs first; only then does the quota spend", async () => {
    verifyTurnstile.mockResolvedValue(true);
    bumpQuota.mockResolvedValue(false); // over quota: the handler stops here
    const res = fakeRes();

    await tipHandler(tipPost(`${FORGED}, ${CLIENT}, ${CDN}`), res as never);

    expect(res.statusCode).toBe(429);
    expect(verifyTurnstile.mock.invocationCallOrder[0]!)
      .toBeLessThan(bumpQuota.mock.invocationCallOrder[0]!);
  });
});

describe("tip POST: the quota key comes from the platform, not the attacker", () => {
  it("keys on the Hosting-appended entry; the forged one is inert", async () => {
    verifyTurnstile.mockResolvedValue(true);
    bumpQuota.mockResolvedValue(false);
    const res = fakeRes();

    await tipHandler(tipPost(`${FORGED}, ${CLIENT}, ${CDN}`), res as never);

    const key = bumpQuota.mock.calls[0]![1];
    expect(key).toBe(ipQuotaKey(CLIENT, "test-salt", "tips"));
    expect(key).not.toBe(ipQuotaKey(FORGED, "test-salt", "tips"));
    // Turnstile is told about the same derived address, not the forged one.
    expect(verifyTurnstile).toHaveBeenCalledWith("tok", CLIENT, "test-secret");
  });

  it("rotating the forged entry lands every request in the same bucket", async () => {
    verifyTurnstile.mockResolvedValue(true);
    bumpQuota.mockResolvedValue(false);

    for (const junk of ["10.0.0.1", "8.8.8.8", "2001:db8::1"]) {
      await tipHandler(tipPost(`${junk}, ${CLIENT}, ${CDN}`), fakeRes() as never);
    }

    const keys = new Set(bumpQuota.mock.calls.map((call) => call[1]));
    expect(keys).toEqual(new Set([ipQuotaKey(CLIENT, "test-salt", "tips")]));
  });
});
