/// The custody surface's auth line, driven through the real handlers (issue
/// #18): stripeConnect / stripeProxy / stripeDisconnect are for signed-in
/// cloud accounts ONLY, and the code must enforce what the headers promise.
///
/// Why it matters: an anonymous uid — the relay-transport guest identity —
/// is unrecoverable by design. If it could seal a Stripe key server-side and
/// register a webhook endpoint, losing that guest identity would strand both
/// with no principal that could ever disconnect them. So all three handlers
/// call requireNonAnonymousUid (devices.ts), the same guard that keeps a
/// guest from stranding itself via createLinkCode.
///
/// Unlike stripe-connect.test.ts, ./devices is NOT mocked here — the real
/// guard (and the real requireFreshSession, over a never-revoked security
/// doc) is exactly what is under test.

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { sealSecret } from "../src/stripe-crypto";
import type { StripeConnectionDoc } from "../src/stripe-store";

// ---------------------------------------------------------------------------
// Module mocks, stripe-connect.test.ts style: ./store's Admin SDK and KMS are
// in-memory stand-ins. ./devices stays real (see the header).

/** path → doc data. Reset per test. */
const docs = new Map<string, Record<string, unknown>>();

function colRef(path: string): { doc: (id: string) => ReturnType<typeof docRef> } {
  return { doc: (id: string) => docRef(`${path}/${id}`) };
}

function docRef(path: string) {
  return {
    path,
    collection: (name: string) => colRef(`${path}/${name}`),
    get: async () => {
      const data = docs.get(path);
      return { exists: data !== undefined, data: () => (data === undefined ? undefined : { ...data }) };
    },
    // The teardown (stripe-connect.ts tearDownConnection, shared with the
    // account deletion) drops the sealed doc — and then the pointer entry —
    // on their own refs, not through a batch: our side is cleaned up whatever
    // Stripe said, and a dangling pointer reads as not connected anyway.
    set: async (data: Record<string, unknown>, opts?: { merge?: boolean }) => {
      const existing = (opts?.merge ? docs.get(path) : undefined) ?? {};
      const connections = {
        ...(existing["connections"] as Record<string, unknown> | undefined),
        ...(data["connections"] as Record<string, unknown> | undefined),
      };
      docs.set(path, { ...existing, ...data, connections });
    },
    delete: async () => {
      docs.delete(path);
    },
  };
}

/** The buffered writes a batch and a transaction both take (see #19c: connect
 * commits in a transaction now, disconnect still in a batch). */
function writeOps() {
  const ops: (() => void)[] = [];
  return {
    ops,
    create: (ref: { path: string }, doc: Record<string, unknown>) =>
      ops.push(() => {
        if (docs.has(ref.path)) throw new Error(`create on existing ${ref.path}`);
        docs.set(ref.path, { ...doc });
      }),
    set: (ref: { path: string }, data: Record<string, unknown>, opts?: { merge?: boolean }) =>
      ops.push(() => {
        const existing = (opts?.merge ? docs.get(ref.path) : undefined) ?? {};
        const connections = {
          ...(existing["connections"] as Record<string, unknown> | undefined),
          ...(data["connections"] as Record<string, unknown> | undefined),
        };
        docs.set(ref.path, { ...existing, ...data, connections });
      }),
    delete: (ref: { path: string }) => ops.push(() => docs.delete(ref.path)),
  };
}

const fakeDb = {
  collection: (name: string) => colRef(name),
  runTransaction: async <T>(fn: (tx: unknown) => Promise<T>): Promise<T> => {
    const writes = writeOps();
    const result = await fn({
      ...writes,
      get: async (ref: { path: string }) => {
        const data = docs.get(ref.path);
        return { exists: data !== undefined, data: () => (data === undefined ? undefined : { ...data }) };
      },
    });
    for (const op of writes.ops) op();
    return result;
  },
  batch: () => {
    const writes = writeOps();
    return { ...writes, commit: async () => { for (const op of writes.ops) op(); } };
  },
};

vi.mock("../src/store", () => ({
  db: () => fakeDb,
  bumpQuota: async () => true,
  // requireFreshSession (real here) consults the security doc; an absent
  // watermark means "never revoked" and the callable proceeds.
  securityRef: () => ({ get: async () => ({ get: () => undefined }) }),
}));

/** Identity "KMS", as in stripe-connect.test.ts. */
const { testWrapper } = vi.hoisted(() => ({
  testWrapper: {
    kmsKeyName: "projects/test/locations/x/keyRings/r/cryptoKeys/k",
    wrap: async (dek: Buffer) => Buffer.from(dek),
    unwrap: async (wrapped: Buffer) => Buffer.from(wrapped),
  },
}));

vi.mock("../src/kms", () => ({
  kmsKeyWrapper: () => testWrapper,
}));

vi.mock("firebase-functions/params", () => ({
  defineString: (_name: string, opts?: { default?: string }) => ({ value: () => opts?.default ?? "" }),
  defineSecret: (_name: string) => ({ value: () => "" }), // params.ts, unused here
}));

import { stripeConnectHandler, stripeDisconnectHandler } from "../src/stripe-connect";
import { stripeProxyHandler } from "../src/stripe-proxy";

