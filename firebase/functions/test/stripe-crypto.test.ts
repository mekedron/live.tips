import { describe, expect, it } from "vitest";
import { isEnvelope, openSecret, sealSecret, type Envelope, type KeyWrapper } from "../src/stripe-crypto";

/**
 * A faked KMS: wrapping XORs the DEK with a per-wrapper pad and prefixes a
 * magic byte, so a wrapper with a DIFFERENT pad (a different KMS key) hands
 * back a wrong DEK and GCM must catch it — the same failure shape as a real
 * cross-project decrypt.
 */
function fakeKms(name = "projects/p/locations/l/keyRings/r/cryptoKeys/k", pad = 0x5a): KeyWrapper {
  return {
    kmsKeyName: name,
    async wrap(dek: Buffer): Promise<Buffer> {
      return Buffer.concat([Buffer.from([0xc0]), Buffer.from(dek.map((b) => b ^ pad))]);
    },
    async unwrap(wrapped: Buffer): Promise<Buffer> {
      return Buffer.from(wrapped.subarray(1).map((b) => b ^ pad));
    },
  };
}

const KEY = "rk_test_51NxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789";

describe("sealSecret / openSecret", () => {
  it("round-trips a restricted key through a faked KMS", async () => {
    const kms = fakeKms();
    const envelope = await sealSecret(KEY, kms);
    expect(isEnvelope(envelope)).toBe(true);
    expect(envelope.kmsKeyName).toBe(kms.kmsKeyName);
    await expect(openSecret(envelope, kms)).resolves.toBe(KEY);
  });

  it("round-trips a webhook signing secret too", async () => {
    const kms = fakeKms();
    const whsec = "whsec_9f8e7d6c5b4a39281706f5e4d3c2b1a0";
    await expect(openSecret(await sealSecret(whsec, kms), kms)).resolves.toBe(whsec);
  });

  it("never stores the plaintext or shares DEK/IV between envelopes", async () => {
    const kms = fakeKms();
    const a = await sealSecret(KEY, kms);
    const b = await sealSecret(KEY, kms);
    for (const env of [a, b]) {
      for (const field of [env.wrappedDek, env.iv, env.ciphertext]) {
        expect(Buffer.from(field, "base64").toString("utf8")).not.toContain("rk_");
      }
    }
    expect(a.wrappedDek).not.toBe(b.wrappedDek); // fresh DEK every seal
    expect(a.iv).not.toBe(b.iv);
    expect(a.ciphertext).not.toBe(b.ciphertext);
  });

  it("refuses to seal an empty secret", async () => {
    await expect(sealSecret("", fakeKms())).rejects.toThrow();
  });

  it("throws on a tampered ciphertext (GCM auth, not silent corruption)", async () => {
    const kms = fakeKms();
    const env = await sealSecret(KEY, kms);
    const bytes = Buffer.from(env.ciphertext, "base64");
    bytes[0] = bytes[0]! ^ 0xff;
    await expect(openSecret({ ...env, ciphertext: bytes.toString("base64") }, kms)).rejects.toThrow();
  });

  it("throws on a tampered IV", async () => {
    const kms = fakeKms();
    const env = await sealSecret(KEY, kms);
    const iv = Buffer.from(env.iv, "base64");
    iv[0] = iv[0]! ^ 0x01;
    await expect(openSecret({ ...env, iv: iv.toString("base64") }, kms)).rejects.toThrow();
  });

  it("throws when unwrapped with the WRONG KMS key (a stolen dump + foreign KMS)", async () => {
    const env = await sealSecret(KEY, fakeKms("projects/ours/…/k", 0x5a));
    await expect(openSecret(env, fakeKms("projects/theirs/…/k", 0xa5))).rejects.toThrow();
  });

  it("throws on truncated ciphertext (shorter than a GCM tag)", async () => {
    const kms = fakeKms();
    const env = await sealSecret(KEY, kms);
    await expect(
      openSecret({ ...env, ciphertext: Buffer.from("shorty").toString("base64") }, kms),
    ).rejects.toThrow(/malformed/);
  });
});

describe("isEnvelope", () => {
  it("accepts exactly the sealed shape and nothing looser", async () => {
    const env = await sealSecret(KEY, fakeKms());
    expect(isEnvelope(env)).toBe(true);
    expect(isEnvelope(null)).toBe(false);
    expect(isEnvelope("rk_live_oops")).toBe(false);
    expect(isEnvelope([])).toBe(false);
    expect(isEnvelope({})).toBe(false);
    expect(isEnvelope({ ...env, v: 2 })).toBe(false);
    expect(isEnvelope({ ...env, kmsKeyName: "" })).toBe(false);
    for (const field of ["kmsKeyName", "wrappedDek", "iv", "ciphertext"] as const) {
      const { [field]: _dropped, ...partial } = env as Envelope;
      expect(isEnvelope(partial)).toBe(false);
    }
  });

  it("openSecret fails closed on malformed envelopes read back from Firestore", async () => {
    const kms = fakeKms();
    await expect(openSecret(undefined, kms)).rejects.toThrow(/malformed/);
    await expect(openSecret({ v: 1 }, kms)).rejects.toThrow(/malformed/);
  });
});
