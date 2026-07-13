/// The mint-vs-burn ordering of collectLinkToken / collectLoginToken, driven
/// through the real handlers over an in-memory Firestore stand-in.
///
/// The production failure this pins down: the handler flipped the code to
/// 'used' INSIDE the validating transaction, BEFORE createCustomToken ran —
/// so when minting failed (the runtime service account lacked
/// iam.serviceAccounts.signBlob) the code was burnt by a token that never
/// existed: the tablet's "Try again" needed a whole fresh QR, and the phone
/// watching the doc saw 'used' and announced a sign-in that never happened.
/// The fix mints FIRST and burns in a second, re-validating transaction.

import { beforeEach, describe, expect, it, vi } from "vitest";
import { sha256Hex } from "../src/auth";

// ---------------------------------------------------------------------------
// Module mocks. ./store initializes the Admin SDK at module load and hands
// out real Firestore refs — both replaced by an in-memory doc map that the
// fake transactions read and write. Values that are constants in the real
// module keep their meaning; functions the handlers under test never touch
// are absent on purpose (a call would fail the test loudly).

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
  runTransaction: async <T>(fn: (tx: unknown) => Promise<T>): Promise<T> =>
    fn({
      get: async (ref: { path: string }) => fakeSnap(ref.path),
      update: (ref: { path: string }, patch: Record<string, unknown>) => {
        const doc = docs.get(ref.path);
        if (doc === undefined) throw new Error(`update on missing ${ref.path}`);
        Object.assign(doc, patch);
      },
    }),
};

vi.mock("../src/store", () => ({
  db: () => fakeDb,
  linkCodeRef: (_db: unknown, code: string) => ({ path: `linkCodes/${code}` }),
  loginRequestRef: (_db: unknown, id: string) => ({ path: `loginRequests/${id}` }),
  securityRef: (_db: unknown, uid: string) => ({ path: `users/${uid}/private/security` }),
  bumpQuota: async () => true,
  LINK_COLLECTS_PER_IP_PER_HOUR: 120,
  LINK_REDEEMS_PER_IP_PER_HOUR: 30,
  LOGIN_COLLECTS_PER_IP_PER_HOUR: 900,
  LOGIN_CREATES_PER_IP_PER_HOUR: 60,
  LOGIN_DESCRIBES_PER_IP_PER_HOUR: 60,
}));

vi.mock("../src/params", () => ({
  IP_HASH_SALT: { value: () => "test-salt" },
}));

const createCustomToken = vi.fn<(uid: string) => Promise<string>>();
vi.mock("firebase-admin/auth", () => ({
  getAuth: () => ({ createCustomToken }),
}));

import { collectLinkTokenHandler, collectLoginTokenHandler } from "../src/devices";

// ---------------------------------------------------------------------------

const CODE = "A".repeat(22); // valid 22-char base64url shape
const REQUEST_ID = "B".repeat(22);
const NONCE = "n".repeat(22);

function linkRequest(): never {
  // CallableRequest is structurally typed; only what the handler reads.
  return {
    data: { code: CODE, nonce: NONCE },
    rawRequest: { headers: {}, socket: { remoteAddress: "203.0.113.7" } },
  } as never;
}

function loginRequest(): never {
  return {
    data: { requestId: REQUEST_ID, collectNonce: NONCE },
    rawRequest: { headers: {}, socket: { remoteAddress: "203.0.113.7" } },
  } as never;
}

function seedConfirmedLinkCode() {
  docs.set(`linkCodes/${CODE}`, {
    uid: "uid_owner",
    status: "confirmed",
    createdAtMs: Date.now(),
    expiresAt: { toMillis: () => Date.now() + 60_000 },
    attempts: 0,
    redeemNonceHash: sha256Hex(NONCE),
    confirmedAtMs: Date.now(),
  });
}

function seedApprovedLoginRequest() {
  docs.set(`loginRequests/${REQUEST_ID}`, {
    status: "approved",
    approvedUid: "uid_artist",
    approvedAtMs: Date.now(),
    createdAtMs: Date.now(),
    expiresAt: { toMillis: () => Date.now() + 60_000 },
    attempts: 0,
    collectNonceHash: sha256Hex(NONCE),
  });
}

/** The revocation watermark, as revokeAllOtherDevices writes it. */
function seedWatermark(uid: string, watermarkMs: number) {
  docs.set(`users/${uid}/private/security`, { sessionsValidAfterMs: watermarkMs });
}

beforeEach(() => {
  docs.clear();
  createCustomToken.mockReset();
});

describe("collectLinkToken: mint before burn", () => {
  it("a failed mint must NOT consume the code — retry works with the same QR", async () => {
    seedConfirmedLinkCode();
    createCustomToken.mockRejectedValueOnce(
      new Error("Permission iam.serviceAccounts.signBlob denied"),
    );

    await expect(collectLinkTokenHandler(linkRequest())).rejects.toThrow();

    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("confirmed");

    // The IAM problem gets fixed (or the outage passes): the SAME code and
    // nonce still collect — no fresh QR ceremony needed.
    createCustomToken.mockResolvedValueOnce("token-123");
    const retry = await collectLinkTokenHandler(linkRequest());
    expect(retry.token).toBe("token-123");
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("used");
  });

  it("'used' on the doc means a token was actually handed over", async () => {
    seedConfirmedLinkCode();
    createCustomToken.mockResolvedValueOnce("token-123");

    const result = await collectLinkTokenHandler(linkRequest());

    expect(result.token).toBe("token-123");
    expect(createCustomToken).toHaveBeenCalledWith("uid_owner");
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("used");
  });

  it("single use still holds: a second collect after the burn is refused", async () => {
    seedConfirmedLinkCode();
    createCustomToken.mockResolvedValue("token-123");

    await collectLinkTokenHandler(linkRequest());
    await expect(collectLinkTokenHandler(linkRequest())).rejects.toThrow();
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("used");
  });

  it("a claimed-but-unconfirmed code still answers pending, minting nothing", async () => {
    seedConfirmedLinkCode();
    docs.get(`linkCodes/${CODE}`)!["status"] = "claimed";

    const result = await collectLinkTokenHandler(linkRequest());

    expect(result.pending).toBe(true);
    expect(createCustomToken).not.toHaveBeenCalled();
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("claimed");
  });
});

