/// The revocation watermark on the jar-mutation callables (#61). The kill
/// switch ("Sign out everywhere else") stamps sessionsValidAfterMs, but onCall
/// still accepts a stolen ID token for up to ~1h; without an app-level check a
/// revoked session could call updateJarProfile and swap the payout methods to
/// a thief's — fans then pay the thief. updateJarProfile / deleteJar / jarSeen
/// gate the OWNER-uid path on requireFreshSession; a caller who presents the
/// jar SECRET holds the root credential and is exempt.
///
/// The blind spot this widens: the jar handlers had no test that modelled a
/// revoked owner still holding a live token — fake_cloud_firestore returns "no
/// watermark" and FakeCallables carries no auth_time, so "owner uid is enough"
/// read as correct everywhere. These tests carry a real watermark and a real
/// auth_time over an in-memory Firestore, the two axes that were missing.

import { beforeEach, describe, expect, it, vi } from "vitest";
import { sha256Hex } from "../src/auth";

// ---------------------------------------------------------------------------
// In-memory Firestore, in the revocation.test.ts mould but for the jar refs:
// getAll for authorizeJar's two-doc read, an update() on the jar ref, a
// recursiveDelete for purgeJar, and securityRef for requireFreshSession.

/** path → doc data. Reset per test. */
const docs = new Map<string, Record<string, unknown>>();

function fakeSnap(path: string) {
  const data = docs.get(path);
  return {
    exists: data !== undefined,
    data: () => (data === undefined ? undefined : { ...data }),
    get: (field: string) => data?.[field],
  };
}

const fakeDb = {
  getAll: async (...refs: { path: string }[]) => refs.map((r) => fakeSnap(r.path)),
  recursiveDelete: async (ref: { path: string }) => {
    for (const key of [...docs.keys()]) {
      if (key === ref.path || key.startsWith(`${ref.path}/`)) docs.delete(key);
    }
  },
};

function jarRef(_db: unknown, jarId: string) {
  const path = `jars/${jarId}`;
  return {
    path,
    update: async (patch: Record<string, unknown>) => {
      const doc = docs.get(path);
      if (doc === undefined) throw new Error(`update on missing ${path}`);
      Object.assign(doc, patch);
    },
  };
}

vi.mock("../src/store", () => ({
  db: () => fakeDb,
  jarRef,
  jarAuthRef: (_db: unknown, jarId: string) => ({ path: `jars/${jarId}/private/auth` }),
  securityRef: (_db: unknown, uid: string) => ({
    path: `users/${uid}/private/security`,
    get: async () => fakeSnap(`users/${uid}/private/security`),
  }),
  expiryTimestamp: (now: number) => ({ expiresAtMs: now + 90 * 86_400_000 }),
  DAY_MS: 86_400_000,
}));

vi.mock("../src/params", () => ({
  IP_HASH_SALT: { value: () => "test-salt" },
}));

import {
  deleteJarHandler,
  jarSeenHandler,
  updateJarProfileHandler,
} from "../src/jars";

// ---------------------------------------------------------------------------

const OWNER = "uid_owner";
const JAR_ID = "j".repeat(26); // valid jarId shape
const SECRET = "s".repeat(40);
const DAY_MS = 86_400_000;

const PROFILE = {
  artistName: "Ana",
  message: "",
  currency: "eur",
  methods: { revolutUsername: "ana" },
};

// The payload the thief would send: the SAME jar, the attacker's Revolut.
const THIEF_PROFILE = {
  artistName: "Ana",
  message: "",
  currency: "eur",
  methods: { revolutUsername: "attacker" },
};

/** A signed-in callable request. auth_time is seconds; omit for none. */
function signedIn(
  uid: string,
  data: Record<string, unknown>,
  authTimeSec?: number,
): never {
  return {
    auth: { uid, token: { auth_time: authTimeSec } },
    data,
    rawRequest: {},
  } as never;
}

const nowSec = () => Math.floor(Date.now() / 1000);

/** An owned relay jar (ownerUid set) plus its secret hash. */
function seedOwnedJar(overrides: Record<string, unknown> = {}) {
  docs.set(`jars/${JAR_ID}`, {
    profile: PROFILE,
    ownerUid: OWNER,
    readerUids: [OWNER],
    createdAtMs: 0,
    lastSeenDay: Math.floor(Date.now() / DAY_MS) - 40,
    tipsDay: Math.floor(Date.now() / DAY_MS),
    tipsToday: 0,
    tipsTotal: 0,
    expiresAt: { untouched: true },
    ...overrides,
  });
  docs.set(`jars/${JAR_ID}/private/auth`, { secretHash: sha256Hex(SECRET) });
}

/** Stamp the kill switch: a watermark in the future relative to any nowSec(). */
function revoke(uid = OWNER) {
  docs.set(`users/${uid}/private/security`, { sessionsValidAfterMs: Date.now() + 60_000 });
}

