/// The tip POST's jar-counter writes and 90-day lifecycle, driven through the
/// real handler with the store and siteverify mocked.
///
/// Two production failures pinned here. First: tipsTotal/tipsToday were a
/// read-modify-write from the jar snapshot taken BEFORE the Turnstile
/// round-trip (hundreds of milliseconds stale) — concurrent tips lost
/// increments, a midnight race mis-reset tipsToday, and a jar deleted inside
/// that window made the batch's update() throw, turning the fan's tip into a
/// 500 with their single-use Turnstile token already spent. The counters now
/// ride the private/rate transaction, computed from its own read. Second:
/// every fan tip stamped lastSeenDay/expiresAt, so anyone could keep an
/// abandoned jar's public URL alive forever; the worker only bumped the
/// 90-day clock while the ARTIST's device was connected, and the tip path
/// now leaves it alone again (jarSeen and the app's daily profile re-push
/// are the keep-alive).

import { beforeEach, describe, expect, it, vi } from "vitest";

// ---------------------------------------------------------------------------
// Module mocks, in the tip.test.ts mold: an in-memory jar behind a fake
// transaction/batch that keeps the two Firestore semantics that matter here —
// a transaction reads SERVER truth (not the handler's earlier snapshot), and
// a batched update() aimed at a missing doc throws the whole commit away.

type Doc = Record<string, unknown>;

let staleJar: Doc | undefined; // what the pre-Turnstile read returned
let serverJar: Doc | undefined; // what the transaction actually finds
let serverRate: Doc | undefined;
let pendingWrites: Doc[] = [];

const pendingCol = {
  orderBy: () => ({
    select: () => ({ get: async () => ({ size: pendingWrites.length, docs: [] as { ref: unknown }[] }) }),
  }),
  doc: () => ({ pending: true }),
};
const jarDocRef = {
  get: async () => ({ data: () => staleJar }),
  collection: () => pendingCol,
};
const rateDocRef = { rate: true };

function fakeTx() {
  return {
    getAll: async (...refs: unknown[]) =>
      refs.map((ref) => {
        const data = ref === jarDocRef ? serverJar : serverRate;
        return { exists: data !== undefined, data: () => data };
      }),
    update(ref: unknown, data: Doc) {
      if (ref !== jarDocRef || serverJar === undefined) throw new Error("5 NOT_FOUND");
      Object.assign(serverJar, data);
    },
    set(ref: unknown, data: Doc) {
      if (ref === rateDocRef) serverRate = data;
    },
  };
}

function fakeBatch() {
  const ops: { op: "set" | "update" | "delete"; ref: unknown; data?: Doc }[] = [];
  return {
    set(ref: unknown, data: Doc) { ops.push({ op: "set", ref, data }); },
    update(ref: unknown, data: Doc) { ops.push({ op: "update", ref, data }); },
    delete(ref: unknown) { ops.push({ op: "delete", ref }); },
    async commit() {
      // Firestore semantics: ONE update() against a missing doc fails the
      // whole batch — the 500 this suite pins as fixed.
      for (const { op, ref } of ops) {
        if (op === "update" && (ref !== jarDocRef || serverJar === undefined)) {
          throw new Error("5 NOT_FOUND: no document to update");
        }
      }
      for (const { op, ref, data } of ops) {
        if (op === "update") Object.assign(serverJar!, data!);
        if (op === "set" && (ref as Doc)["pending"] === true) pendingWrites.push(data!);
      }
    },
  };
}

const firestore = {
  runTransaction: (fn: (tx: ReturnType<typeof fakeTx>) => Promise<unknown>) => fn(fakeTx()),
  batch: () => fakeBatch(),
};

vi.mock("../src/store", () => ({
  DAY_MS: 86_400_000,
  DEDUPE_WINDOW_MS: 60_000,
  MAX_PENDING: 60,
  PENDING_TTL_MS: 60 * 60_000,
  TIPS_PER_HOUR: 60,
  TIPS_PER_IP_PER_HOUR: 120,
  TIPS_PER_MINUTE: 6,
  bumpQuota: async () => true,
  db: () => firestore,
  dedupeSignature: (tip: unknown) => JSON.stringify(tip),
  jarIsLive: (doc: unknown) => doc !== undefined,
  jarRateRef: () => rateDocRef,
  jarRef: () => jarDocRef,
}));

vi.mock("../src/params", () => ({
  IP_HASH_SALT: { value: () => "test-salt" },
  TURNSTILE_SECRET: { value: () => "test-secret" },
  TURNSTILE_SITE_KEY: { value: () => "test-sitekey" },
}));

vi.mock("../src/turnstile", () => ({
  verifyTurnstile: async () => true,
}));

import { tipHandler } from "../src/tip";

// ---------------------------------------------------------------------------

