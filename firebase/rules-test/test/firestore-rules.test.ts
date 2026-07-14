/**
 * The Firestore rules perimeter (issue #60).
 *
 * The Flutter app talks to Firestore directly, so `firebase/firestore.rules`
 * is the ENTIRE authorization boundary. The Flutter and functions suites run
 * on fake_cloud_firestore, which enforces no rules — so a rule that opens a
 * door ships green. This suite loads the REAL rules file against the Firestore
 * emulator and proves the perimeter, denial by denial.
 *
 * The value is in the denials: `assertFails` is the guard, `assertSucceeds`
 * only proves the door the owner needs is not welded shut. When you edit
 * firestore.rules, this is the net that catches a regression before CI's
 * `--force` deploy ships it.
 *
 * Run:  cd firebase/rules-test && npm test
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestContext,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  type Firestore,
} from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

// The two artists whose separation is the whole game. UID_A owns everything
// seeded below; UID_B is a different signed-in artist — every one of B's
// reaches into A's tree must fail.
const UID_A = "artist_a";
const UID_B = "artist_b";
// The anonymous uid the relay signs in as for a no-account artist. It is a
// real (authenticated) principal, but only ever a jar reader.
const UID_RELAY = "relay_anon_uid";

// Paths under A's tree. Kept as constants so the subcollection coverage is
// legible at a glance — the classic miss is guarding the parent and forgetting
// a child, so every subtree the rules name explicitly is listed here.
const A_ROOT = `users/${UID_A}`;
const A_BAND = `users/${UID_A}/bands/band1`;
const A_BAND_SECRET = `users/${UID_A}/bands/band1/secrets/v1`;
const A_SESSION_TIP = `users/${UID_A}/bands/band1/sessions/sess1/tips/tip1`;
const A_RELAY_TIP = `users/${UID_A}/bands/band1/relayTips/rt1`;
const A_STRIPE_TIP = `users/${UID_A}/bands/band1/stripeTips/st1`;
const A_SETTINGS = `users/${UID_A}/settings/app`;
const A_LIVE = `users/${UID_A}/live/current`;
const A_DEVICE = `users/${UID_A}/devices/dev1`;
const A_PRIVATE_SECURITY = `users/${UID_A}/private/security`;
const A_PRIVATE_STRIPE = `users/${UID_A}/private/stripe`;

// Top-level collections.
const JAR = "jars/jar1";
const JAR_PENDING_TIP = "jars/jar1/pendingTips/pt1";
const JAR_PRIVATE = "jars/jar1/private/auth";
const LINK_CODE = "linkCodes/lc1";
const RATE_LIMIT = "rateLimits/salted-hash";
const ACCOUNT_DELETION = `accountDeletions/${UID_A}`;
const STRIPE_CONNECTION = "stripeConnections/conn1";
const PROCESSED_EVENT = "processedEvents/evt_1";

let testEnv: RulesTestEnvironment;

/** A signed-in artist context, optionally with a chosen auth_time (seconds). */
function authed(uid: string, authTimeSec?: number): Firestore {
  const ctx: RulesTestContext =
    authTimeSec === undefined
      ? testEnv.authenticatedContext(uid)
      : testEnv.authenticatedContext(uid, { auth_time: authTimeSec });
  // rules-unit-testing declares firestore() as the compat type but returns a
  // modular Firestore at runtime (its own docs pass it to modular doc()/get()).
  return ctx.firestore() as unknown as Firestore;
}

/** An unauthenticated (no request.auth) context. */
function anon(): Firestore {
  return testEnv.unauthenticatedContext().firestore() as unknown as Firestore;
}

/** Seed a document past the rules (the server's job in production). */
async function seed(path: string, data: Record<string, unknown>): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

beforeAll(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080";
  const [hostname, port] = host.split(":");
  testEnv = await initializeTestEnvironment({
    projectId: "demo-livetips-rules",
    firestore: {
      // Load the REAL perimeter, not a copy. This path is the whole point.
      rules: readFileSync(resolve(process.cwd(), "../firestore.rules"), "utf8"),
      host: hostname,
      port: Number(port),
    },
  });
});

