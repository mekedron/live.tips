/// The webhook's dedupe beyond delivery, driven through the real handler
/// over an in-memory Firestore stand-in and genuinely signed payloads.
///
/// The failure this pins down (issue #13): dedupe used to live only in the
/// tip doc's id — create() refuses to overwrite — but the queue's contract
/// is delivery-is-deletion. Stripe delivers at-least-once, so an event
/// already answered 200 can come again AFTER the tip was collected; create()
/// then succeeds (nothing left to conflict with) and the fan's one donation
/// takes the stage twice. The fix is the processedEvents tombstone that
/// outlives the queue entry.

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
const tipPath = `users/${UID}/bands/${BAND}/stripeTips/${SESSION}`;
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
  it("first delivery queues the tip AND writes a tombstone that outlasts Stripe's retries", async () => {
    await seedConnection();

    const out = await deliver(checkoutEvent(SESSION, "evt_1"));

    expect(out).toEqual({ status: 200, body: { received: true } });
    expect(docs.has(tipPath)).toBe(true);
    // The tombstone's whole job is outliving the 1h queue entry: its TTL
    // must clear Stripe's documented 3-day retry window.
    const expiresAt = docs.get(tombstonePath)!["expiresAt"] as Timestamp;
    expect(expiresAt.toMillis()).toBeGreaterThan(Date.now() + 3 * 24 * 3_600_000);
  });

  it("a redelivery while the tip still sits in the queue is a duplicate no-op", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    const queued = { ...docs.get(tipPath)! };

    const out = await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(out).toEqual({ status: 200, body: { received: true, duplicate: true } });
    expect(docs.get(tipPath)).toEqual(queued); // untouched — no refreshed TTL
  });

  it("THE regression: a redelivery AFTER the tip was collected does not re-stage it", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    // The device collects the tip: delivery is deletion (the queue's
    // contract). Before the fix, this is exactly where the dedupe died.
    docs.delete(tipPath);

    const out = await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(out).toEqual({ status: 200, body: { received: true, duplicate: true } });
    expect(docs.has(tipPath)).toBe(false); // the fan's one donation stays delivered
  });

  it("a redelivery costs the artist no tip quota", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    docs.delete(tipPath);
    quotaBumps = 0;

    await deliver(checkoutEvent(SESSION, "evt_1_redelivered"));

    expect(quotaBumps).toBe(0);
  });

  it("the tombstone dedupes ONE tip, not the jar: the next tip still lands", async () => {
    await seedConnection();
    await deliver(checkoutEvent(SESSION, "evt_1"));
    docs.delete(tipPath); // collected

    const out = await deliver(checkoutEvent("cs_test_next456", "evt_2"));

    expect(out).toEqual({ status: 200, body: { received: true } });
    expect(docs.has(`users/${UID}/bands/${BAND}/stripeTips/cs_test_next456`)).toBe(true);
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

  it("a redelivered request event is idempotent, even after the tip was collected", async () => {
    await seedConnection({ requestLinks });
    await deliver(checkoutEvent(SESSION, "evt_1", { payment_link: SONG_LINK }));
    docs.delete(tipPath); // collected — delivery is deletion

    const out = await deliver(checkoutEvent(SESSION, "evt_1_redelivered", { payment_link: SONG_LINK }));

    expect(out).toEqual({ status: 200, body: { received: true, duplicate: true } });
    expect(docs.has(tipPath)).toBe(false);
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
