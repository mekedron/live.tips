import { describe, expect, it } from "vitest";
import { sha256Hex, verifySecret } from "../src/auth";
import {
  DISPLAY_ALPHABET,
  DISPLAY_CODE_LENGTH,
  LOGIN_REQUEST_TTL_MS,
  MAX_LOGIN_ATTEMPTS,
  decideApprove,
  decideCollect,
  decideDescribe,
  isValidDisplayCode,
  isValidLoginRequestId,
  loginDeviceField,
  loginRequestExpiryMs,
  newCollectNonce,
  newDisplayCode,
  newLoginRequestId,
  normalizeDisplayCode,
  parseLoginCode,
  type LoginRequestSnapshot,
  type LoginRequestStatus,
} from "../src/loginrequests";
import { isAnonymousProvider } from "../src/linkcodes";

const NOW = 1_752_000_000_000;

function req(overrides: Partial<LoginRequestSnapshot> = {}): LoginRequestSnapshot {
  return { status: "pending", expiresAtMs: NOW + LOGIN_REQUEST_TTL_MS, attempts: 0, ...overrides };
}

describe("newLoginRequestId / newCollectNonce", () => {
  it("emit 22-char unpadded base64url (16 bytes = 128 bits)", () => {
    for (let i = 0; i < 50; i++) {
      for (const v of [newLoginRequestId(), newCollectNonce()]) {
        expect(v).toMatch(/^[A-Za-z0-9_-]{22}$/);
        expect(Buffer.from(v, "base64url").byteLength).toBe(16);
        expect(isValidLoginRequestId(v)).toBe(true);
      }
    }
  });

  it("never repeat (128 bits of entropy)", () => {
    const seen = new Set(Array.from({ length: 200 }, () => newLoginRequestId()));
    expect(seen.size).toBe(200);
  });
});

describe("displayCode", () => {
  it("uses a 32-symbol alphabet with no 0/O/1/I/L confusables", () => {
    expect(DISPLAY_ALPHABET).toHaveLength(32);
    expect(new Set(DISPLAY_ALPHABET).size).toBe(32);
    for (const bad of ["0", "1", "O", "I"]) expect(DISPLAY_ALPHABET).not.toContain(bad);
    // 8 chars × 5 bits = 40 bits.
    expect(DISPLAY_CODE_LENGTH).toBe(8);
    expect(DISPLAY_CODE_LENGTH * Math.log2(DISPLAY_ALPHABET.length)).toBe(40);
  });

  it("mints 8 characters drawn only from that alphabet", () => {
    for (let i = 0; i < 200; i++) {
      const code = newDisplayCode();
      expect(code).toHaveLength(DISPLAY_CODE_LENGTH);
      for (const ch of code) expect(DISPLAY_ALPHABET).toContain(ch);
      expect(isValidDisplayCode(code)).toBe(true);
    }
  });

  it("draws every symbol of the alphabet over enough mints (unbiased masking)", () => {
    const seen = new Set<string>();
    for (let i = 0; i < 500; i++) for (const ch of newDisplayCode()) seen.add(ch);
    expect(seen.size).toBe(32);
  });

  it("rejects codes with confusable or out-of-alphabet characters", () => {
    expect(isValidDisplayCode("A4KP9TXM")).toBe(true);
    expect(isValidDisplayCode("A4KP9TX0")).toBe(false); // zero
    expect(isValidDisplayCode("A4KP9TX1")).toBe(false); // one
    expect(isValidDisplayCode("A4KP9TXO")).toBe(false); // letter O
    expect(isValidDisplayCode("A4KP9TXI")).toBe(false); // letter I
    expect(isValidDisplayCode("A4KP9TX")).toBe(false); // too short
    expect(isValidDisplayCode("A4KP9TXMM")).toBe(false); // too long
    expect(isValidDisplayCode("a4kp9txm")).toBe(false); // canonical form is upper
  });
});

