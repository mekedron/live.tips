/// The webhook's dedupe and destination routing, driven through the real
/// handler over an in-memory Firestore stand-in and genuinely signed
/// payloads.
///
/// Two eras pinned here. Issue #13: dedupe used to live only in the tip
/// doc's id — create() refuses to overwrite — but Stripe delivers
/// at-least-once and an event already answered 200 can come again later;
/// the processedEvents tombstone is what answers it. Issue #71: the
/// stripeTips consume-once queue is dead — mapped tips go through the
/// shared destination router (tip-destination.ts) straight into the
/// account: the live session's tips subcollection while a set runs for the
/// band, the relayTips archive otherwise. The tombstone matters MORE now:
/// where a tip lands moves with the set, so a redelivery after the session
/// ended would land in the OTHER collection if only create() guarded it.

import { createHmac } from "node:crypto";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { Timestamp } from "firebase-admin/firestore";
import { sealSecret } from "../src/stripe-crypto";

// ---------------------------------------------------------------------------
// Module mocks, stripe-connect.test.ts style: ./store's Admin SDK and KMS are
// replaced by in-memory stand-ins. Values the handler under test never
// touches are absent on purpose (a call would fail loudly).

/** path → doc data. Reset per test. */
const docs = new Map<string, Record<string, unknown>>();

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

function colRef(path: string) {
  return {
    doc: (id: string) => docRef(`${path}/${id}`),
    // The one query the handler runs: the overflow scan over stripeTips.
    orderBy: (_field: string) => ({
      select: () => ({
        get: async () => {
          const hits = [...docs.keys()]
            .filter((p) => p.startsWith(`${path}/`) && !p.slice(path.length + 1).includes("/"))
            .map((p) => ({ ref: docRef(p) }));
          return { size: hits.length, docs: hits };
        },
      }),
    }),
  };
}

const fakeDb = {
  collection: (name: string) => colRef(name),
  batch: () => {
    // Buffered like the real thing: nothing lands until commit().
    const ops: (() => void)[] = [];
    return {
      create: (ref: { path: string }, doc: Record<string, unknown>) =>
        ops.push(() => {
          // The Admin SDK's ALREADY_EXISTS — the code the handler matches on.
          if (docs.has(ref.path)) throw Object.assign(new Error(`create on existing ${ref.path}`), { code: 6 });
          docs.set(ref.path, { ...doc });
        }),
      set: (ref: { path: string }, data: Record<string, unknown>) =>
        ops.push(() => docs.set(ref.path, { ...data })),
      delete: (ref: { path: string }) => ops.push(() => docs.delete(ref.path)),
      commit: async () => {
        for (const op of ops) op();
      },
    };
  },
};

/** How many times the handler reached for the flood valve. */
let quotaBumps = 0;

