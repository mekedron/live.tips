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
// Module mocks: the REAL store module (constants, and above all the real
// dedupeSignature — the song-request dedupe test below is only worth anything
// against the production hash) behind an in-memory Firestore fake that
// carries the whole POST path: transaction, rate doc, pending-tips batch.

type Doc = Record<string, unknown>;

const bumpQuota = vi.fn<(...args: unknown[]) => Promise<boolean>>();

let jar: Doc | undefined;
let rateDoc: Doc | undefined;
let pendingDocs: Doc[] = [];

const pendingCol = {
  orderBy: () => ({
    select: () => ({ get: async () => ({ size: pendingDocs.length, docs: [] as { ref: unknown }[] }) }),
  }),
  doc: () => ({ pending: true }),
};
const jarDocRef = {
  path: `jars/${"j".repeat(26)}`,
  get: async () => ({ data: () => jar }),
  collection: () => pendingCol,
};
const rateDocRef = { rate: true };

const fakeDb = {
  runTransaction: (fn: (tx: unknown) => Promise<unknown>) =>
    fn({
      getAll: async (...refs: unknown[]) =>
        refs.map((ref) => {
          const data = ref === jarDocRef ? jar : rateDoc;
          return { exists: data !== undefined, data: () => data };
        }),
      update(_ref: unknown, patch: Doc) { Object.assign(jar!, patch); },
      set(ref: unknown, data: Doc) { if (ref === rateDocRef) rateDoc = data; },
    }),
  batch: () => {
    const writes: Doc[] = [];
    return {
      set(ref: unknown, data: Doc) { if ((ref as Doc)["pending"] === true) writes.push(data); },
      delete() {},
      async commit() { pendingDocs.push(...writes); },
    };
  },
};

vi.mock("../src/store", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../src/store")>()),
  db: () => fakeDb,
  jarRef: () => jarDocRef,
  jarRateRef: () => rateDocRef,
  jarIsLive: (doc: unknown) => doc !== undefined,
  bumpQuota: (...args: unknown[]) => bumpQuota(...args),
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

/** A plain relay jar with live counters — enough for the whole POST path. */
function plainJar(): Doc {
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
    lastSeenDay: 0,
    tipsDay: 0,
    tipsToday: 0,
    tipsTotal: 0,
    expiresAt: { untouched: true },
  };
}

/** plainJar plus a published song library and an OPEN request window. */
function requestsJar(): Doc {
  return {
    ...plainJar(),
    requestsConfig: {
      enabled: true,
      defaultPriceMinor: 300,
      methods: ["revolut"],
      songs: [
        { id: "s1", title: "Wonderwall" },
        { id: "s2", title: "Hallelujah", priceMinor: 500 },
        { id: "s3", title: "Yesterday" },
      ],
    },
    requestsLive: { openUntilMs: Date.now() + 3_600_000, updatedAtMs: 0, currency: "eur", songs: {} },
  };
}

/** A POST /t/:jarId/tips as Cloud Run hands it over: the forged entry the
 * attacker sent on the left, the platform-appended chain on the right.
 * `bodyOverrides` replaces the default plain-tip body wholesale when it
 * carries a method of its own. */
