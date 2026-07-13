/// The reconnect carry-over of stripeConnect, driven through the real handler
/// over an in-memory Firestore stand-in and a two-account fake Stripe.
///
/// The failure this pins down (issue #8): an artist reconnects a band with a
/// key from a DIFFERENT Stripe account, and the connection silently keeps the
/// old account's paymentLinkId. Every checkout.session.* event from the new
/// account then fails the payment_link filter (stripe-events.ts), the webhook
/// answers 200 and forgets, and QR tips evaporate until a new jar happens to
/// be created. The fix carries the link over only when the incoming key can
/// actually see it — Stripe 404s a link on any other account.

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { sealSecret } from "../src/stripe-crypto";
import type { StripeConnectionDoc } from "../src/stripe-store";

// ---------------------------------------------------------------------------
// Module mocks, collect-token.test.ts style: ./store's Admin SDK, KMS and the
// session watermark are replaced by in-memory stand-ins. Values the handler
// under test never touches are absent on purpose (a call would fail loudly).

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
  };
}

/** Firestore serializes transactions on the docs they read; so does this — the
 * bodies run one at a time, and the second one sees what the first committed. */
let txChain: Promise<unknown> = Promise.resolve();

const fakeDb = {
  collection: (name: string) => colRef(name),
  runTransaction: <T>(fn: (tx: unknown) => Promise<T>): Promise<T> => {
    const run = txChain.then(() => {
      // Buffered like a real transaction: the writes land at the end, together.
      const ops: (() => void)[] = [];
      const tx = {
        get: async (ref: { path: string }) => {
          const data = docs.get(ref.path);
          return { exists: data !== undefined, data: () => (data === undefined ? undefined : { ...data }) };
        },
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
      return fn(tx).then((result) => {
        for (const op of ops) op();
        return result;
      });
    });
    // A rejected transaction must not break the chain for the next one.
    txChain = run.catch(() => undefined);
    return run;
  },
  batch: () => {
    // Buffered like the real thing: nothing lands until commit().
    const ops: (() => void)[] = [];
    return {
      create: (ref: { path: string }, doc: Record<string, unknown>) =>
        ops.push(() => {
          if (docs.has(ref.path)) throw new Error(`create on existing ${ref.path}`);
          docs.set(ref.path, { ...doc });
        }),
      set: (ref: { path: string }, data: Record<string, unknown>, opts?: { merge?: boolean }) =>
        ops.push(() => {
          const existing = (opts?.merge ? docs.get(ref.path) : undefined) ?? {};
          // Deep enough for the one merge the handler does: the pointer's
          // connections map.
          const connections = {
            ...(existing["connections"] as Record<string, unknown> | undefined),
            ...(data["connections"] as Record<string, unknown> | undefined),
          };
          docs.set(ref.path, { ...existing, ...data, connections });
        }),
      delete: (ref: { path: string }) => ops.push(() => docs.delete(ref.path)),
      commit: async () => {
        for (const op of ops) op();
      },
    };
  },
};

vi.mock("../src/store", () => ({
  db: () => fakeDb,
  bumpQuota: async () => true,
  STRIPE_CONNECTS_PER_UID_PER_HOUR: 10,
}));

vi.mock("../src/devices", () => ({
  requireFreshSession: async () => {},
  // The real anonymous-rejecting guard is pinned in stripe-guards.test.ts;
  // for the carry-over scenarios it only has to hand the uid back.
  requireNonAnonymousUid: (request: { auth: { uid: string } }) => request.auth.uid,
}));

/** A KeyWrapper whose "KMS" is the identity function — the envelope logic
 * around it is real (stripe-crypto.test.ts covers it), only the wrap is not. */
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

import { stripeConnectHandler } from "../src/stripe-connect";

// ---------------------------------------------------------------------------
// The fake Stripe: TWO accounts behind one fetch, told apart by the bearer
// key. OLD_LINK lives on account A — account B's answer to it is the same
// 404 the real Stripe gives for a link on any other account.

// Invented keys, assembled rather than written out (see stripe-api.test.ts).
const rk = (tag: string) => `rk_test_51${tag}BCDEFGHJKLMNPQRSTUVWXYZ0123`;
const KEY_A_OLD = rk("AccountAold");
const KEY_A_FRESH = rk("AccountAfresh");
const KEY_B = rk("AccountBnew");

const OLD_LINK = "plink_1OldTipJarLink";

/** Set true to make GET payment_links/{id} answer 500 — Stripe down. */
let linkLookupDown = false;
/** Every request the handler made, as "METHOD path". */
let stripeRequests: string[] = [];
/**
 * When set, POST webhook_endpoints blocks until `size` callers have arrived —
 * the only way to hold two connects inside the lookup→commit gap at once, which
 * is where the race of issue #19(c) lives.
 */
let endpointBarrier: (() => Promise<void>) | null = null;

function barrier(size: number): () => Promise<void> {
  let arrived = 0;
  let release!: () => void;
  const open = new Promise<void>((resolve) => { release = resolve; });
  return async () => {
    if (++arrived === size) release();
    await open;
  };
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status });
}