vi.mock("../src/store", () => ({
  db: () => fakeDb,
  bumpQuota: async () => {
    quotaBumps += 1;
    return true;
  },
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

import { stripeWebhookHandler } from "../src/stripe-webhook";

// ---------------------------------------------------------------------------

const UID = "uid_artist";
const BAND = "acc_m3k9zq1a2b3c";
const CONN = "d".repeat(22); // valid jarId shape (lowercase base36)
const SECRET = "whsec_9f8e7d6c5b4a39281706f5e4d3c2b1a0";
const OUR_LINK = "plink_1OurTipJarLink";

const SONG_LINK = "plink_1SongRequestLink";

const SESSION = "cs_test_abc123";
const LIVE_SESSION = "sess_tonight";
/** Off-session (or dead-lease) destination: the band's durable archive. */
const tipPath = `users/${UID}/bands/${BAND}/relayTips/${SESSION}`;
/** In-session destination: the running set's own tips subcollection. */
const liveTipPath = `users/${UID}/bands/${BAND}/sessions/${LIVE_SESSION}/tips/${SESSION}`;
/** The dead queue (#71): nothing may ever land here again. */
const queuePath = `users/${UID}/bands/${BAND}/stripeTips/${SESSION}`;
const tombstonePath = `processedEvents/${SESSION}`;

async function seedConnection(extra: Record<string, unknown> = {}) {
  // Only what the webhook reads: no restricted key on purpose.
  docs.set(`stripeConnections/${CONN}`, {
    uid: UID,
    bandId: BAND,
    webhookSecret: await sealSecret(SECRET, testWrapper),
    paymentLinkId: OUR_LINK,
    ...extra,
  });
}

/** A running set: live/current as the app's claim transaction writes it. */
function seedLiveSession(overrides: Record<string, unknown> = {}) {
  docs.set(`users/${UID}/live/current`, {
    active: true,
    bandId: BAND,
    sessionId: LIVE_SESSION,
    leaderDeviceId: "device_a",
    leaderLeaseUntilMs: Date.now() + 45_000,
    ...overrides,
  });
}

/** A paid checkout session against OUR link — the QR tip shape. Stripe may
 * redeliver it under a fresh evt_ id; the object id is what dedupes. */
function checkoutEvent(sessionId: string, eventId: string, overrides: Record<string, unknown> = {}): string {
  return JSON.stringify({
    id: eventId,
    type: "checkout.session.completed",
    data: {
      object: {
        id: sessionId,
        object: "checkout.session",
        amount_total: 1500,
        currency: "eur",
        created: Math.floor(Date.now() / 1000),
        livemode: true,
        payment_status: "paid",
        payment_link: OUR_LINK,
        payment_intent: "pi_123",
        customer_details: { name: "Card Holder", email: "fan@example.com" },
        custom_fields: [{ key: "nickname", text: { value: "Maya" } }],
        ...overrides,
      },
    },
  });
}

function sign(payload: string): string {
  const t = Math.floor(Date.now() / 1000);
  const v1 = createHmac("sha256", SECRET).update(`${t}.${payload}`, "utf8").digest("hex");
  return `t=${t},v1=${v1}`;
}

/** One delivery through the real handler; returns what it answered. */
async function deliver(payload: string): Promise<{ status: number; body: Record<string, unknown> }> {
  const req = {
    method: "POST",
    path: `/stripe/webhook/${CONN}`,
    rawBody: Buffer.from(payload, "utf8"),
    get: (name: string) => (name === "Stripe-Signature" ? sign(payload) : undefined),
  };
  const out = { status: 0, body: {} as Record<string, unknown> };
  const res = {
    status: (code: number) => {
      out.status = code;
      return res;
    },
    set: () => res,
    json: (body: Record<string, unknown>) => {
      out.body = body;
    },
  };
  await stripeWebhookHandler(req as never, res as never);
  return out;
}

beforeEach(() => {
  docs.clear();
  quotaBumps = 0;
});

describe("stripeWebhook: dedupe must outlive the delivered tip", () => {
  it("first delivery writes the tip AND a tombstone that outlasts Stripe's retries", async () => {
    await seedConnection();

    const out = await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(out).toEqual({ status: 200, body: { received: true } });
    expect(docs.has(tipPath)).toBe(true);
    // The tombstone's whole job is answering long after the delivery: its
    // TTL must clear Stripe's documented 3-day retry window.
    const expiresAt = docs.get(tombstonePath)!["expiresAt"] as Timestamp;
    expect(expiresAt.toMillis()).toBeGreaterThan(Date.now() + 3 * 24 * 3_600_000);
  });

  it("a redelivery is a duplicate no-op that leaves the tip untouched", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    const written = { ...docs.get(tipPath)! };

    const out = await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(out).toEqual({ status: 200, body: { received: true, duplicate: true } });
    expect(docs.get(tipPath)).toEqual(written); // no refreshed updatedAtMs
  });

  it("THE #71 regression shape: a redelivery after a set STARTS does not land the same money twice", async () => {
    // The destination moves with the set, so create()'s per-doc idempotency
    // cannot answer a late redelivery — only the tombstone can: first
    // delivery lands off-session in relayTips, then a set starts, then
    // Stripe re-sends. Without the tombstone the session subcollection
    // would receive a second copy under the same object id.
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    expect(docs.has(tipPath)).toBe(true);
    seedLiveSession();

    const out = await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(out).toEqual({ status: 200, body: { received: true, duplicate: true } });
    expect(docs.has(liveTipPath)).toBe(false); // the fan's one donation stays one doc
  });

  it("a redelivery costs the artist no tip quota", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    quotaBumps = 0;

    await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(quotaBumps).toBe(0);
  });

  it("the tombstone dedupes ONE tip, not the jar: the next tip still lands", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));

    const out = await deliver(checkoutEvent("cs_test_next456", "evt_2"));

    expect(out).toEqual({ status: 200, body: { received: true } });
    expect(docs.has(`users/${UID}/bands/${BAND}/relayTips/cs_test_next456`)).toBe(true);
  });
});

