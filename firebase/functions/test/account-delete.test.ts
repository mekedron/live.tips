/// deleteAccount, driven through the real handler over an in-memory Firestore
/// stand-in and a fake Stripe (revocation.test.ts / stripe-connect.test.ts
/// shape). What is pinned here is what #33 says a delete has to actually be:
///
///  - every surface goes — bands and their sessions/relayTips/secrets, the
///    relay jars behind the PUBLIC tip pages, the sealed Stripe key AND the
///    webhook endpoint on the artist's own account, the devices, the link
///    codes, the watermark, the Auth user;
///  - a GUEST can do it (its jar is not ownerUid-pinned — an ownerUid query
///    alone would leave the public page up forever);
///  - an orphaned Stripe connection (#19(c)) is collected too: nothing else
///    ever could;
///  - a stale session is refused, like every other device ceremony;
///  - a partial delete is RECORDED, never reported as done, and resumes —
///    including from the sweep, which is the only actor left once the Auth
///    user is gone.

import { beforeEach, describe, expect, it, vi } from "vitest";
import { sealSecret } from "../src/stripe-crypto";
import type { StripeConnectionDoc } from "../src/stripe-store";

// ---------------------------------------------------------------------------
// The in-memory Firestore. Only what these handlers touch: doc get/set/create/
// delete, direct-child queries, a delete-only batch, and recursiveDelete.

/** path → doc data. Reset per test. */
const docs = new Map<string, Record<string, unknown>>();

/** When set, any recursiveDelete under this path prefix throws — how the
 * partial-delete scenario stops the run exactly where it wants to. */
let recursiveDeleteFailsUnder: string | null = null;

function fakeSnap(path: string) {
  const data = docs.get(path);
  return {
    exists: data !== undefined,
    id: path.slice(path.lastIndexOf("/") + 1),
    ref: { path },
    data: () => (data === undefined ? undefined : { ...data }),
    get: (field: string) => data?.[field],
  };
}

type Filter = { field: string; op: string; value: unknown };

function matches(data: Record<string, unknown>, f: Filter): boolean {
  const actual = data[f.field];
  if (f.op === "==") return actual === f.value;
  if (f.op === "<") return typeof actual === "number" && typeof f.value === "number" && actual < f.value;
  throw new Error(`unsupported operator ${f.op}`);
}

/** Direct children of `prefix` matching every filter. */
function fakeQuery(prefix: string, filters: Filter[] = [], cap = Infinity) {
  return {
    where: (field: string, op: string, value: unknown) =>
      fakeQuery(prefix, [...filters, { field, op, value }], cap),
    limit: (n: number) => fakeQuery(prefix, filters, n),
    doc: (id: string) => docRef(`${prefix}/${id}`),
    get: async () => {
      const out = [];
      for (const [path, data] of docs) {
        if (!path.startsWith(`${prefix}/`)) continue;
        if (path.slice(prefix.length + 1).includes("/")) continue;
        if (!filters.every((f) => matches(data, f))) continue;
        if (out.length >= cap) break;
        out.push(fakeSnap(path));
      }
      return { docs: out, empty: out.length === 0, size: out.length };
    },
  };
}

function docRef(path: string) {
  return {
    path,
    collection: (name: string) => fakeQuery(`${path}/${name}`),
    get: async () => fakeSnap(path),
    create: async (data: Record<string, unknown>) => {
      if (docs.has(path)) throw new Error(`create on existing ${path}`);
      docs.set(path, { ...data });
    },
    set: async (data: Record<string, unknown>, opts?: { merge?: boolean }) => {
      const existing = (opts?.merge ? docs.get(path) : undefined) ?? {};
      docs.set(path, { ...existing, ...data });
    },
    delete: async () => {
      docs.delete(path);
    },
  };
}

const fakeDb = {
  collection: (name: string) => fakeQuery(name),
  batch: () => {
    const ops: (() => void)[] = [];
    return {
      delete: (ref: { path: string }) => ops.push(() => docs.delete(ref.path)),
      commit: async () => {
        for (const op of ops) op();
      },
    };
  },
  recursiveDelete: async (ref: { path: string }) => {
    if (recursiveDeleteFailsUnder !== null && ref.path.startsWith(recursiveDeleteFailsUnder)) {
      throw new Error("firestore unavailable");
    }
    for (const path of [...docs.keys()]) {
      if (path === ref.path || path.startsWith(`${ref.path}/`)) docs.delete(path);
    }
  },
};

// The REAL ref builders (they are pure path arithmetic over a Firestore
// handle) — only db() is swapped, so the paths under test are the paths the
// deployed functions write.
vi.mock("../src/store", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../src/store")>()),
  db: () => fakeDb,
}));