const JAR_ID = "j".repeat(26); // valid jarId shape
const DAY_MS = 86_400_000;
const today = () => Math.floor(Date.now() / DAY_MS);

// A sentinel by REFERENCE: the lifecycle assertion is that the tip path
// never replaces it.
const EXPIRES_SENTINEL = { untouched: true };

function jarDoc(overrides: Doc = {}): Doc {
  return {
    profile: {
      artistName: "Ana",
      message: "",
      currency: "eur",
      methods: { revolutUsername: "ana" },
    },
    ownerUid: null,
    readerUids: [],
    createdAtMs: 0,
    lastSeenDay: today() - 40,
    tipsDay: today(),
    tipsToday: 2,
    tipsTotal: 5,
    expiresAt: EXPIRES_SENTINEL,
    ...overrides,
  };
}

/** A POST /t/:jarId/tips as Cloud Run hands it over (client, then the
 * Hosting hop). `overrides` varies the body so dedupe stays out of the way. */
function tipPost(overrides: Doc = {}): never {
  const body = {
    method: "revolut", amountMinor: 500, name: "", message: "", turnstileToken: "tok",
    ...overrides,
  };
  return {
    path: `/t/${JAR_ID}/tips`,
    method: "POST",
    protocol: "https",
    get: (header: string) => (header === "host" ? "tip.live.tips" : undefined),
    rawBody: Buffer.from(JSON.stringify(body)),
    headers: { "x-forwarded-for": "203.0.113.9, 216.239.36.53" },
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
  staleJar = undefined;
  serverJar = undefined;
  serverRate = undefined;
  pendingWrites = [];
});

describe("tip POST: counters ride the transaction, not the stale snapshot", () => {
  it("increments the transaction's read — tips landing during the Turnstile round-trip are not lost", async () => {
    staleJar = jarDoc(); // tipsTotal 5, as read before Turnstile
    serverJar = jarDoc({ tipsTotal: 7, tipsToday: 4 }); // two more landed since
    const res = fakeRes();

    await tipHandler(tipPost(), res as never);

    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ queued: true });
    expect(serverJar!["tipsTotal"]).toBe(8); // 7+1, not the stale 5+1
    expect(serverJar!["tipsToday"]).toBe(5);
    expect(pendingWrites).toHaveLength(1);
  });

  it("back-to-back tips both land", async () => {
    staleJar = jarDoc();
    serverJar = jarDoc();

    await tipHandler(tipPost({ message: "hi" }), fakeRes() as never);
    await tipHandler(tipPost({ message: "yo" }), fakeRes() as never);

    expect(serverJar!["tipsTotal"]).toBe(7);
    expect(serverJar!["tipsToday"]).toBe(4);
  });

  it("a snapshot from before midnight cannot mis-reset tipsToday", async () => {
    staleJar = jarDoc({ tipsDay: today() - 1, tipsToday: 9 }); // read yesterday
    serverJar = jarDoc({ tipsDay: today(), tipsToday: 4 }); // it is today now
    const res = fakeRes();

    await tipHandler(tipPost(), res as never);

    expect(serverJar!["tipsToday"]).toBe(5); // not reset to 1
    expect(serverJar!["tipsDay"]).toBe(today());
  });

  it("a new day starts the counter over, from the transactional read", async () => {
    staleJar = jarDoc();
    serverJar = jarDoc({ tipsDay: today() - 1, tipsToday: 9 });
    const res = fakeRes();

    await tipHandler(tipPost(), res as never);

    expect(serverJar!["tipsToday"]).toBe(1);
    expect(serverJar!["tipsDay"]).toBe(today());
    expect(serverJar!["tipsTotal"]).toBe(6);
  });

  it("a jar deleted between the read and the commit answers 200, not 500", async () => {
    staleJar = jarDoc(); // alive when the handler first looked
    serverJar = undefined; // gone by the time the transaction runs
    const res = fakeRes();

    await tipHandler(tipPost(), res as never);

    // The fan's Turnstile token is already spent: they still get their
    // payment link, just nothing is queued or counted.
    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ queued: false });
    expect(typeof res.body!["redirectUrl"]).toBe("string");
    // And nothing is resurrected under the deleted jar.
    expect(serverRate).toBeUndefined();
    expect(pendingWrites).toHaveLength(0);
  });
});

describe("tip POST: a fan tip is not artist activity", () => {
  it("bumps the counters but never lastSeenDay/expiresAt — strangers cannot keep an abandoned jar alive", async () => {
    staleJar = jarDoc();
    serverJar = jarDoc();
    const res = fakeRes();

    await tipHandler(tipPost(), res as never);

    expect(res.body).toMatchObject({ queued: true });
    expect(serverJar!["tipsTotal"]).toBe(6);
    expect(serverJar!["lastSeenDay"]).toBe(today() - 40);
    expect(serverJar!["expiresAt"]).toBe(EXPIRES_SENTINEL);
  });
});