describe("stripeWebhook: the bell feed rides the tombstone batch", () => {
  const notePath = `users/${UID}/notifications/${SESSION}`;

  it("an off-session delivery writes the notification in the SAME commit as the tip", async () => {
    await seedConnection();

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.get(notePath)).toEqual({
      kind: "tip",
      bandId: BAND,
      tipId: SESSION,
      amountMinor: 1500,
      currency: "eur",
      name: "Maya",
      createdAtMs: expect.any(Number) as number,
    });
  });

  it("a tip landing on a running set writes NO notification — the stage showed it", async () => {
    await seedConnection();
    seedLiveSession();

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.has(liveTipPath)).toBe(true);
    expect(docs.has(notePath)).toBe(false);
  });

  it("a redelivery answered by the tombstone rings no second bell", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    const written = { ...docs.get(notePath)! };

    await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(docs.get(notePath)).toEqual(written);
  });
});

// ---------------------------------------------------------------------------
// Destination routing (#71): the same router the relay POST uses.

/** A card-present tap — the in-person Charge shape the webhook accepts. */
function chargeEvent(chargeId: string, eventId: string): string {
  return JSON.stringify({
    id: eventId,
    type: "charge.succeeded",
    data: {
      object: {
        id: chargeId,
        object: "charge",
        amount: 700,
        currency: "eur",
        created: Math.floor(Date.now() / 1000),
        livemode: true,
        status: "succeeded",
        paid: true,
        payment_method_details: { type: "card_present" },
        payment_intent: "pi_tap1",
      },
    },
  });
}

describe("stripeWebhook: tips land in the account, never the stripeTips queue (#71)", () => {
  it("a set running for the band captures the tip into its tips subcollection", async () => {
    await seedConnection();
    seedLiveSession();

    const out = await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(out).toEqual({ status: 200, body: { received: true } });
    expect(docs.has(liveTipPath)).toBe(true);
    expect(docs.has(tipPath)).toBe(false);
  });

  it("no set running: the tip waits durably in the band's relayTips archive", async () => {
    await seedConnection();

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.has(tipPath)).toBe(true);
    expect(docs.has(liveTipPath)).toBe(false);
  });

  it("a lease dead past the app's staleMs routes off-session — active:true alone is a lie", async () => {
    await seedConnection();
    seedLiveSession({ leaderLeaseUntilMs: Date.now() - 2 * 60_000 });

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.has(tipPath)).toBe(true);
    expect(docs.has(liveTipPath)).toBe(false);
  });

  it("a lease merely EXPIRED but within staleMs still counts as running — money flows through the takeover window", async () => {
    await seedConnection();
    seedLiveSession({ leaderLeaseUntilMs: Date.now() - 60_000 }); // dead leader, no takeover yet

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.has(liveTipPath)).toBe(true);
  });

  it("a cleanly stopped session (active:false) does not capture tips into a finished set", async () => {
    await seedConnection();
    seedLiveSession({ active: false });

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.has(tipPath)).toBe(true);
    expect(docs.has(liveTipPath)).toBe(false);
  });

  it("a live set for ANOTHER band of the same account does not capture this band's tips", async () => {
    await seedConnection();
    seedLiveSession({ bandId: "acc_other_band" });

    await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(docs.has(tipPath)).toBe(true);
    expect([...docs.keys()].some((p) => p.includes("/sessions/"))).toBe(false);
  });

  it("NOTHING is ever written to stripeTips again — the queue is dead", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    seedLiveSession();
    await deliver(checkoutEvent("cs_test_next456", "evt_2"));

    expect([...docs.keys()].some((p) => p.includes("/stripeTips/"))).toBe(false);
    expect(docs.has(queuePath)).toBe(false);
  });
});

