/// The bridge's token mint: the whole contract is "you get a token for the
/// uid you already are, and only if you are somebody".

import { describe, expect, it, vi } from "vitest";
import type { CallableRequest } from "firebase-functions/v2/https";

vi.mock("firebase-admin/auth", () => ({
  getAuth: () => ({
    createCustomToken: async (uid: string) => `custom-token-for:${uid}`,
  }),
}));

import { mintSessionTokenHandler } from "../src/session-token";

function request(auth: { uid: string } | undefined): CallableRequest {
  return { auth, data: {}, rawRequest: {} } as unknown as CallableRequest;
}

describe("mintSessionToken", () => {
  it("refuses an unauthenticated caller", async () => {
    await expect(mintSessionTokenHandler(request(undefined))).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("mints for the caller's own uid — never anyone else's", async () => {
    const res = await mintSessionTokenHandler(request({ uid: "uid_artist" }));
    expect(res).toEqual({ token: "custom-token-for:uid_artist" });
  });

  it("serves anonymous sessions too — a guest upgrading itself brings an "
    + "anonymous session by definition", async () => {
    // request.auth for an anonymous Firebase user still carries a uid; the
    // handler must not demand a provider.
    const res = await mintSessionTokenHandler(request({ uid: "uid_guest" }));
    expect(res.token).toBe("custom-token-for:uid_guest");
  });
});