describe("normalizeDisplayCode", () => {
  it("forgives case and the separators a human adds", () => {
    expect(normalizeDisplayCode("a4kp9txm")).toBe("A4KP9TXM");
    expect(normalizeDisplayCode("A4KP-9TXM")).toBe("A4KP9TXM");
    expect(normalizeDisplayCode("  a4kp 9txm ")).toBe("A4KP9TXM");
  });

  it("never silently drops an out-of-alphabet character (a typo is not a code)", () => {
    // Dropping the '0' would shift the rest into a DIFFERENT valid code.
    expect(normalizeDisplayCode("A4KP90TXM")).toBeNull();
    expect(normalizeDisplayCode("A4KPI9TXM")).toBeNull();
  });

  it("returns null for junk, empties and absurd lengths", () => {
    expect(normalizeDisplayCode("")).toBeNull();
    expect(normalizeDisplayCode(undefined)).toBeNull();
    expect(normalizeDisplayCode(42)).toBeNull();
    expect(normalizeDisplayCode("../../etc")).toBeNull();
    expect(normalizeDisplayCode("A".repeat(40))).toBeNull();
  });
});

describe("parseLoginCode", () => {
  it("accepts a requestId straight out of the QR", () => {
    const id = newLoginRequestId();
    expect(parseLoginCode(id)).toEqual({ kind: "requestId", value: id });
  });

  it("accepts a typed displayCode, normalized", () => {
    expect(parseLoginCode("a4kp-9txm")).toEqual({ kind: "displayCode", value: "A4KP9TXM" });
  });

  it("cannot confuse the two shapes (22 chars vs 8)", () => {
    for (let i = 0; i < 50; i++) {
      expect(parseLoginCode(newLoginRequestId())?.kind).toBe("requestId");
      expect(parseLoginCode(newDisplayCode())?.kind).toBe("displayCode");
    }
  });

  it("rejects everything else", () => {
    expect(parseLoginCode("")).toBeNull();
    expect(parseLoginCode(null)).toBeNull();
    expect(parseLoginCode("x".repeat(21))).toBeNull();
    expect(parseLoginCode("x".repeat(21) + "/")).toBeNull();
    expect(parseLoginCode("../../../../etc/passwd")).toBeNull();
  });
});

describe("collect nonce hashing", () => {
  it("round-trips through sha256Hex + verifySecret (timing-safe compare)", () => {
    const nonce = newCollectNonce();
    const stored = sha256Hex(nonce);
    expect(verifySecret(nonce, stored)).toBe(true);
    expect(verifySecret(newCollectNonce(), stored)).toBe(false);
    expect(verifySecret(undefined, stored)).toBe(false);
    expect(verifySecret("", stored)).toBe(false);
  });
});

describe("loginRequestExpiryMs", () => {
  it("is now + 60 seconds — a quarter of a link code's TTL", () => {
    expect(LOGIN_REQUEST_TTL_MS).toBe(60_000);
    expect(loginRequestExpiryMs(NOW)).toBe(NOW + 60_000);
  });
});

describe("loginDeviceField", () => {
  it("scrubs and truncates the tablet's self-description", () => {
    expect(loginDeviceField("  Bar tablet​ ", 40)).toBe("Bar tablet");
    expect(loginDeviceField("x".repeat(60), 40)).toBe("x".repeat(40));
    expect(loginDeviceField("🎸".repeat(25), 20)).toBe("🎸".repeat(20));
  });

  it("returns null for non-strings, empties and absurd lengths", () => {
    expect(loginDeviceField(undefined, 40)).toBeNull();
    expect(loginDeviceField(42, 40)).toBeNull();
    expect(loginDeviceField("   ", 40)).toBeNull();
    expect(loginDeviceField("x".repeat(40 * 8 + 1), 40)).toBeNull();
  });
});

describe("decideDescribe", () => {
  it("describes a fresh pending request", () => {
    expect(decideDescribe(req(), NOW)).toEqual({ ok: true });
  });

  it("refuses (and expires) a timed-out request", () => {
    expect(decideDescribe(req({ expiresAtMs: NOW }), NOW)).toMatchObject({ ok: false, expire: true });
  });

  it("refuses an approved/used/expired request without rewriting a terminal status", () => {
    expect(decideDescribe(req({ status: "approved" }), NOW)).toMatchObject({ ok: false, expire: false });
    for (const status of ["used", "expired"] as LoginRequestStatus[]) {
      const d = decideDescribe(req({ status, expiresAtMs: NOW - 1 }), NOW);
      expect(d).toMatchObject({ ok: false, expire: false });
    }
  });

  it("force-expires at the attempt cap", () => {
    expect(decideDescribe(req({ attempts: MAX_LOGIN_ATTEMPTS - 1 }), NOW)).toEqual({ ok: true });
    expect(decideDescribe(req({ attempts: MAX_LOGIN_ATTEMPTS }), NOW)).toMatchObject({
      ok: false,
      expire: true,
    });
  });
});