afterAll(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("cross-account isolation: artist B is locked out of artist A's tree", () => {
  it("denies B read on every A subtree the rules name (parent AND children)", async () => {
    const db = authed(UID_B);
    // Every path A's rules match explicitly — a rule that guards the parent
    // and forgets a subcollection would let one of these through.
    for (const path of [
      A_ROOT,
      A_BAND,
      A_BAND_SECRET,
      A_SESSION_TIP,
      A_RELAY_TIP,
      A_STRIPE_TIP,
      A_SETTINGS,
      A_LIVE,
      A_DEVICE,
      A_PRIVATE_SECURITY,
      A_PRIVATE_STRIPE,
    ]) {
      await assertFails(getDoc(doc(db, path)));
    }
  });

  it("denies B write on every A subtree", async () => {
    const db = authed(UID_B);
    for (const path of [
      A_ROOT,
      A_BAND,
      A_BAND_SECRET,
      A_SESSION_TIP,
      A_RELAY_TIP,
      A_STRIPE_TIP,
      A_SETTINGS,
      A_LIVE,
      A_PRIVATE_SECURITY,
      A_PRIVATE_STRIPE,
    ]) {
      await assertFails(setDoc(doc(db, path), { hijacked: true }));
    }
  });

  it("denies B the deeply-nested band doc (the recursive-wildcard OR-trap ward)", async () => {
    const db = authed(UID_B);
    const deep = `users/${UID_A}/bands/band1/sessions/s/tips/t/anything/x/more/y`;
    await assertFails(getDoc(doc(db, deep)));
    await assertFails(setDoc(doc(db, deep), { x: 1 }));
  });
});

describe("owner access: A's own doors are open (not welded shut)", () => {
  it("lets A read and write its own profile, bands, settings and live doc", async () => {
    const db = authed(UID_A);
    await assertSucceeds(setDoc(doc(db, A_ROOT), { displayName: "A" }));
    await assertSucceeds(getDoc(doc(db, A_ROOT)));
    await assertSucceeds(setDoc(doc(db, A_BAND), { name: "band" }));
    await assertSucceeds(getDoc(doc(db, A_BAND)));
    await assertSucceeds(setDoc(doc(db, A_BAND_SECRET), { hash: "x" }));
    await assertSucceeds(setDoc(doc(db, A_SETTINGS), { theme: "dark" }));
    await assertSucceeds(setDoc(doc(db, A_LIVE), { running: true }));
  });

  it("lets A read its own revocation watermark (private/security) but never write it", async () => {
    const db = authed(UID_A);
    // Read is granted to the owner — they may see when their sessions were cut.
    await assertSucceeds(getDoc(doc(db, A_PRIVATE_SECURITY)));
    // Write is `if false` for EVERYONE, the owner included: the watermark is
    // function-owned, or a stolen phone could launder its own revocation away.
    await assertFails(setDoc(doc(db, A_PRIVATE_SECURITY), { sessionsValidAfterMs: 0 }));
  });

  it("denies A its own private/stripe pointer (only private/security is readable)", async () => {
    const db = authed(UID_A);
    // The rules deliberately dropped the {document=**} read grant under
    // private/ — anything but private/security falls to default deny, so the
    // Stripe custody path has no client edge, the owner's included.
    await assertFails(getDoc(doc(db, A_PRIVATE_STRIPE)));
    await assertFails(setDoc(doc(db, A_PRIVATE_STRIPE), { anything: true }));
  });
});

describe("client-writable tips: only the owner, only onto their own tree", () => {
  it("lets A create tips/relayTips/stripeTips under its own band", async () => {
    const db = authed(UID_A);
    await assertSucceeds(setDoc(doc(db, A_SESSION_TIP), { amount: 500 }));
    await assertSucceeds(setDoc(doc(db, A_RELAY_TIP), { amount: 500 }));
    await assertSucceeds(setDoc(doc(db, A_STRIPE_TIP), { amount: 500 }));
  });

  it("denies B creating a tip on A's tree (no fake-tip injection cross-account)", async () => {
    const db = authed(UID_B);
    await assertFails(setDoc(doc(db, A_SESSION_TIP), { amount: 500 }));
    await assertFails(setDoc(doc(db, A_RELAY_TIP), { amount: 500 }));
    await assertFails(setDoc(doc(db, A_STRIPE_TIP), { amount: 500 }));
  });
});

describe("anonymous and unauthenticated callers are denied", () => {
  it("denies an unauthenticated caller A's tree and every top-level collection", async () => {
    const db = anon();
    for (const path of [A_ROOT, A_BAND, A_DEVICE, A_PRIVATE_SECURITY, JAR, LINK_CODE]) {
      await assertFails(getDoc(doc(db, path)));
    }
    await assertFails(setDoc(doc(db, A_ROOT), { x: 1 }));
  });

  it("denies the relay's anonymous uid any A-tree access (it is only a jar reader)", async () => {
    const db = authed(UID_RELAY);
    await assertFails(getDoc(doc(db, A_ROOT)));
    await assertFails(getDoc(doc(db, A_BAND)));
    await assertFails(getDoc(doc(db, A_DEVICE)));
  });
});

describe("jars: fake-tip injection is impossible from a client", () => {
  beforeEach(async () => {
    await seed(JAR, { ownerUid: UID_A, readerUids: [UID_RELAY] });
    await seed(JAR_PENDING_TIP, { amount: 500 });
    await seed(JAR_PRIVATE, { secretHash: "x" });
  });

  it("reads the jar for the owner and linked readers, denies everyone else", async () => {
    await assertSucceeds(getDoc(doc(authed(UID_A), JAR))); // owner
    await assertSucceeds(getDoc(doc(authed(UID_RELAY), JAR))); // linked reader
    await assertFails(getDoc(doc(authed(UID_B), JAR))); // stranger
    await assertFails(getDoc(doc(anon(), JAR))); // unauthenticated
  });

  it("denies ALL client writes to a jar (write is `if false`), owner included", async () => {
    await assertFails(setDoc(doc(authed(UID_A), JAR), { ownerUid: UID_A, readerUids: [] }));
    await assertFails(setDoc(doc(authed(UID_B), JAR), { ownerUid: UID_B }));
    await assertFails(updateDoc(doc(authed(UID_A), JAR), { readerUids: [UID_B] }));
  });

  it("denies pendingTips create and update to every client (only the tip function stages)", async () => {
    // create: a client forging a $500 tip into someone's jar.
    await assertFails(setDoc(doc(authed(UID_A), "jars/jar1/pendingTips/forged"), { amount: 500 }));
    await assertFails(setDoc(doc(authed(UID_RELAY), "jars/jar1/pendingTips/forged"), { amount: 500 }));
    await assertFails(setDoc(doc(authed(UID_B), "jars/jar1/pendingTips/forged"), { amount: 500 }));
    // update: editing a staged tip in place.
    await assertFails(updateDoc(doc(authed(UID_A), JAR_PENDING_TIP), { amount: 999999 }));
  });

  it("lets owner and reader read+delete a pending tip (delivery IS deletion), denies strangers", async () => {
    await assertSucceeds(getDoc(doc(authed(UID_A), JAR_PENDING_TIP)));
    await assertSucceeds(getDoc(doc(authed(UID_RELAY), JAR_PENDING_TIP)));
    await assertFails(getDoc(doc(authed(UID_B), JAR_PENDING_TIP)));
    await assertFails(getDoc(doc(anon(), JAR_PENDING_TIP)));
    // A stranger cannot delete a tip out from under the artist.
    await assertFails(deleteDoc(doc(authed(UID_B), JAR_PENDING_TIP)));
    // The owner clears it once shown.
    await assertSucceeds(deleteDoc(doc(authed(UID_A), JAR_PENDING_TIP)));
  });

  it("denies jars/*/private/* (secret hash + rate state) to every principal, owner included", async () => {
    for (const db of [authed(UID_A), authed(UID_RELAY), authed(UID_B), anon()]) {
      await assertFails(getDoc(doc(db, JAR_PRIVATE)));
      await assertFails(setDoc(doc(db, JAR_PRIVATE), { secretHash: "y" }));
    }
  });
});

describe("devices: the kill switch's teeth cannot be laundered", () => {
  it("lets a create declare revoked:false with no revokedAtMs", async () => {
    const db = authed(UID_A);
    await assertSucceeds(
      setDoc(doc(db, "users/artist_a/devices/new"), {
        name: "iPhone",
        revoked: false,
        createdAtMs: 1,
      }),
    );
  });

  it("denies a create that tries to be born revoked:true or to carry revokedAtMs", async () => {
    const db = authed(UID_A);
    await assertFails(
      setDoc(doc(db, "users/artist_a/devices/evil1"), { name: "x", revoked: true }),
    );
    await assertFails(
      setDoc(doc(db, "users/artist_a/devices/evil2"), {
        name: "x",
        revoked: false,
        revokedAtMs: 123,
      }),
    );
    // A create that omits `revoked` entirely fails the `revoked == false` pin.
    await assertFails(setDoc(doc(db, "users/artist_a/devices/evil3"), { name: "x" }));
  });

  it("lets an update touch benign fields but change neither revoked nor revokedAtMs", async () => {
    await seed(A_DEVICE, { name: "old", revoked: false, createdAtMs: 1 });
    const db = authed(UID_A);
    await assertSucceeds(updateDoc(doc(db, A_DEVICE), { name: "renamed", lastSeenAtMs: 2 }));
  });

  it("denies an update that flips revoked or stamps revokedAtMs (self-unrevoke)", async () => {
    await seed(A_DEVICE, { name: "old", revoked: false, createdAtMs: 1 });
    const db = authed(UID_A);
    await assertFails(updateDoc(doc(db, A_DEVICE), { revoked: true }));
    await assertFails(updateDoc(doc(db, A_DEVICE), { revokedAtMs: 999 }));
  });

  it("denies a revoked device laundering itself back to false via update", async () => {
    // A stolen phone that revokeAllOtherDevices marked revoked:true must not be
    // able to write itself back to false.
    await seed(A_DEVICE, { name: "stolen", revoked: true, revokedAtMs: 100, createdAtMs: 1 });
    const db = authed(UID_A);
    await assertFails(updateDoc(doc(db, A_DEVICE), { revoked: false }));
    await assertFails(updateDoc(doc(db, A_DEVICE), { revoked: false, revokedAtMs: null }));
  });

  it("denies client delete (no delete-and-recreate to shed a revocation)", async () => {
    await seed(A_DEVICE, { name: "d", revoked: true, revokedAtMs: 100, createdAtMs: 1 });
    await assertFails(deleteDoc(doc(authed(UID_A), A_DEVICE)));
  });
});

describe("revocation watermark: an ID token minted before the cut loses the subtree", () => {
  const WATERMARK_MS = 2_000_000_000_000; // some instant
  const BEFORE_SEC = 1_000_000_000; // *1000 = 1e12 ms  < watermark
  const AFTER_SEC = 3_000_000_000; // *1000 = 3e12 ms  >= watermark

  it("allows the owner's subtree when there is NO security doc (short-circuit on exists())", async () => {
    // No watermark seeded → notRevoked short-circuits true.
    await assertSucceeds(getDoc(doc(authed(UID_A, BEFORE_SEC), A_ROOT)));
  });

  it("denies the whole subtree for a token minted before the watermark", async () => {
    await seed(A_PRIVATE_SECURITY, { sessionsValidAfterMs: WATERMARK_MS });
    const stale = authed(UID_A, BEFORE_SEC);
    await assertFails(getDoc(doc(stale, A_ROOT)));
    await assertFails(getDoc(doc(stale, A_BAND)));
    await assertFails(setDoc(doc(stale, A_SETTINGS), { theme: "x" }));
    await assertFails(getDoc(doc(stale, A_DEVICE)));
  });

  it("allows the subtree for a token minted at/after the watermark", async () => {
    await seed(A_PRIVATE_SECURITY, { sessionsValidAfterMs: WATERMARK_MS });
    const fresh = authed(UID_A, AFTER_SEC);
    await assertSucceeds(getDoc(doc(fresh, A_ROOT)));
    await assertSucceeds(getDoc(doc(fresh, A_BAND)));
  });
});

describe("list vs get: single-document rules do not permit an open query", () => {
  beforeEach(async () => {
    await seed(JAR, { ownerUid: UID_A, readerUids: [] });
    await seed(LINK_CODE, { uid: UID_A, status: "pending" });
  });

  it("denies an unconstrained list where the rule means a single-doc read", async () => {
    const db = authed(UID_A);
    // jars.read is gated on resource.data — you may fetch a jar you own, never
    // enumerate the collection.
    await assertFails(getDocs(collection(db, "jars")));
    // linkCodes.read is gated on resource.data.uid — same story.
    await assertFails(getDocs(collection(db, "linkCodes")));
  });

  it("allows a get of a link code you own, denies a stranger and all writes", async () => {
    await assertSucceeds(getDoc(doc(authed(UID_A), LINK_CODE)));
    await assertFails(getDoc(doc(authed(UID_B), LINK_CODE)));
    await assertFails(getDoc(doc(anon(), LINK_CODE)));
    await assertFails(setDoc(doc(authed(UID_A), LINK_CODE), { uid: UID_A, status: "hijack" }));
  });
});

describe("server-owned collections are unwritable (and unreadable) by clients", () => {
  const serverOnly = [
    RATE_LIMIT,
    ACCOUNT_DELETION,
    STRIPE_CONNECTION,
    PROCESSED_EVENT,
  ];

  it("denies read and write to rateLimits, accountDeletions, stripeConnections, processedEvents", async () => {
    for (const path of serverOnly) {
      // Seed each so the read is a real doc, not an absent one.
      await seed(path, { server: true });
    }
    // Every client principal, including the artist named by accountDeletions/A.
    for (const db of [authed(UID_A), authed(UID_B), anon()]) {
      for (const path of serverOnly) {
        await assertFails(getDoc(doc(db, path)));
        await assertFails(setDoc(doc(db, path), { forged: true }));
      }
    }
  });

  it("denies stripeConnections to the owning artist too (key custody: no client edge, ever)", async () => {
    await seed(STRIPE_CONNECTION, { uid: UID_A, kmsBlob: "wrapped" });
    // Even a doc that names A is closed to A — the KMS-wrapped key never returns
    // to a device.
    await assertFails(getDoc(doc(authed(UID_A), STRIPE_CONNECTION)));
    await assertFails(setDoc(doc(authed(UID_A), STRIPE_CONNECTION), { kmsBlob: "y" }));
  });

  it("denies the catch-all: an unlisted collection is closed to everyone", async () => {
    await seed("someFutureThing/x", { a: 1 });
    await assertFails(getDoc(doc(authed(UID_A), "someFutureThing/x")));
    await assertFails(setDoc(doc(authed(UID_A), "someFutureThing/x"), { a: 2 }));
  });
});