vi.mock("firebase-functions/params", () => ({
  defineString: (_name: string, opts?: { default?: string }) => ({ value: () => opts?.default ?? "" }),
  defineSecret: (_name: string) => ({ value: () => "" }),
}));

/** The identity "KMS" of stripe-connect.test.ts: the envelope logic around it
 * is real, only the wrap is not. */
const { testWrapper } = vi.hoisted(() => ({
  testWrapper: {
    kmsKeyName: "projects/test/locations/x/keyRings/r/cryptoKeys/k",
    wrap: async (dek: Buffer) => Buffer.from(dek),
    unwrap: async (wrapped: Buffer) => Buffer.from(wrapped),
  },
}));

vi.mock("../src/kms", () => ({ kmsKeyWrapper: () => testWrapper }));

const deleteUser = vi.fn<(uid: string) => Promise<void>>();
vi.mock("firebase-admin/auth", () => ({ getAuth: () => ({ deleteUser }) }));

import { deleteAccountHandler, resumeAccountDeletions } from "../src/account";

// ---------------------------------------------------------------------------
// The fake Stripe: endpoint deletes are what we care about.

const UID = "uid_artist";
const BAND = "acc_band1";
const CONN = "c".repeat(24);
const ORPHAN = "d".repeat(24);
const KEY = `rk_test_51${"AccountA"}BCDEFGHJKLMNPQRSTUVWXYZ0123`;

/** Every request the teardown made, as "METHOD path". */
let stripeRequests: string[] = [];
/** Endpoint ids Stripe refuses to delete (a key the artist already revoked). */
let undeletableEndpoints = new Set<string>();

const fakeStripeFetch = (async (url: RequestInfo | URL, init?: RequestInit) => {
  const method = init?.method ?? "GET";
  const path = String(url).replace("https://api.stripe.com/v1/", "").split("?")[0]!;
  stripeRequests.push(`${method} ${path}`);
  if (method === "DELETE") {
    const id = path.slice("webhook_endpoints/".length);
    if (undeletableEndpoints.has(id)) {
      return new Response(JSON.stringify({ error: { message: "Invalid API Key", type: "invalid_request_error" } }), { status: 401 });
    }
    return new Response(JSON.stringify({ deleted: true }), { status: 200 });
  }
  // payment_links/{id} deactivation
  return new Response(JSON.stringify({ id: "plink_x", object: "payment_link", active: false }), { status: 200 });
}) as typeof fetch;

// ---------------------------------------------------------------------------

/** A callable request whose token is FRESH (auth_time = now). */
function signedIn(provider = "google.com", authTimeMs = Date.now()): never {
  return {
    auth: {
      uid: UID,
      token: {
        auth_time: Math.floor(authTimeMs / 1000),
        firebase: { sign_in_provider: provider },
      },
    },
    data: {},
    rawRequest: { headers: {}, socket: { remoteAddress: "203.0.113.7" } },
  } as never;
}

async function seedConnection(connectionId: string, endpointId: string, pointed: boolean) {
  const doc: StripeConnectionDoc = {
    uid: UID,
    bandId: BAND,
    key: await sealSecret(KEY, testWrapper),
    livemode: false,
    webhookEndpointId: endpointId,
    webhookSecret: await sealSecret("whsec_test", testWrapper),
    paymentLinkId: "plink_x",
    createdAtMs: Date.now(),
  };
  docs.set(`stripeConnections/${connectionId}`, doc as unknown as Record<string, unknown>);
  if (pointed) {
    docs.set(`users/${UID}/private/stripe`, { connections: { [BAND]: connectionId } });
  }
}

/** The whole account, as the app leaves it: a band with a relay jar, an owned
 * jar, devices, a session, cached history, secrets, a live QR grant. */
