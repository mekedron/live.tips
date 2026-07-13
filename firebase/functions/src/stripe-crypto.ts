/// Envelope encryption for the Stripe secrets a cloud account parks with us —
/// the restricted key and the webhook signing secret. The design goal is
/// stated once and holds everywhere: a Firestore dump ALONE must be worthless.
///
/// Shape: each secret is sealed with a fresh one-shot AES-256-GCM data key
/// (DEK), and only the DEK — never the secret — goes to Cloud KMS to be
/// wrapped. What Firestore stores is {wrapped DEK, IV, ciphertext+tag}, so
/// reading a secret back requires BOTH the Firestore document and a
/// cryptoKeys.decrypt call that only the functions' service account may make.
/// KMS never sees a Stripe key; Firestore never sees a usable one.
///
/// Fail closed: any malformed envelope, any KMS refusal, any GCM tag mismatch
/// is a thrown error, never a fallback to plaintext or a partial value.

import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

/**
 * The seam to Cloud KMS. The real implementation (kms.ts) calls
 * cryptoKeys.encrypt/decrypt; tests hand in a fake. Deliberately the ONLY
 * surface that touches KMS, so the envelope logic stays pure and testable.
 */
export interface KeyWrapper {
  /** The KMS key resource this wrapper wraps with (recorded in envelopes). */
  readonly kmsKeyName: string;
  wrap(dek: Buffer): Promise<Buffer>;
  unwrap(wrapped: Buffer): Promise<Buffer>;
}

/**
 * What Firestore stores. `v` exists so a future scheme change can coexist
 * with old envelopes; `kmsKeyName` records which key wrapped the DEK, so a
 * key migration can tell old envelopes from new ones. All bytes base64.
 */
export interface Envelope {
  v: 1;
  kmsKeyName: string;
  wrappedDek: string;
  iv: string;
  /** AES-256-GCM ciphertext with the 16-byte auth tag appended. */
  ciphertext: string;
}

const DEK_BYTES = 32;
const IV_BYTES = 12;
const TAG_BYTES = 16;

/** Runtime shape check for data read back from Firestore. Fails closed. */
export function isEnvelope(value: unknown): value is Envelope {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const e = value as Record<string, unknown>;
  return (
    e["v"] === 1 &&
    typeof e["kmsKeyName"] === "string" && e["kmsKeyName"].length > 0 &&
    typeof e["wrappedDek"] === "string" && e["wrappedDek"].length > 0 &&
    typeof e["iv"] === "string" && e["iv"].length > 0 &&
    typeof e["ciphertext"] === "string" && e["ciphertext"].length > 0
  );
}

/** Seals one secret. A fresh DEK and IV every call — envelopes never share. */
export async function sealSecret(plaintext: string, wrapper: KeyWrapper): Promise<Envelope> {
  if (plaintext.length === 0) throw new Error("refusing to seal an empty secret");
  const dek = randomBytes(DEK_BYTES);
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv("aes-256-gcm", dek, iv);
  const body = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const sealed = Buffer.concat([body, cipher.getAuthTag()]);
  const wrappedDek = await wrapper.wrap(dek);
  dek.fill(0);
  return {
    v: 1,
    kmsKeyName: wrapper.kmsKeyName,
    wrappedDek: wrappedDek.toString("base64"),
    iv: iv.toString("base64"),
    ciphertext: sealed.toString("base64"),
  };
}

/**
 * Opens one envelope. The GCM tag makes this authenticated: a flipped bit
 * anywhere in the ciphertext, IV, or DEK surfaces as a throw, not as a
 * silently corrupted key that would then be sent to Stripe.
 */
export async function openSecret(envelope: unknown, wrapper: KeyWrapper): Promise<string> {
  if (!isEnvelope(envelope)) throw new Error("malformed secret envelope");
  const sealed = Buffer.from(envelope.ciphertext, "base64");
  if (sealed.byteLength <= TAG_BYTES) throw new Error("malformed secret envelope");
  const dek = await wrapper.unwrap(Buffer.from(envelope.wrappedDek, "base64"));
  try {
    const decipher = createDecipheriv("aes-256-gcm", dek, Buffer.from(envelope.iv, "base64"));
    decipher.setAuthTag(sealed.subarray(sealed.byteLength - TAG_BYTES));
    return Buffer.concat([
      decipher.update(sealed.subarray(0, sealed.byteLength - TAG_BYTES)),
      decipher.final(),
    ]).toString("utf8");
  } finally {
    dek.fill(0);
  }
}