describe("collectLoginToken: mint before burn (the venue tablet's flow)", () => {
  it("a failed mint must NOT consume the request", async () => {
    seedApprovedLoginRequest();
    createCustomToken.mockRejectedValueOnce(
      new Error("Permission iam.serviceAccounts.signBlob denied"),
    );

    await expect(collectLoginTokenHandler(loginRequest())).rejects.toThrow();
    expect(docs.get(`loginRequests/${REQUEST_ID}`)!["status"]).toBe("approved");

    createCustomToken.mockResolvedValueOnce("token-456");
    const retry = await collectLoginTokenHandler(loginRequest());
    expect(retry.token).toBe("token-456");
    expect(createCustomToken).toHaveBeenLastCalledWith("uid_artist");
    expect(docs.get(`loginRequests/${REQUEST_ID}`)!["status"]).toBe("used");
  });

  it("single use still holds after a successful collect", async () => {
    seedApprovedLoginRequest();
    createCustomToken.mockResolvedValue("token-456");

    await collectLoginTokenHandler(loginRequest());
    await expect(collectLoginTokenHandler(loginRequest())).rejects.toThrow();
  });
});

// ---------------------------------------------------------------------------
// The revocation watermark gate (issue #7). revokeAllOtherDevices sweeps live
// grants to 'expired', but a confirm/approve can race the sweep — so collect*
// must ALSO refuse a grant whose confirm/approve predates the uid's
// sessionsValidAfterMs watermark. These tests exercise exactly that race: the
// doc is still 'confirmed'/'approved' (as if the sweep missed it), and the
// mint must not happen.

describe("collectLinkToken vs the revocation watermark", () => {
  it("a code confirmed BEFORE revokeAllOtherDevices must not mint", async () => {
    seedConfirmedLinkCode();
    docs.get(`linkCodes/${CODE}`)!["confirmedAtMs"] = Date.now() - 5_000;
    seedWatermark("uid_owner", Date.now());

    await expect(collectLinkTokenHandler(linkRequest())).rejects.toThrow();

    expect(createCustomToken).not.toHaveBeenCalled();
    // The refusal burns the grant too: retrying cannot revive it.
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("expired");
  });

  it("a confirmed code with no confirmedAtMs fails closed once a watermark exists", async () => {
    seedConfirmedLinkCode();
    delete docs.get(`linkCodes/${CODE}`)!["confirmedAtMs"];
    seedWatermark("uid_owner", Date.now());

    await expect(collectLinkTokenHandler(linkRequest())).rejects.toThrow();
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it("a code confirmed AFTER the watermark mints — a fresh session confirmed it", async () => {
    seedConfirmedLinkCode();
    docs.get(`linkCodes/${CODE}`)!["confirmedAtMs"] = Date.now();
    seedWatermark("uid_owner", Date.now() - 5_000);
    createCustomToken.mockResolvedValueOnce("token-123");

    const result = await collectLinkTokenHandler(linkRequest());

    expect(result.token).toBe("token-123");
    expect(docs.get(`linkCodes/${CODE}`)!["status"]).toBe("used");
  });
});

describe("collectLoginToken vs the revocation watermark", () => {
  it("a request approved BEFORE revokeAllOtherDevices must not mint", async () => {
    seedApprovedLoginRequest();
    docs.get(`loginRequests/${REQUEST_ID}`)!["approvedAtMs"] = Date.now() - 5_000;
    seedWatermark("uid_artist", Date.now());

    await expect(collectLoginTokenHandler(loginRequest())).rejects.toThrow();

    expect(createCustomToken).not.toHaveBeenCalled();
    expect(docs.get(`loginRequests/${REQUEST_ID}`)!["status"]).toBe("expired");
  });

  it("an approved request with no approvedAtMs fails closed once a watermark exists", async () => {
    seedApprovedLoginRequest();
    delete docs.get(`loginRequests/${REQUEST_ID}`)!["approvedAtMs"];
    seedWatermark("uid_artist", Date.now());

    await expect(collectLoginTokenHandler(loginRequest())).rejects.toThrow();
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it("a request approved AFTER the watermark mints — a fresh session approved it", async () => {
    seedApprovedLoginRequest();
    docs.get(`loginRequests/${REQUEST_ID}`)!["approvedAtMs"] = Date.now();
    seedWatermark("uid_artist", Date.now() - 5_000);
    createCustomToken.mockResolvedValueOnce("token-456");

    const result = await collectLoginTokenHandler(loginRequest());

    expect(result.token).toBe("token-456");
    expect(docs.get(`loginRequests/${REQUEST_ID}`)!["status"]).toBe("used");
  });
});