describe("stripeWebhook: the wire shape is the app's own Tip.toJson", () => {
  it("a donation is written exactly as the leader would publish it — verified/method/inPerson OMITTED", async () => {
    await seedConnection();
    const payload = checkoutEvent(SESSION, "evt_1");
    const created = (JSON.parse(payload) as { data: { object: { created: number } } }).data.object.created;

    await deliver(payload);

    // toEqual, not toMatchObject: absent keys are the contract. `verified`
    // and `method` are Tip's DEFAULTS (true / stripe) and Tip.toJson omits
    // them; a `verified: true` key here would break byte-identity with
    // app-written history. No expiresAt: this is history, nothing sweeps it.
    expect(docs.get(tipPath)).toEqual({
      id: SESSION,
      amountMinor: 1500,
      currency: "eur",
      createdAt: created * 1000,
      name: "Maya",
      livemode: true,
      viaService: true,
      paymentIntentId: "pi_123",
      updatedAtMs: expect.any(Number) as number,
    });
  });

  it("an in-person tap carries inPerson:true and stays nameless", async () => {
    await seedConnection();
    seedLiveSession();
    const payload = chargeEvent("ch_tap_1", "evt_tap");
    const created = (JSON.parse(payload) as { data: { object: { created: number } } }).data.object.created;

    await deliver(payload);

    expect(docs.get(`users/${UID}/bands/${BAND}/sessions/${LIVE_SESSION}/tips/ch_tap_1`)).toEqual({
      id: "ch_tap_1",
      amountMinor: 700,
      currency: "eur",
      createdAt: created * 1000,
      livemode: true,
      viaService: true,
      paymentIntentId: "pi_tap1",
      inPerson: true,
      updatedAtMs: expect.any(Number) as number,
    });
  });
});

describe("stripeWebhook: song-request links (issue #64)", () => {
  const requestLinks = { [SONG_LINK]: { songId: "song_wonderwall", title: "Wonderwall" } };

  it("a paid session through a mapped song link lands as a tip WITH songId/songTitle", async () => {
    await seedConnection({ requestLinks });

    // 4 votes × 5.00 EUR: amount_total arrives already multiplied.
    const out = await deliver(checkoutEvent(SESSION, "evt_1", { payment_link: SONG_LINK, amount_total: 2000 }));

    expect(out).toEqual({ status: 200, body: { received: true } });
    const tip = docs.get(tipPath)!;
    expect(tip["songId"]).toBe("song_wonderwall");
    expect(tip["songTitle"]).toBe("Wonderwall");
    expect(tip["amountMinor"]).toBe(2000);
    expect(tip["name"]).toBe("Maya");
    expect(docs.has(tombstonePath)).toBe(true);
  });

  it("a redelivered request event is idempotent — even into a set that started in between", async () => {
    await seedConnection({ requestLinks });
    await deliver(checkoutEvent(SESSION, "evt_1", { payment_link: SONG_LINK }));
    seedLiveSession(); // the destination has moved; the tombstone still answers

    const out = await deliver(checkoutEvent(SESSION, "evt_1_redelivered", { payment_link: SONG_LINK }));

    expect(out).toEqual({ status: 200, body: { received: true, duplicate: true } });
    expect(docs.has(liveTipPath)).toBe(false);
  });

  it("a donation stays a donation: no song fields leak onto the tip-jar path", async () => {
    await seedConnection({ requestLinks });

    const out = await deliver(checkoutEvent(SESSION, "evt_1")); // OUR_LINK, the jar

    expect(out).toEqual({ status: 200, body: { received: true } });
    const tip = docs.get(tipPath)!;
    expect("songId" in tip).toBe(false);
    expect("songTitle" in tip).toBe(false);
    expect(tip["amountMinor"]).toBe(1500);
  });

  it("an UNMAPPED foreign link is acknowledged and NOT stored — the gate holds", async () => {
    await seedConnection({ requestLinks });

    const out = await deliver(checkoutEvent(SESSION, "evt_1", { payment_link: "plink_SomethingElse" }));

    expect(out).toEqual({ status: 200, body: { received: true, tip: false } });
    expect(docs.has(tipPath)).toBe(false);
    expect(docs.has(tombstonePath)).toBe(false);
  });

  it("a connection without requestLinks (pre-#64 doc) behaves exactly as before", async () => {
    await seedConnection(); // no requestLinks field at all

    const request = await deliver(checkoutEvent(SESSION, "evt_1", { payment_link: SONG_LINK }));
    expect(request).toEqual({ status: 200, body: { received: true, tip: false } });

    const donation = await deliver(checkoutEvent("cs_test_next456", "evt_2"));
    expect(donation).toEqual({ status: 200, body: { received: true } });
  });
});
