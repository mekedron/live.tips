/// The interleaving issue #7 says was never tested: an attacker pre-positions
/// a grant with a stolen session (confirms a link code), the victim hits
/// "revoke all other devices", and the attacker's device collects AFTERWARDS.
/// collectLinkToken is unauthenticated and mints custom tokens whose auth_time
/// postdates the watermark, so the watermark alone cannot stop the mint — the
/// revocation must kill the GRANT itself. Driven through the real handlers over
/// an in-memory Firestore stand-in.

import { beforeEach, describe, expect, it, vi } from "vitest";
import { FieldValue } from "firebase-admin/firestore";
import { sha256Hex } from "../src/auth";

// ---------------------------------------------------------------------------
// Module mocks, in the shape of collect-token.test.ts but wider: the revoke
// handler also QUERIES collections (the grant sweep, the device loop) and
// writes through a batch, so the fake grows where(), get() and batch().

/** path → doc data. Reset per test. */
const docs = new Map<string, Record<string, unknown>>();

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

/** Timestamps arrive as real Timestamp (query values) or {toMillis} (doc data). */
function toComparable(value: unknown): unknown {
  const maybe = value as { toMillis?: () => number } | null | undefined;
  return typeof maybe?.toMillis === "function" ? maybe.toMillis() : value;
}

function matches(data: Record<string, unknown>, f: Filter): boolean {
  const actual = toComparable(data[f.field]);
  const wanted = toComparable(f.value);
  if (f.op === "==") return actual === wanted;
  if (f.op === ">") return typeof actual === "number" && typeof wanted === "number" && actual > wanted;
  throw new Error(`unsupported operator ${f.op}`);
}

/** Direct children of `prefix` matching every filter — enough for these handlers. */
function fakeQuery(prefix: string, filters: Filter[] = []) {
  return {
    where: (field: string, op: string, value: unknown) =>
      fakeQuery(prefix, [...filters, { field, op, value }]),
    get: async () => {
      const out = [];
      for (const [path, data] of docs) {
        if (!path.startsWith(`${prefix}/`)) continue;
        if (path.slice(prefix.length + 1).includes("/")) continue;
        if (!filters.every((f) => matches(data, f))) continue;
        out.push(fakeSnap(path));
      }
      return { docs: out };
    },
  };
}

function applyUpdate(path: string, patch: Record<string, unknown>) {
  const doc = docs.get(path);
  if (doc === undefined) throw new Error(`update on missing ${path}`);
  for (const [field, value] of Object.entries(patch)) {
    // FieldValue.delete() — the confirm drops revokedAtMs when it re-admits.
    if (value instanceof FieldValue) delete doc[field];
    else doc[field] = value;
  }
}

const fakeDb = {
  runTransaction: async <T>(fn: (tx: unknown) => Promise<T>): Promise<T> =>
    fn({
      get: async (ref: { path: string }) => fakeSnap(ref.path),
      update: (ref: { path: string }, patch: Record<string, unknown>) =>
        applyUpdate(ref.path, patch),
    }),
  collection: (name: string) => fakeQuery(name),
  batch: () => {
    const writes: Array<() => void> = [];
    return {
      update: (ref: { path: string }, patch: Record<string, unknown>) => {
        writes.push(() => applyUpdate(ref.path, patch));
      },
      commit: async () => {
        for (const write of writes) write();
        writes.length = 0;
      },
    };
  },
};

vi.mock("../src/store", () => ({
  db: () => fakeDb,
  linkCodeRef: (_db: unknown, code: string) => ({ path: `linkCodes/${code}` }),
  deviceRef: (_db: unknown, uid: string, deviceId: string) => ({
    path: `users/${uid}/devices/${deviceId}`,
  }),
  devicesCol: (_db: unknown, uid: string) => fakeQuery(`users/${uid}/devices`),
  securityRef: (_db: unknown, uid: string) => {
    const path = `users/${uid}/private/security`;
    return {
      path,
      get: async () => fakeSnap(path),
      set: async (data: Record<string, unknown>) => {
        docs.set(path, { ...docs.get(path), ...data });
      },
    };
  },
  bumpQuota: async () => true,
  LINK_COLLECTS_PER_IP_PER_HOUR: 120,
  LINK_REDEEMS_PER_IP_PER_HOUR: 30,
}));

vi.mock("../src/params", () => ({
  IP_HASH_SALT: { value: () => "test-salt" },
}));

const createCustomToken = vi.fn<(uid: string) => Promise<string>>();
const revokeRefreshTokens = vi.fn<(uid: string) => Promise<void>>();
vi.mock("firebase-admin/auth", () => ({
  getAuth: () => ({ createCustomToken, revokeRefreshTokens }),
}));