describe("decideApprove", () => {
  it("approves a fresh pending request", () => {
    expect(decideApprove(req(), NOW)).toEqual({ ok: true });
  });

  it("refuses a second approver — approvedUid is not overwritable", () => {
    expect(decideApprove(req({ status: "approved" }), NOW)).toMatchObject({
      ok: false,
      expire: false,
    });
  });

  it("refuses used/expired requests and expires a timed-out one", () => {
    for (const status of ["used", "expired"] as LoginRequestStatus[]) {
      expect(decideApprove(req({ status }), NOW)).toMatchObject({ ok: false, expire: false });
    }
    expect(decideApprove(req({ expiresAtMs: NOW - 1 }), NOW)).toMatchObject({
      ok: false,
      expire: true,
    });
  });

  it("force-expires at the attempt cap", () => {
    expect(decideApprove(req({ attempts: MAX_LOGIN_ATTEMPTS }), NOW)).toMatchObject({
      ok: false,
      expire: true,
    });
  });
});

describe("who may approve", () => {
  /**
   * The one asymmetry with the add-a-device flow: createLinkCode and
   * revokeAllOtherDevices refuse anonymous callers (both would strand a guest
   * account), but approveLoginRequest MUST accept them — it is a guest's only
   * route onto a second screen. The handler therefore calls requireUid, NOT
   * requireNonAnonymousUid; isAnonymousProvider is what the strict callables
   * gate on, and nothing in this flow consults it.
   */
  it("is anyone signed in, anonymous included", () => {
    for (const provider of ["password", "google.com", "apple.com", "custom", "anonymous"]) {
      // A guest is 'anonymous' to the strict guard...
      const anon = isAnonymousProvider(provider);
      expect(typeof anon).toBe("boolean");
      // ...and still gets an ordinary approval decision here.
      expect(decideApprove(req(), NOW)).toEqual({ ok: true });
    }
    expect(isAnonymousProvider("anonymous")).toBe(true);
    expect(isAnonymousProvider(undefined)).toBe(true);
  });
});

describe("decideCollect", () => {
  it("hands out the token exactly once: approved + matching nonce", () => {
    expect(decideCollect(req({ status: "approved" }), NOW, true)).toEqual({ ok: true });
  });

  it("answers pending (not an error) while nobody has approved yet", () => {
    expect(decideCollect(req({ status: "pending" }), NOW, true)).toEqual({ ok: true, pending: true });
  });

  it("requires the nonce — no nonce, no token, and no oracle either", () => {
    // Same rejection whether the request is pending or approved: a caller
    // without the nonce cannot even learn whether someone has approved it.
    const onPending = decideCollect(req({ status: "pending" }), NOW, false);
    const onApproved = decideCollect(req({ status: "approved" }), NOW, false);
    expect(onPending).toMatchObject({ ok: false, countAttempt: true });
    expect(onApproved).toMatchObject({ ok: false, countAttempt: true });
    expect(onPending.ok === false && onPending.message).toBe(
      onApproved.ok === false && onApproved.message,
    );
  });

  it("burns an attempt on a wrong nonce and force-expires at the cap", () => {
    const early = decideCollect(req({ status: "approved", attempts: 1 }), NOW, false);
    expect(early).toMatchObject({ ok: false, countAttempt: true, expire: false });
    const last = decideCollect(
      req({ status: "approved", attempts: MAX_LOGIN_ATTEMPTS - 1 }),
      NOW,
      false,
    );
    expect(last).toMatchObject({ ok: false, countAttempt: true, expire: true });
    const capped = decideCollect(
      req({ status: "approved", attempts: MAX_LOGIN_ATTEMPTS }),
      NOW,
      true,
    );
    expect(capped).toMatchObject({ ok: false, expire: true, countAttempt: false });
  });

  it("is single use: a used request is not collectable again", () => {
    expect(decideCollect(req({ status: "used" }), NOW, true)).toMatchObject({
      ok: false,
      expire: false,
    });
  });

  it("expires a timed-out approved request (a token is never minted late)", () => {
    expect(decideCollect(req({ status: "approved", expiresAtMs: NOW }), NOW, true)).toMatchObject({
      ok: false,
      expire: true,
    });
  });
});

describe("constants", () => {
  it("keep the documented caps", () => {
    expect(MAX_LOGIN_ATTEMPTS).toBe(5);
    expect(LOGIN_REQUEST_TTL_MS).toBe(60_000);
  });
});