async function seedAccount({ ownedJar = true }: { ownedJar?: boolean } = {}) {
  docs.set(`users/${UID}`, { name: "Casey", authProvider: "google" });
  docs.set(`users/${UID}/bands/${BAND}`, {
    name: "The Midnight Foxes",
    relayJar: { jarId: "j".repeat(24), tipUrl: "https://tip.live.tips/t/jjj" },
  });
  docs.set(`users/${UID}/bands/${BAND}/sessions/s1`, { json: "…" });
  docs.set(`users/${UID}/bands/${BAND}/relayTips/t1`, { json: "…" });
  docs.set(`users/${UID}/bands/${BAND}/stripeTips/cs_1`, { amountMinor: 500 });
  docs.set(`users/${UID}/bands/${BAND}/secrets/v1`, { sealed: "…" });
  docs.set(`users/${UID}/devices/phone-1`, { name: "Casey's iPhone", revoked: false });
  docs.set(`users/${UID}/live/current`, { leader: "phone-1" });
  docs.set(`users/${UID}/settings/app`, { themeMode: "dark" });
  docs.set(`users/${UID}/private/security`, { sessionsValidAfterMs: Date.now() - 86_400_000 });
  // The jar the band names. A GUEST's jar carries ownerUid: null — the app
  // refuses to pin a public page to an unrecoverable uid (RelayAuth.ownsJars).
  docs.set(`jars/${"j".repeat(24)}`, {
    ownerUid: ownedJar ? UID : null,
    readerUids: [UID],
    profile: { artistName: "The Midnight Foxes" },
  });
  docs.set(`jars/${"j".repeat(24)}/private/auth`, { secretHash: "…" });
  docs.set(`jars/${"j".repeat(24)}/pendingTips/p1`, { amountMinor: 300 });
  docs.set(`linkCodes/${"A".repeat(22)}`, { uid: UID, status: "pending" });
  docs.set("rateLimits/create-uid-uid_artist", { hourBucket: 1, count: 3 });
  docs.set(`rateLimits/stripe-proxy-${UID}`, { hourBucket: 1, count: 9 });
  // Somebody else's everything — none of it may be touched.
  docs.set("users/uid_other", { name: "Someone else" });
  docs.set(`jars/${"z".repeat(24)}`, { ownerUid: "uid_other", readerUids: ["uid_other"] });
  docs.set(`linkCodes/${"B".repeat(22)}`, { uid: "uid_other", status: "pending" });
  await seedConnection(CONN, "we_pointed", true);
}

beforeEach(() => {
  docs.clear();
  recursiveDeleteFailsUnder = null;
  stripeRequests = [];
  undeletableEndpoints = new Set();
  deleteUser.mockReset();
  deleteUser.mockResolvedValue(undefined);
  vi.stubGlobal("fetch", fakeStripeFetch);
});

describe("deleteAccount erases the whole account", () => {
  it("takes every surface with it — and nobody else's", async () => {
    await seedAccount();
    // The orphan of #19(c): a sealed key and a LIVE endpoint that the pointer
    // can no longer see. Nothing but a uid query would ever collect it.
    await seedConnection(ORPHAN, "we_orphan", false);

    const result = await deleteAccountHandler(signedIn());

    expect(result).toEqual({ ok: true, strandedEndpoints: [] });

    // Stripe: BOTH endpoints came off the artist's own account.
    expect(stripeRequests).toContain("DELETE webhook_endpoints/we_pointed");
    expect(stripeRequests).toContain("DELETE webhook_endpoints/we_orphan");
    expect(docs.has(`stripeConnections/${CONN}`)).toBe(false);
    expect(docs.has(`stripeConnections/${ORPHAN}`)).toBe(false);
    expect(docs.has(`users/${UID}/private/stripe`)).toBe(false);

    // The public tip page dies with the account, pending tips and all.
    expect([...docs.keys()].filter((p) => p.startsWith(`jars/${"j".repeat(24)}`))).toEqual([]);

    // The uid's whole subtree: bands, sessions, relayTips, stripeTips,
    // secrets/v1, devices, live, settings, the watermark, the profile doc.
    expect([...docs.keys()].filter((p) => p.startsWith(`users/${UID}`))).toEqual([]);

    // Grants, quotas, and the Auth user itself.
    expect(docs.has(`linkCodes/${"A".repeat(22)}`)).toBe(false);
    expect(docs.has("rateLimits/create-uid-uid_artist")).toBe(false);
    expect(docs.has(`rateLimits/stripe-proxy-${UID}`)).toBe(false);
    expect(deleteUser).toHaveBeenCalledWith(UID);

    // The ledger is gone too: there is nothing left to finish.
    expect(docs.has(`accountDeletions/${UID}`)).toBe(false);

    // Somebody else's account is untouched — the queries are uid-scoped.
    expect(docs.has("users/uid_other")).toBe(true);
    expect(docs.has(`jars/${"z".repeat(24)}`)).toBe(true);
    expect(docs.has(`linkCodes/${"B".repeat(22)}`)).toBe(true);
  });

  it("a GUEST can delete itself, and its unowned tip page dies too", async () => {
    // The account #33 cares about most: unrecoverable by design, and until now
    // with no way out at all. Its jar has ownerUid: null, so the ownerUid query
    // finds nothing — the band doc is what names the page, read on the SERVER.
    await seedAccount({ ownedJar: false });

    const result = await deleteAccountHandler(signedIn("anonymous"));

    expect(result.ok).toBe(true);
    expect([...docs.keys()].filter((p) => p.startsWith(`jars/${"j".repeat(24)}`))).toEqual([]);
    expect(deleteUser).toHaveBeenCalledWith(UID);
  });

  it("an endpoint Stripe will not remove is NAMED, not hidden", async () => {
    // The artist revoked the key in their dashboard first: we can no longer
    // delete the endpoint, and a delete that quietly shrugged would leave a
    // live webhook on their account with nothing anywhere saying so.
    await seedAccount();
    undeletableEndpoints.add("we_pointed");

    const result = await deleteAccountHandler(signedIn());

    expect(result).toEqual({ ok: true, strandedEndpoints: ["we_pointed"] });
    // Our side is still cleaned up regardless — a dead key must not keep the
    // ciphertext alive.
    expect(docs.has(`stripeConnections/${CONN}`)).toBe(false);
  });
});