import {
  collectLinkTokenHandler,
  confirmLinkCodeHandler,
  redeemLinkCodeHandler,
  revokeAllOtherDevicesHandler,
} from "../src/devices";

// ---------------------------------------------------------------------------

const VICTIM = "uid_victim";
const GUEST = "uid_guest";
const CODE = "A".repeat(22);
const NONCE = "n".repeat(22);

/** A signed-in callable request — only what the handlers read. */
function signedIn(
  uid: string,
  data: Record<string, unknown>,
  provider = "password",
): never {
  return {
    auth: {
      uid,
      token: {
        auth_time: Math.floor(Date.now() / 1000),
        firebase: { sign_in_provider: provider },
      },
    },
    data,
    rawRequest: { headers: {}, socket: { remoteAddress: "203.0.113.7" } },
  } as never;
}

/** A guest: a real account with a real session, and no provider behind it. */
function guest(uid: string, data: Record<string, unknown>): never {
  return signedIn(uid, data, "anonymous");
}

/** The unauthenticated collector (device B / the tablet). */
function unauthenticated(data: Record<string, unknown>): never {
  return {
    data,
    rawRequest: { headers: {}, socket: { remoteAddress: "203.0.113.7" } },
  } as never;
}

function seedClaimedLinkCode(uid = VICTIM, code = CODE) {
  docs.set(`linkCodes/${code}`, {
    uid,
    status: "claimed",
    createdAtMs: Date.now(),
    expiresAt: { toMillis: () => Date.now() + 60_000 },
    attempts: 1,
    requester: { name: "Attacker's phone", platform: "android" },
    redeemNonceHash: sha256Hex(NONCE),
  });
}

function seedDevices(uid = VICTIM) {
  docs.set(`users/${uid}/devices/phone-1`, {
    name: "Victim's phone", platform: "ios", createdAtMs: Date.now(),
    lastSeenAtMs: Date.now(), revoked: false,
  });
  docs.set(`users/${uid}/devices/device-b`, {
    name: "Attacker's phone", platform: "android", createdAtMs: Date.now(),
    lastSeenAtMs: Date.now(), revoked: false,
  });
}

beforeEach(() => {
  docs.clear();
  createCustomToken.mockReset();
  createCustomToken.mockResolvedValue("caller-token");
  revokeRefreshTokens.mockReset();
  revokeRefreshTokens.mockResolvedValue(undefined);
});

describe("confirm, THEN revoke, THEN collect — the link-code kill switch", () => {
  it("a confirmed link code does not survive revokeAllOtherDevices", async () => {
    seedClaimedLinkCode();
    seedDevices();

    // 1. The stolen (but not-yet-revoked) session confirms its own code.
    await confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE }));
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("confirmed");

    // 2. The victim hits the kill switch. The sweep must expire the code.
    const result = await revokeAllOtherDevicesHandler(
      signedIn(VICTIM, { currentDeviceId: "phone-1" }),
    );
    expect(result.revokedCount).toBe(1);
    expect(revokeRefreshTokens).toHaveBeenCalledWith(VICTIM);
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("expired");
    // The only token minted so far is the caller's own way back in (#34); the
    // question below is whether the ATTACKER gets one.
    expect(createCustomToken).toHaveBeenCalledWith(VICTIM);
    createCustomToken.mockClear();

    // 3. Device B collects — inside the 2-minute window — and must get nothing.
    await expect(
      collectLinkTokenHandler(unauthenticated({ code: CODE, nonce: NONCE })),
    ).rejects.toThrow();
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it("the sweep leaves other accounts' codes and 'used' codes alone", async () => {
    const otherCode = "C".repeat(22);
    seedClaimedLinkCode();
    seedClaimedLinkCode("uid_other", otherCode);
    docs.get(`linkCodes/${otherCode}`)!["status"] = "confirmed";
    const usedCode = "D".repeat(22);
    seedClaimedLinkCode(VICTIM, usedCode);
    docs.get(`linkCodes/${usedCode}`)!["status"] = "used";
    seedDevices();

    await revokeAllOtherDevicesHandler(signedIn(VICTIM, { currentDeviceId: "phone-1" }));

    // The victim's claimed code dies; the used one keeps its history; the
    // other account's confirmed code is untouched.
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("expired");
    expect(docs.get(`linkCodes/${usedCode}`)!["status"]).toBe("used");
    expect(docs.get(`linkCodes/${otherCode}`)!["status"]).toBe("confirmed");
  });
});