function tipPost(xff: string, bodyOverrides: Doc = {}): never {
  const body = {
    method: "revolut", amountMinor: 500, name: "", message: "", turnstileToken: "tok",
    ...bodyOverrides,
  };
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

/** A request-mode body: songId in, amountMinor deliberately OUT. */
function requestBody(overrides: Doc = {}): Doc {
  return {
    method: "revolut", amountMinor: undefined, songId: "s1", name: "Ada", message: "",
    turnstileToken: "tok", ...overrides,
  };
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
  jar = plainJar();
  rateDoc = undefined;
  pendingDocs = [];
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

// ---------------------------------------------------------------------------
// Song requests (#64) on the same POST.

const XFF = `${CLIENT}, ${CDN}`;

function allowThrough() {
  verifyTurnstile.mockResolvedValue(true);
  bumpQuota.mockResolvedValue(true);
}

describe("tip POST: song requests", () => {
  it("prices an accepted request server-side and queues songId + songTitle", async () => {
    jar = requestsJar();
    allowThrough();
    const res = fakeRes();

    // votes × per-song override: 2 × 500, not 2 × 300 and not fan-chosen.
    await tipHandler(tipPost(XFF, requestBody({ songId: "s2", votes: 2 })), res as never);

    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ queued: true });
    expect(pendingDocs).toHaveLength(1);
    expect(pendingDocs[0]).toMatchObject({
      method: "revolut",
      amountMinor: 1000,
      currency: "eur",
      name: "Ada",
      songId: "s2",
      songTitle: "Hallelujah",
    });
    // The deep link carries the computed amount and the title-first note.
    const url = new URL(res.body!["redirectUrl"] as string);
    expect(url.searchParams.get("amount")).toBe("1000");
    expect(url.searchParams.get("note")).toBe("♪ Hallelujah — Ada");
  });

  it("falls back to the default price at one vote", async () => {
    jar = requestsJar();
    allowThrough();
    const res = fakeRes();

    await tipHandler(tipPost(XFF, requestBody()), res as never);

    expect(pendingDocs[0]).toMatchObject({ amountMinor: 300, songId: "s1", songTitle: "Wonderwall" });
  });

  it("is 409 requests_closed when the window has lapsed — before Turnstile spends anything", async () => {
    jar = requestsJar();
    (jar["requestsLive"] as Doc)["openUntilMs"] = Date.now() - 1;
    const res = fakeRes();

    await tipHandler(tipPost(XFF, requestBody()), res as never);

    expect(res.statusCode).toBe(409);
    expect(res.body).toEqual({ error: "requests_closed" });
    // A stale page must not burn the fan's Turnstile solve on a dead sale.
    expect(verifyTurnstile).not.toHaveBeenCalled();
    expect(pendingDocs).toHaveLength(0);
  });

  it("is 409 when requests are configured but disabled, and on a jar with no config at all", async () => {
    jar = requestsJar();
    (jar["requestsConfig"] as Doc)["enabled"] = false;
    const res = fakeRes();
    await tipHandler(tipPost(XFF, requestBody()), res as never);
    expect(res.statusCode).toBe(409);

    jar = plainJar(); // dark until a profile carries config
    const res2 = fakeRes();
    await tipHandler(tipPost(XFF, requestBody()), res2 as never);
    expect(res2.statusCode).toBe(409);
    expect(res2.body).toEqual({ error: "requests_closed" });
  });

  it("rejects an unknown songId with 422", async () => {
    jar = requestsJar();
    allowThrough();
    const res = fakeRes();

    await tipHandler(tipPost(XFF, requestBody({ songId: "nope" })), res as never);

    expect(res.statusCode).toBe(422);
    expect(pendingDocs).toHaveLength(0);
  });

  it("rejects a fan-sent amountMinor alongside songId with 422", async () => {
    jar = requestsJar();
    allowThrough();
    const res = fakeRes();

    await tipHandler(tipPost(XFF, requestBody({ amountMinor: 100 })), res as never);

    expect(res.statusCode).toBe(422);
    expect(pendingDocs).toHaveLength(0);
  });

  it("dedupe: two same-priced requests for DIFFERENT songs both queue", async () => {
    // s1 and s3 both cost the default 300 from the same anonymous fan within
    // the 60s window — identical method/amount/name/message. Without songId
    // in the dedupe signature the second paid request would silently vanish.
    jar = requestsJar();
    allowThrough();

    const first = fakeRes();
    await tipHandler(tipPost(XFF, requestBody({ songId: "s1", name: "" })), first as never);
    const second = fakeRes();
    await tipHandler(tipPost(XFF, requestBody({ songId: "s3", name: "" })), second as never);

    expect(first.body).toMatchObject({ queued: true });
    expect(second.body).toMatchObject({ queued: true });
    expect(pendingDocs).toHaveLength(2);
    expect(pendingDocs.map((d) => d["songId"])).toEqual(["s1", "s3"]);

    // The SAME song twice is still a duplicate: accepted, not re-queued.
    const third = fakeRes();
    await tipHandler(tipPost(XFF, requestBody({ songId: "s3", name: "" })), third as never);
    expect(third.statusCode).toBe(200);
    expect(third.body).toMatchObject({ queued: false });
    expect(pendingDocs).toHaveLength(2);
  });
});

// ---------------------------------------------------------------------------
// GET /t/:jarId/queue — the poll the tip page runs while its section shows.

/** A bare GET as the Hosting rewrite forwards it. */
function getReq(path: string): never {
  return {
    path,
    method: "GET",
    protocol: "https",
    get: () => undefined,
    headers: {},
    socket: { remoteAddress: "169.254.8.129" },
  } as never;
}

/** Like fakeRes, but keeps the raw payload and headers: the 404 comparison
 * below is about BYTES (HTML page vs JSON body), not parsed shapes. */
function rawRes() {
  return {
    statusCode: 0,
    headers: {} as Record<string, string>,
    payload: "",
    status(code: number) { this.statusCode = code; return this; },
    set(h: Record<string, string>) { Object.assign(this.headers, h); return this; },
    send(payload: string) { this.payload = payload; },
  };
}

