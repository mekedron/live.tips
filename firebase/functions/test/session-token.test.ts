/// The bridge's token mint: the whole contract is "you get a token for the
/// uid you already are, and only if you are somebody" — and, since #59, only
/// if your session is fresh past the revocation watermark. Without the last
/// clause a stolen (revoked) session mints itself a post-watermark custom
/// token and re-enters permanently, so these tests carry a real watermark and
/// a real auth_time: the dimension the old happy-path fake could not express.

import { beforeEach, describe, expect, it, vi } from "vitest";
import type { CallableRequest } from "firebase-functions/v2/https";

const createCustomToken = vi.fn<(uid: string) => Promise<string>>();
vi.mock("firebase-admin/auth", () => ({
  getAuth: () => ({ createCustomToken }),
}));

// requireFreshSession (imported by the handler from ./devices) reads
// securityRef(...).get(); mock the store so the read hits an in-memory
// watermark instead of a live Firestore. Only db + securityRef are exercised
// on this path; the handler passes db() straight into requireFreshSession.
const watermarks = new Map<string, number>();
vi.mock("../src/store", () => ({
  db: () => ({}),
  securityRef: (_db: unknown, uid: string) => ({
    get: async () => ({
      get: (field: string) =>
        field === "sessionsValidAfterMs" ? watermarks.get(uid) : undefined,
    }),
  }),
}));

vi.mock("../src/params", () => ({
  IP_HASH_SALT: { value: () => "test-salt" },
}));

import { mintSessionTokenHandler } from "../src/session-token";

/** auth_time is seconds; omit it to model a caller/token that carries none. */
function request(
  auth: { uid: string; authTimeSec?: number } | undefined,
): CallableRequest {
  const built =
    auth === undefined
      ? undefined
      : { uid: auth.uid, token: { auth_time: auth.authTimeSec } };
  return { auth: built, data: {}, rawRequest: {} } as unknown as CallableRequest;
}

const nowSec = () => Math.floor(Date.now() / 1000);

beforeEach(() => {
  watermarks.clear();
  createCustomToken.mockReset();
  createCustomToken.mockImplementation(async (uid: string) => `custom-token-for:${uid}`);
});

describe("mintSessionToken", () => {
  it("refuses an unauthenticated caller", async () => {
    await expect(mintSessionTokenHandler(request(undefined))).rejects.toMatchObject({
      code: "unauthenticated",
    });
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it("mints for the caller's own uid — never anyone else's", async () => {
    // No watermark: an account that never revoked sails through untouched.
    const res = await mintSessionTokenHandler(request({ uid: "uid_artist" }));
    expect(res).toEqual({ token: "custom-token-for:uid_artist" });
  });

  it("serves anonymous sessions too — a guest upgrading itself brings an "
    + "anonymous session by definition", async () => {
    const res = await mintSessionTokenHandler(request({ uid: "uid_guest" }));
    expect(res.token).toBe("custom-token-for:uid_guest");
  });

  it("refuses a revoked (pre-watermark) session and mints it nothing", async () => {
    // The stolen phone: the kill switch stamped the watermark a minute into the
    // future relative to the token's auth_time, so this session is on the wrong
    // side of it. Minting here would launder the ≤1h window into permanent
    // re-entry (#59) — so it must be refused, and no token may be minted.
    watermarks.set("uid_artist", Date.now() + 60_000);
    await expect(
      mintSessionTokenHandler(request({ uid: "uid_artist", authTimeSec: nowSec() })),
    ).rejects.toMatchObject({ code: "unauthenticated" });
    expect(createCustomToken).not.toHaveBeenCalled();
  });

  it("mints for a fresh sign-in past the watermark — the legitimate bridge caller",
    async () => {
      // The real caller is a fresh sign-in on auth.live.tips: auth_time = now,
      // which postdates a watermark stamped earlier. The handoff must still work.
      watermarks.set("uid_artist", Date.now() - 60_000);
      const res = await mintSessionTokenHandler(
        request({ uid: "uid_artist", authTimeSec: nowSec() }),
      );
      expect(res).toEqual({ token: "custom-token-for:uid_artist" });
    });
});