// The other half of the kill switch, and the half nothing tested (#34): what
// the CALLER is left holding. These tests assert not what the handler revokes
// but that the artist who pulled the switch can still act afterwards.
describe("the caller keeps its session", () => {
  it("hands the caller a token minted AFTER the refresh tokens die", async () => {
    seedDevices();
    // A token minted BEFORE the revoke would be a credential the revoke was
    // supposed to kill. The order IS the guarantee, so assert the order.
    const order: string[] = [];
    revokeRefreshTokens.mockImplementation(async () => {
      order.push("revoke");
    });
    createCustomToken.mockImplementation(async (uid) => {
      order.push(`mint:${uid}`);
      return "caller-token";
    });

    const result = await revokeAllOtherDevicesHandler(
      signedIn(VICTIM, { currentDeviceId: "phone-1" }),
    );

    expect(result.token).toBe("caller-token");
    expect(order).toEqual(["revoke", `mint:${VICTIM}`]);
    // Its own uid, nobody else's — the caller can only ever come back as
    // itself, which is what makes handing it a token safe.
    expect(createCustomToken).toHaveBeenCalledExactlyOnceWith(VICTIM);
  });

  it("hands out no token when the revoke itself fails", async () => {
    seedDevices();
    revokeRefreshTokens.mockRejectedValue(new Error("admin sdk down"));

    await expect(
      revokeAllOtherDevicesHandler(signedIn(VICTIM, { currentDeviceId: "phone-1" })),
    ).rejects.toThrow();
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it("still refuses a session older than the watermark — and mints it nothing",
    async () => {
      // A stolen session, already cut off by an earlier revocation, must not be
      // able to call the switch and be handed a fresh credential for its
      // trouble. requireFreshSession is the door, and it is still shut.
      seedDevices();
      docs.set(`users/${VICTIM}/private/security`, {
        sessionsValidAfterMs: Date.now() + 60_000,
      });

      await expect(
        revokeAllOtherDevicesHandler(signedIn(VICTIM, { currentDeviceId: "phone-1" })),
      ).rejects.toMatchObject({ code: "unauthenticated" });
      expect(revokeRefreshTokens).not.toHaveBeenCalled();
      expect(createCustomToken).not.toHaveBeenCalled();
    });

  it("mints a token no earlier than the second AFTER the watermark", async () => {
    // auth_time is seconds; the watermark is milliseconds. A session minted in
    // the same second as the stamp reads as older than it forever — so the
    // caller's own re-entry would be locked out of users/** for its whole life.
    seedDevices();
    let mintedAt = 0;
    createCustomToken.mockImplementation(async () => {
      mintedAt = Date.now();
      return "caller-token";
    });

    await revokeAllOtherDevicesHandler(signedIn(VICTIM, { currentDeviceId: "phone-1" }));

    const watermark = docs.get(`users/${VICTIM}/private/security`)![
      "sessionsValidAfterMs"
    ] as number;
    // The auth_time (seconds) of any session redeemed from here on clears it.
    expect(Math.floor(mintedAt / 1000) * 1000).toBeGreaterThanOrEqual(watermark);
  });

  it("serves a GUEST caller: the token needs no provider to redeem", async () => {
    // The anonymous restriction existed for exactly one reason — an anonymous
    // account had nothing to re-authenticate WITH. A server-minted token needs
    // no provider, so the guest gets the kill switch (#34), and gets back in.
    seedDevices(GUEST);

    const result = await revokeAllOtherDevicesHandler(
      guest(GUEST, { currentDeviceId: "phone-1" }),
    );

    expect(result.revokedCount).toBe(1);
    expect(docs.get(`users/${GUEST}/devices/device-b`)!["revoked"]).toBe(true);
    expect(docs.get(`users/${GUEST}/private/security`)!["sessionsValidAfterMs"])
      .toBeTypeOf("number");
    expect(revokeRefreshTokens).toHaveBeenCalledWith(GUEST);
    expect(result.token).toBe("caller-token");
  });
});

// Revocation used to be a one-way door (#36): nothing anywhere wrote
// revoked:false, so a device the artist revoked — their own laptop, every
// other device after one tap on the kill switch — was barred from the account
// for good. The confirm is the way back, and the only one.
describe("a revoked device can be re-admitted, and only by the artist", () => {
  const LAPTOP = "device-b";

  /** The QR the artist shows on a device that is still signed in. */
  function seedPendingLinkCode(uid = VICTIM, code = CODE) {
    docs.set(`linkCodes/${code}`, {
      uid,
      status: "pending",
      createdAtMs: Date.now(),
      expiresAt: { toMillis: () => Date.now() + 60_000 },
      attempts: 0,
    });
  }

  /** The laptop scans it, naming itself. */
  function redeem(deviceId: string | undefined, code = CODE) {
    return redeemLinkCodeHandler(
      unauthenticated({
        code,
        deviceName: "Casey's laptop",
        devicePlatform: "macos",
        ...(deviceId === undefined ? {} : { deviceId }),
      }),
    );
  }

  it("the artist's own laptop comes back after the kill switch", async () => {
    seedDevices();
    await revokeAllOtherDevicesHandler(signedIn(VICTIM, { currentDeviceId: "phone-1" }));
    expect(docs.get(`users/${VICTIM}/devices/${LAPTOP}`)!["revoked"]).toBe(true);

    // The whole ceremony, from the laptop's side and then the artist's.
    seedPendingLinkCode();
    await redeem(LAPTOP);
    expect(docs.get(`linkCodes/${CODE}`)!["requesterDeviceId"]).toBe(LAPTOP);

    await confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE }));

    const laptop = docs.get(`users/${VICTIM}/devices/${LAPTOP}`)!;
    expect(laptop["revoked"]).toBe(false);
    expect(laptop).not.toHaveProperty("revokedAtMs");
    // And the code is still a code: the re-admission rides the ceremony, it
    // does not replace it. The laptop still has to collect its token.
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("confirmed");
  });

  it("re-admits nobody the artist did not confirm", async () => {
    // Two revoked devices, one ceremony. The other one stays out.
    seedDevices();
    docs.set(`users/${VICTIM}/devices/tablet`, {
      name: "Old tablet", platform: "android", createdAtMs: Date.now(),
      lastSeenAtMs: Date.now(), revoked: false,
    });
    await revokeAllOtherDevicesHandler(signedIn(VICTIM, { currentDeviceId: "phone-1" }));

    seedPendingLinkCode();
    await redeem(LAPTOP);
    await confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE }));

    expect(docs.get(`users/${VICTIM}/devices/${LAPTOP}`)!["revoked"]).toBe(false);
    expect(docs.get(`users/${VICTIM}/devices/tablet`)!["revoked"]).toBe(true);
  });

  it("a confirm from a REVOKED session re-admits nothing", async () => {
    // The thief's session is exactly what requireFreshSession shuts out, and
    // the re-admission must live behind that door like everything else here.
    seedDevices();
    docs.set(`users/${VICTIM}/private/security`, {
      sessionsValidAfterMs: Date.now() + 60_000,
    });
    docs.set(`users/${VICTIM}/devices/${LAPTOP}`, {
      name: "Casey's laptop", platform: "macos", createdAtMs: Date.now(),
      lastSeenAtMs: Date.now(), revoked: true, revokedAtMs: Date.now(),
    });
    seedPendingLinkCode();
    await redeem(LAPTOP);

    await expect(
      confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE })),
    ).rejects.toMatchObject({ code: "unauthenticated" });
    expect(docs.get(`users/${VICTIM}/devices/${LAPTOP}`)!["revoked"]).toBe(true);
  });

  it("only ever touches a device of the CONFIRMING account", async () => {
    // The deviceId rides in on an unauthenticated redeem, so it is a claim,
    // not a credential. It can only ever name a doc under the uid that owns the
    // code — and only that uid's confirm acts on it.
    docs.set(`users/uid_other/devices/${LAPTOP}`, {
      name: "Someone else's laptop", platform: "macos", createdAtMs: Date.now(),
      lastSeenAtMs: Date.now(), revoked: true, revokedAtMs: Date.now(),
    });
    docs.set(`users/${VICTIM}/devices/${LAPTOP}`, {
      name: "Casey's laptop", platform: "macos", createdAtMs: Date.now(),
      lastSeenAtMs: Date.now(), revoked: true, revokedAtMs: Date.now(),
    });
    seedPendingLinkCode();
    await redeem(LAPTOP);
    await confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE }));

    expect(docs.get(`users/${VICTIM}/devices/${LAPTOP}`)!["revoked"]).toBe(false);
    expect(docs.get(`users/uid_other/devices/${LAPTOP}`)!["revoked"]).toBe(true);
  });

  it("a first-time device is confirmed without a device doc being invented",
    async () => {
      seedPendingLinkCode();
      await redeem("brand-new-device");

      await confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE }));

      expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("confirmed");
      expect(docs.has(`users/${VICTIM}/devices/brand-new-device`)).toBe(false);
    });

  it("a client that names no device still completes the ceremony", async () => {
    // An app that predates this simply has nothing to re-admit.
    seedPendingLinkCode();
    await redeem(undefined);
    expect(docs.get(`linkCodes/${CODE}`)).not.toHaveProperty("requesterDeviceId");

    await confirmLinkCodeHandler(signedIn(VICTIM, { code: CODE }));
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("confirmed");
  });
});