describe("the guards", () => {
  it("refuses a stale session, and deletes nothing", async () => {
    await seedAccount();
    // Revoked five minutes ago; this token was minted before that.
    docs.set(`users/${UID}/private/security`, { sessionsValidAfterMs: Date.now() });
    const before = docs.size;

    await expect(
      deleteAccountHandler(signedIn("google.com", Date.now() - 600_000)),
    ).rejects.toMatchObject({ code: "unauthenticated" });

    expect(docs.size).toBe(before);
    expect(docs.has(`accountDeletions/${UID}`)).toBe(false);
    expect(deleteUser).not.toHaveBeenCalled();
    expect(stripeRequests).toEqual([]);
  });

  it("refuses a caller with no session at all", async () => {
    await expect(
      deleteAccountHandler({ data: {}, rawRequest: { headers: {} } } as never),
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });
});

describe("a partial delete is recorded, never reported as done, and resumes", () => {
  it("records how far it got, fails loudly, and the sweep finishes it", async () => {
    await seedAccount();
    // Firestore falls over on the subtree wipe — after Stripe, the jars, the
    // codes and the quotas are already gone.
    recursiveDeleteFailsUnder = `users/${UID}`;

    await expect(deleteAccountHandler(signedIn())).rejects.toMatchObject({
      code: "internal",
    });

    // NOT reported as done — and the Auth user is still there, which is what
    // lets anyone (the artist, or the sweep) come back at all.
    expect(deleteUser).not.toHaveBeenCalled();
    const ledger = docs.get(`accountDeletions/${UID}`)!;
    expect(ledger["done"]).toEqual(["stripe", "jars", "codes", "quotas"]);
    expect(ledger["attempts"]).toBe(1);
    expect(ledger["lastError"]).toContain("unavailable");
    // The stages that DID run really ran.
    expect(docs.has(`stripeConnections/${CONN}`)).toBe(false);
    expect(docs.has(`jars/${"j".repeat(24)}`)).toBe(false);
    // And the account's data is still there, honestly un-deleted.
    expect(docs.has(`users/${UID}/bands/${BAND}`)).toBe(true);

    // The sweep takes it over — the artist may have no session left to retry
    // with, and a deletion in the ledger is a deletion owed.
    recursiveDeleteFailsUnder = null;
    stripeRequests = [];
    const finished = await resumeAccountDeletions(fakeDb as never, Date.now(), 0);

    expect(finished).toBe(1);
    expect([...docs.keys()].filter((p) => p.startsWith(`users/${UID}`))).toEqual([]);
    expect(deleteUser).toHaveBeenCalledWith(UID);
    expect(docs.has(`accountDeletions/${UID}`)).toBe(false);
    // The finished stages are not redone: no second Stripe round trip.
    expect(stripeRequests).toEqual([]);
  });

  it("a retry from the client resumes the same ledger", async () => {
    await seedAccount();
    recursiveDeleteFailsUnder = `users/${UID}`;
    await expect(deleteAccountHandler(signedIn())).rejects.toThrow();
    const requestedAtMs = docs.get(`accountDeletions/${UID}`)!["requestedAtMs"];

    recursiveDeleteFailsUnder = null;
    const result = await deleteAccountHandler(signedIn());

    expect(result.ok).toBe(true);
    expect(docs.has(`accountDeletions/${UID}`)).toBe(false);
    // Same ledger, resumed — not a second deletion started from scratch.
    expect(requestedAtMs).toBeTypeOf("number");
    expect(deleteUser).toHaveBeenCalledTimes(1);
  });

  it("the sweep leaves a deletion still inside its grace window alone", async () => {
    // A run in flight is not a run that failed: only stale ledgers are taken
    // over, or the sweep would race the callable that wrote it.
    await seedAccount();
    recursiveDeleteFailsUnder = `users/${UID}`;
    await expect(deleteAccountHandler(signedIn())).rejects.toThrow();
    recursiveDeleteFailsUnder = null;

    const finished = await resumeAccountDeletions(fakeDb as never, Date.now(), 10 * 60_000);

    expect(finished).toBe(0);
    expect(docs.has(`accountDeletions/${UID}`)).toBe(true);
    expect(deleteUser).not.toHaveBeenCalled();
  });
});