describe("GET /t/:jarId/queue", () => {
  it("returns the live standings of an open jar, uncacheable", async () => {
    jar = requestsJar();
    (jar["requestsLive"] as Doc)["updatedAtMs"] = 42;
    (jar["requestsLive"] as Doc)["songs"] = {
      s1: { t: 900, c: 3, s: "q" },
      s2: { t: 500, c: 1, s: "p" },
    };
    const res = rawRes();

    await tipHandler(getReq(`/t/${JAR_ID}/queue`), res as never);

    expect(res.statusCode).toBe(200);
    expect(res.headers["Cache-Control"]).toBe("no-store");
    expect(JSON.parse(res.payload)).toEqual({
      open: true,
      currency: "eur",
      updatedAtMs: 42,
      songs: [
        { id: "s1", totalMinor: 900, count: 3, status: "q" },
        { id: "s2", totalMinor: 500, count: 1, status: "p" },
      ],
    });
  });

  it("survives a doc armed open before any queue publish — no songs map at all", async () => {
    // The go-live shape: setJarRequests({open:true}) lands before the leader's
    // first queue push, so requestsLive holds no `songs`. Both readers (page
    // and poll) crashed on this in prod on 2026-07-14; never trust the shape.
    jar = requestsJar();
    delete (jar["requestsLive"] as Doc)["songs"];

    const queue = rawRes();
    await tipHandler(getReq(`/t/${JAR_ID}/queue`), queue as never);
    expect(queue.statusCode).toBe(200);
    expect(JSON.parse(queue.payload)).toEqual({
      open: true,
      currency: "eur",
      updatedAtMs: 0,
      songs: [],
    });

    const page = rawRes();
    await tipHandler(getReq(`/t/${JAR_ID}`), page as never);
    expect(page.statusCode).toBe(200);
    expect(page.payload).toContain("Wonderwall"); // the section renders, standings empty
  });

  it("reports a lapsed window as closed, with no song data", async () => {
    jar = requestsJar();
    (jar["requestsLive"] as Doc)["openUntilMs"] = Date.now() - 1;
    const res = rawRes();

    await tipHandler(getReq(`/t/${JAR_ID}/queue`), res as never);

    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.payload)).toEqual({ open: false, songs: [] });
  });

  it("reports a disabled config — and a jar with none — as the same closed shape", async () => {
    jar = requestsJar();
    (jar["requestsConfig"] as Doc)["enabled"] = false;
    const res = rawRes();
    await tipHandler(getReq(`/t/${JAR_ID}/queue`), res as never);
    expect(JSON.parse(res.payload)).toEqual({ open: false, songs: [] });

    jar = plainJar();
    const res2 = rawRes();
    await tipHandler(getReq(`/t/${JAR_ID}/queue`), res2 as never);
    expect(res2.statusCode).toBe(200);
    expect(JSON.parse(res2.payload)).toEqual({ open: false, songs: [] });
  });

  it("serves the page's own 404 for an unknown jar — no enumeration oracle", async () => {
    jar = undefined;
    const page = rawRes();
    const queue = rawRes();

    await tipHandler(getReq(`/t/${JAR_ID}`), page as never);
    await tipHandler(getReq(`/t/${JAR_ID}/queue`), queue as never);

    expect(queue.statusCode).toBe(404);
    expect(queue.statusCode).toBe(page.statusCode);
    expect(queue.payload).toBe(page.payload); // the identical HTML body
    expect(queue.headers["Content-Type"]).toBe(page.headers["Content-Type"]);
  });

  it("serves that same 404 for a junk jarId, before Firestore is ever asked", async () => {
    const page = rawRes();
    const queue = rawRes();

    await tipHandler(getReq("/t/NOT-A-JAR"), page as never);
    await tipHandler(getReq("/t/NOT-A-JAR/queue"), queue as never);

    expect(queue.statusCode).toBe(404);
    expect(queue.payload).toBe(page.payload);
  });
});

describe("tip POST: plain tips are untouched by the requests feature", () => {
  it("queues a plain tip with no request fields, even while requests are open", async () => {
    jar = requestsJar(); // open window, but this fan just tips
    allowThrough();
    const res = fakeRes();

    await tipHandler(tipPost(XFF, { name: "Ada", message: "great show" }), res as never);

    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ queued: true });
    expect(pendingDocs).toHaveLength(1);
    const doc = pendingDocs[0]!;
    expect(doc).toMatchObject({ method: "revolut", amountMinor: 500, name: "Ada" });
    // Absent KEYS, not undefined values — the pending doc keeps its old shape.
    expect("songId" in doc).toBe(false);
    expect("songTitle" in doc).toBe(false);
    const url = new URL(res.body!["redirectUrl"] as string);
    expect(url.searchParams.get("note")).toBe("Ada: great show");
  });

  it("rejects votes without a songId — the old strict key set still bites", async () => {
    jar = plainJar();
    allowThrough();
    const res = fakeRes();

    await tipHandler(tipPost(XFF, { votes: 3 }), res as never);

    expect(res.statusCode).toBe(422);
  });
});