// ---------------------------------------------------------------------------
// A fake Stripe that grants everything — auth is what is under test, so no
// call may fail for Stripe reasons. Requests are recorded to prove the guard
// fired BEFORE anything reached the artist's account.

/** Every request the handlers made, as "METHOD path". */
let stripeRequests: string[] = [];

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status });
}

const fakeStripeFetch = (async (url: RequestInfo | URL, init?: RequestInit) => {
  const method = init?.method ?? "GET";
  const path = String(url).replace("https://api.stripe.com/v1/", "").split("?")[0]!;
  stripeRequests.push(`${method} ${path}`);
  // The five key probes are plain list GETs; grant them all.
  if (method === "GET") return json(200, { object: "list", data: [] });
  if (method === "POST" && path === "webhook_endpoints") {
    return json(200, { id: "we_1", object: "webhook_endpoint", secret: "whsec_1" });
  }
  if (method === "DELETE") return json(200, { deleted: true });
  return json(400, { error: { message: `unexpected ${method} ${path}` } });
}) as typeof fetch;

// ---------------------------------------------------------------------------

const UID = "uid_caller";
const BAND = "acc_m3k9zq1a2b3c";
const CONN = "c".repeat(22); // valid jarId shape (lowercase base36)

// Invented key, assembled rather than written out (see stripe-api.test.ts).
const rk = (tag: string) => `rk_test_51${tag}BCDEFGHJKLMNPQRSTUVWXYZ0123`;
const KEY = rk("Guard");

/** A callable request with the given provider — only what the handlers read. */
function caller(provider: string, data: Record<string, unknown>): never {
  return {
    auth: {
      uid: UID,
      token: {
        auth_time: Math.floor(Date.now() / 1000),
        firebase: { sign_in_provider: provider },
      },
    },
    data,
  } as never;
}

const anonymous = (data: Record<string, unknown>) => caller("anonymous", data);
const signedIn = (data: Record<string, unknown>) => caller("password", data);

async function seedConnection() {
  const doc: StripeConnectionDoc = {
    uid: UID,
    bandId: BAND,
    key: await sealSecret(KEY, testWrapper),
    livemode: false,
    webhookEndpointId: "we_seeded",
    webhookSecret: await sealSecret("whsec_seeded", testWrapper),
    paymentLinkId: null,
    createdAtMs: Date.now() - 60_000,
  };
  docs.set(`stripeConnections/${CONN}`, doc as unknown as Record<string, unknown>);
  docs.set(`users/${UID}/private/stripe`, { connections: { [BAND]: CONN } });
}

beforeEach(() => {
  docs.clear();
  stripeRequests = [];
  vi.stubGlobal("fetch", fakeStripeFetch);
});

afterEach(() => {
  vi.unstubAllGlobals();
});

// The exact rejection requireNonAnonymousUid throws for the device surface —
// the custody surface must answer identically.
const GUEST_REFUSAL = { code: "failed-precondition", message: "link a permanent sign-in method first" };

describe("the custody surface refuses anonymous uids (issue #18)", () => {
  it("stripeConnect: a guest cannot seal a key — nothing reaches Stripe, nothing is stored", async () => {
    await expect(
      stripeConnectHandler(anonymous({ bandId: BAND, key: KEY })),
    ).rejects.toMatchObject(GUEST_REFUSAL);

    // The guard fired FIRST: no probe, no endpoint registration, no doc.
    expect(stripeRequests).toEqual([]);
    expect(docs.size).toBe(0);
  });

  it("stripeDisconnect: a guest cannot tear a connection down either", async () => {
    await seedConnection();

    await expect(
      stripeDisconnectHandler(anonymous({ bandId: BAND })),
    ).rejects.toMatchObject(GUEST_REFUSAL);

    expect(stripeRequests).toEqual([]);
    expect(docs.has(`stripeConnections/${CONN}`)).toBe(true);
  });

  it("stripeProxy: a guest cannot drive the artist's key, not even for a probe", async () => {
    await seedConnection();

    await expect(
      stripeProxyHandler(anonymous({ bandId: BAND, op: "checkKey" })),
    ).rejects.toMatchObject(GUEST_REFUSAL);

    expect(stripeRequests).toEqual([]);
  });
});

describe("a signed-in cloud account still passes every handler", () => {
  it("stripeConnect stores the connection", async () => {
    const result = await stripeConnectHandler(signedIn({ bandId: BAND, key: KEY }));

    expect(result.ok).toBe(true);
    const pointer = docs.get(`users/${UID}/private/stripe`)!;
    expect((pointer["connections"] as Record<string, string>)[BAND]).toBeDefined();
  });

  it("stripeProxy answers a checkKey probe", async () => {
    await seedConnection();

    const result = await stripeProxyHandler(signedIn({ bandId: BAND, op: "checkKey" }));

    expect(result["allOk"]).toBe(true);
  });

  it("stripeDisconnect removes the connection", async () => {
    await seedConnection();

    const result = await stripeDisconnectHandler(signedIn({ bandId: BAND }));

    expect(result).toEqual({ ok: true });
    expect(docs.has(`stripeConnections/${CONN}`)).toBe(false);
  });
});