const fakeStripeFetch = (async (url: RequestInfo | URL, init?: RequestInit) => {
  const method = init?.method ?? "GET";
  const path = String(url).replace("https://api.stripe.com/v1/", "").split("?")[0]!;
  stripeRequests.push(`${method} ${path}`);
  const account = (init?.headers as Record<string, string>)["Authorization"] === `Bearer ${KEY_B}` ? "B" : "A";

  if (method === "GET" && path === `payment_links/${OLD_LINK}`) {
    if (linkLookupDown) return json(500, { error: { message: "server error", type: "api_error" } });
    if (account === "A") return json(200, { id: OLD_LINK, object: "payment_link", active: true });
    return json(404, {
      error: { message: `No such payment link: '${OLD_LINK}'`, code: "resource_missing", type: "invalid_request_error" },
    });
  }
  // The five key probes are plain list GETs; both accounts grant them all.
  if (method === "GET") return json(200, { object: "list", data: [] });
  if (method === "POST" && path === "webhook_endpoints") {
    if (endpointBarrier) await endpointBarrier();
    return json(200, { id: `we_new_${account}`, object: "webhook_endpoint", secret: `whsec_new_${account}` });
  }
  if (method === "DELETE") return json(200, { deleted: true });
  return json(400, { error: { message: `unexpected ${method} ${path}` } });
}) as typeof fetch;

// ---------------------------------------------------------------------------

const UID = "uid_artist";
const BAND = "acc_m3k9zq1a2b3c";
const OLD_CONN = "c".repeat(22); // valid jarId shape (lowercase base36)

async function seedConnection() {
  const doc: StripeConnectionDoc = {
    uid: UID,
    bandId: BAND,
    key: await sealSecret(KEY_A_OLD, testWrapper),
    livemode: false,
    webhookEndpointId: "we_old_A",
    webhookSecret: await sealSecret("whsec_old_A", testWrapper),
    paymentLinkId: OLD_LINK,
    createdAtMs: Date.now() - 60_000,
  };
  docs.set(`stripeConnections/${OLD_CONN}`, doc as unknown as Record<string, unknown>);
  docs.set(`users/${UID}/private/stripe`, { connections: { [BAND]: OLD_CONN } });
}

function connectRequest(key: string): never {
  // CallableRequest is structurally typed; only what the handler reads.
  return { auth: { uid: UID }, data: { bandId: BAND, key } } as never;
}

/** The connection the pointer names after the connect — the doc that will
 * answer for every future webhook event. */
function currentConnection(): StripeConnectionDoc {
  const pointer = docs.get(`users/${UID}/private/stripe`)!;
  const connectionId = (pointer["connections"] as Record<string, string>)[BAND]!;
  return docs.get(`stripeConnections/${connectionId}`) as unknown as StripeConnectionDoc;
}