beforeEach(() => {
  docs.clear();
});

// ---------------------------------------------------------------------------
// updateJarProfile — the money-redirection surface.

describe("updateJarProfile honours the revocation watermark on the owner path", () => {
  it("a revoked owner-uid session cannot swap the payout methods", async () => {
    seedOwnedJar();
    revoke();

    await expect(
      updateJarProfileHandler(signedIn(OWNER, { jarId: JAR_ID, profile: THIEF_PROFILE }, nowSec())),
    ).rejects.toMatchObject({ code: "unauthenticated" });

    // The jar still points at the artist, not the attacker.
    expect((docs.get(`jars/${JAR_ID}`)!["profile"] as typeof PROFILE).methods)
      .toEqual({ revolutUsername: "ana" });
  });

  it("a fresh owner-uid session (auth_time past the watermark) may update", async () => {
    seedOwnedJar();
    docs.set(`users/${OWNER}/private/security`, { sessionsValidAfterMs: Date.now() - 60_000 });

    await updateJarProfileHandler(
      signedIn(OWNER, { jarId: JAR_ID, profile: PROFILE }, nowSec()),
    );

    expect((docs.get(`jars/${JAR_ID}`)!["profile"] as typeof PROFILE).methods)
      .toEqual({ revolutUsername: "ana" });
  });

  it("an owner-uid session with no watermark (never revoked) may update", async () => {
    // A local/guest-owned jar, or any account that never pulled the switch:
    // requireFreshSession returns early, so nothing is gated.
    seedOwnedJar();

    await updateJarProfileHandler(
      signedIn(OWNER, { jarId: JAR_ID, profile: PROFILE }),
    );

    expect(docs.get(`jars/${JAR_ID}`)!["lastSeenDay"]).toBe(Math.floor(Date.now() / DAY_MS));
  });

  it("the jar SECRET bypasses the watermark — it is a separate root credential",
    async () => {
      // A revoked session that ALSO holds the secret is presenting the root
      // credential, not just the session, and must be let through.
      seedOwnedJar();
      revoke();

      await updateJarProfileHandler(
        signedIn(OWNER, { jarId: JAR_ID, profile: PROFILE, secret: SECRET }, nowSec()),
      );

      expect((docs.get(`jars/${JAR_ID}`)!["profile"] as typeof PROFILE).methods)
        .toEqual({ revolutUsername: "ana" });
    });
});

// ---------------------------------------------------------------------------
// deleteJar — the defacement surface.

describe("deleteJar honours the revocation watermark on the owner path", () => {
  it("a revoked owner-uid session cannot delete the tip pages", async () => {
    seedOwnedJar();
    revoke();

    await expect(
      deleteJarHandler(signedIn(OWNER, { jarId: JAR_ID }, nowSec())),
    ).rejects.toMatchObject({ code: "unauthenticated" });

    expect(docs.has(`jars/${JAR_ID}`)).toBe(true);
  });

  it("a revoked session holding the secret may delete", async () => {
    seedOwnedJar();
    revoke();

    await deleteJarHandler(signedIn(OWNER, { jarId: JAR_ID, secret: SECRET }, nowSec()));

    expect(docs.has(`jars/${JAR_ID}`)).toBe(false);
    expect(docs.has(`jars/${JAR_ID}/private/auth`)).toBe(false);
  });

  it("an owner with no watermark may delete", async () => {
    seedOwnedJar();

    await deleteJarHandler(signedIn(OWNER, { jarId: JAR_ID }));

    expect(docs.has(`jars/${JAR_ID}`)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// jarSeen — the keep-alive surface (lowest value, gated for consistency).

describe("jarSeen honours the revocation watermark on the owner path", () => {
  it("a revoked owner-uid session cannot bump the keep-alive clock", async () => {
    seedOwnedJar({ lastSeenDay: Math.floor(Date.now() / DAY_MS) - 40 });
    revoke();

    await expect(
      jarSeenHandler(signedIn(OWNER, { jarId: JAR_ID }, nowSec())),
    ).rejects.toMatchObject({ code: "unauthenticated" });

    expect(docs.get(`jars/${JAR_ID}`)!["lastSeenDay"]).toBe(Math.floor(Date.now() / DAY_MS) - 40);
  });

  it("a fresh owner may bump the keep-alive clock", async () => {
    seedOwnedJar({ lastSeenDay: Math.floor(Date.now() / DAY_MS) - 40 });

    await jarSeenHandler(signedIn(OWNER, { jarId: JAR_ID }, nowSec()));

    expect(docs.get(`jars/${JAR_ID}`)!["lastSeenDay"]).toBe(Math.floor(Date.now() / DAY_MS));
  });
});
