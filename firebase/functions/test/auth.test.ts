import { describe, expect, it } from "vitest";
import { ipQuotaKey, newJarId, newSecret, sha256Hex, verifySecret } from "../src/auth";
import { dedupeSignature } from "../src/store";
import { isValidJarId } from "../src/validate";

describe("newJarId", () => {
  it("emits 26-char lowercase Crockford base32 that isValidJarId accepts", () => {
    for (let i = 0; i < 50; i++) {
      const id = newJarId();
      expect(id).toMatch(/^[0-9abcdefghjkmnpqrstvwxyz]{26}$/);
      expect(isValidJarId(id)).toBe(true);
    }
  });

  it("never repeats (128 bits of entropy)", () => {
    const seen = new Set(Array.from({ length: 200 }, () => newJarId()));
    expect(seen.size).toBe(200);
  });
});

describe("newSecret", () => {
  it("emits 43-char unpadded base64url (32 bytes)", () => {
    for (let i = 0; i < 50; i++) {
      const s = newSecret();
      expect(s).toMatch(/^[A-Za-z0-9_-]{43}$/);
      expect(Buffer.from(s, "base64url").byteLength).toBe(32);
    }
  });
});

describe("sha256Hex / verifySecret", () => {
  it("produces the standard digest", () => {
    // Known vector: sha256("abc").
    expect(sha256Hex("abc")).toBe("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
  });

  it("verifies a secret against its stored hash and rejects everything else", () => {
    const secret = newSecret();
    const stored = sha256Hex(secret);
    expect(verifySecret(secret, stored)).toBe(true);
    expect(verifySecret(secret + "x", stored)).toBe(false);
    expect(verifySecret("", stored)).toBe(false);
    expect(verifySecret(undefined, stored)).toBe(false);
    expect(verifySecret(42, stored)).toBe(false);
    expect(verifySecret("x".repeat(129), stored)).toBe(false);
  });
});

describe("ipQuotaKey", () => {
  it("throws without a salt (fail closed — never store a bare IP digest)", () => {
    expect(() => ipQuotaKey("1.2.3.4", "", "create")).toThrow();
  });

  it("scopes by salt, scope and ip", () => {
    const a = ipQuotaKey("1.2.3.4", "salt", "create");
    expect(a).toBe(sha256Hex("salt:create:1.2.3.4"));
    expect(ipQuotaKey("1.2.3.4", "salt", "tips")).not.toBe(a);
    expect(ipQuotaKey("1.2.3.5", "salt", "create")).not.toBe(a);
    expect(ipQuotaKey("1.2.3.4", "other", "create")).not.toBe(a);
  });
});

describe("dedupeSignature", () => {
  const tip = { method: "revolut" as const, amountMinor: 500, name: "Ada", message: "great show" };

  it("is stable for identical tips and never stores plaintext", () => {
    const sig = dedupeSignature(tip);
    expect(sig).toBe(dedupeSignature({ ...tip }));
    expect(sig).toMatch(/^[0-9a-f]{64}$/);
    expect(sig).not.toContain("Ada");
    // The exact NUL-separated preimage — byte-for-byte. The trailing empty
    // field is the songId slot (empty for plain tips).
    expect(sig).toBe(sha256Hex("revolut\u0000500\u0000Ada\u0000great show\u0000"));
  });

  it("changes when any field changes", () => {
    const sig = dedupeSignature(tip);
    expect(dedupeSignature({ ...tip, amountMinor: 501 })).not.toBe(sig);
    expect(dedupeSignature({ ...tip, name: "Bea" })).not.toBe(sig);
    expect(dedupeSignature({ ...tip, message: "great show!" })).not.toBe(sig);
    expect(dedupeSignature({ ...tip, method: "monzo" })).not.toBe(sig);
  });

  it("distinguishes song requests by songId — two same-priced songs are two tips", () => {
    // Without the songId in the signature, two anonymous default-priced
    // requests for DIFFERENT songs inside the 60s window would collapse into
    // one, and a fan's paid request would silently vanish from the queue.
    const a = dedupeSignature({ ...tip, songId: "song-a", songTitle: "A" });
    const b = dedupeSignature({ ...tip, songId: "song-b", songTitle: "B" });
    expect(a).not.toBe(b);
    expect(a).not.toBe(dedupeSignature(tip));
  });

  it("cannot be collided across field boundaries", () => {
    // The NUL separator is why: no printable delimiter a fan can type.
    const a = dedupeSignature({ ...tip, name: "Ada", message: "xy" });
    const b = dedupeSignature({ ...tip, name: "Adax", message: "y" });
    expect(a).not.toBe(b);
  });
});