beforeEach(() => {
  docs.clear();
  stripeRequests = [];
  linkLookupDown = false;
  endpointBarrier = null;
  txChain = Promise.resolve();
  vi.stubGlobal("fetch", fakeStripeFetch);
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("stripeConnect: the reconnect carry-over", () => {
  it("SAME account, fresh key: the jar's payment link is kept — no churn", async () => {
    await seedConnection();

    const result = await stripeConnectHandler(connectRequest(KEY_A_FRESH));

    expect(result.ok).toBe(true);
    const doc = currentConnection();
    expect(doc.paymentLinkId).toBe(OLD_LINK);
    // The replacement itself still happened: new endpoint, old doc gone.
    expect(doc.webhookEndpointId).toBe("we_new_A");
    expect(docs.has(`stripeConnections/${OLD_CONN}`)).toBe(false);
  });

  it("DIFFERENT account: the old link is NOT carried over — tips must not silently evaporate", async () => {
    await seedConnection();

    const result = await stripeConnectHandler(connectRequest(KEY_B));

    expect(result.ok).toBe(true);
    const doc = currentConnection();
    // Null forces jar re-creation, exactly like a first connect; the one
    // forbidden outcome is a stored plink the new key cannot see.
    expect(doc.paymentLinkId).toBeNull();
    // The webhook wiring is the NEW account's throughout: its endpoint, its
    // signing secret — nothing of account A's survives on the connection.
    expect(doc.webhookEndpointId).toBe("we_new_B");
    expect(docs.has(`stripeConnections/${OLD_CONN}`)).toBe(false);
  });

  it("an explicitly passed paymentLinkId still short-circuits the check (pre-existing jar)", async () => {
    await seedConnection();

    const request = { auth: { uid: UID }, data: { bandId: BAND, key: KEY_A_FRESH, paymentLinkId: "plink_1HandedInLink" } } as never;
    const result = await stripeConnectHandler(request);

    expect(result.ok).toBe(true);
    expect(currentConnection().paymentLinkId).toBe("plink_1HandedInLink");
    // No lookup was needed: the caller vouched for this link with this key.
    expect(stripeRequests).not.toContain(`GET payment_links/${OLD_LINK}`);
  });

  it("Stripe trouble during the check fails the connect loudly — never a guess", async () => {
    await seedConnection();
    linkLookupDown = true;

    await expect(stripeConnectHandler(connectRequest(KEY_A_FRESH))).rejects.toThrow(/unavailable|Stripe/);

    // Nothing was replaced and nothing was registered: the old connection
    // still answers, and no endpoint was stranded on the artist's account.
    expect(docs.get(`users/${UID}/private/stripe`)!["connections"]).toEqual({ [BAND]: OLD_CONN });
    expect(docs.has(`stripeConnections/${OLD_CONN}`)).toBe(true);
    expect(stripeRequests).not.toContain("POST webhook_endpoints");
  });

  it("a first connect (nothing stored) starts with a null link, untouched by the guard", async () => {
    const result = await stripeConnectHandler(connectRequest(KEY_B));

    expect(result.ok).toBe(true);
    expect(currentConnection().paymentLinkId).toBeNull();
    expect(stripeRequests.filter((r) => r.startsWith("GET payment_links/"))).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// Issue #19(c): the lookup→commit race. The lookup happens BEFORE the Stripe
// round-trips, so two connects for one band can both be holding the same
// `existing` when they reach the commit. Before the fix both wrote a connection
// doc and the pointer merge picked a winner at random — the loser's doc (a
// sealed key AND a live webhook endpoint on the artist's Stripe account) was
// orphaned forever: nothing follows anything but the pointer, and no sweep
// touches stripeConnections. The barrier below holds both calls inside exactly
// that gap.

/** Every connection doc currently stored — an orphan is one nobody points at. */
function connectionIds(): string[] {
  return [...docs.keys()]
    .filter((path) => path.startsWith("stripeConnections/"))
    .map((path) => path.slice("stripeConnections/".length));
}

describe("stripeConnect: two connects for one band cannot both commit", () => {
  it("a first connect racing itself leaves ONE connection and no orphan", async () => {
    endpointBarrier = barrier(2);

    const results = await Promise.allSettled([
      stripeConnectHandler(connectRequest(KEY_A_FRESH)),
      stripeConnectHandler(connectRequest(KEY_A_FRESH)),
    ]);

    // Both registered an endpoint (that is the race), but only one committed.
    expect(stripeRequests.filter((r) => r === "POST webhook_endpoints")).toHaveLength(2);
    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    const loser = results.find((r) => r.status === "rejected") as PromiseRejectedResult;
    expect(loser.reason).toMatchObject({ code: "aborted" });

    // The loser left nothing behind: no second doc, and its endpoint was
    // rolled back off the artist's Stripe account.
    expect(connectionIds()).toHaveLength(1);
    const pointer = docs.get(`users/${UID}/private/stripe`)!["connections"] as Record<string, string>;
    expect(pointer[BAND]).toBe(connectionIds()[0]);
    expect(stripeRequests).toContain("DELETE webhook_endpoints/we_new_A");
  });

  it("a reconnect racing itself replaces exactly once", async () => {
    await seedConnection();
    endpointBarrier = barrier(2);

    const results = await Promise.allSettled([
      stripeConnectHandler(connectRequest(KEY_A_FRESH)),
      stripeConnectHandler(connectRequest(KEY_A_FRESH)),
    ]);

    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    // The old connection is gone (the winner replaced it), the loser's is
    // never created — one band, one connection, whatever the interleaving.
    expect(connectionIds()).toHaveLength(1);
    expect(connectionIds()[0]).not.toBe(OLD_CONN);
    const doc = currentConnection();
    expect(doc.webhookEndpointId).toBe("we_new_A");
    expect(doc.paymentLinkId).toBe(OLD_LINK);
  });
});
