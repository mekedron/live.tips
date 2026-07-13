/// IDs, secrets, and hashing. The jarId doubles as the Firestore document id
/// (and the public tip URL), so it must be unguessable: 128 bits of entropy.

import { createHash, randomBytes, timingSafeEqual } from "node:crypto";

const CROCKFORD = "0123456789abcdefghjkmnpqrstvwxyz";

/** 16 random bytes → 26-char lowercase Crockford base32 (URL/QR friendly). */
export function newJarId(): string {
  const bytes = randomBytes(16);
  let bits = 0;
  let acc = 0;
  let out = "";
  for (const b of bytes) {
    acc = (acc << 8) | b;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out += CROCKFORD[(acc >>> bits) & 31];
    }
  }
  if (bits > 0) out += CROCKFORD[(acc << (5 - bits)) & 31];
  return out;
}

/** 32 random bytes → 43-char base64url. Returned to the device exactly once. */
export function newSecret(): string {
  return randomBytes(32).toString("base64url");
}

export function sha256Hex(input: string): string {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

/**
 * Key for a per-IP quota. The salt is what makes this a hash rather than an
 * encoding: IPv4 is only 2^32 values, so an unsalted SHA-256 of an IP is
 * reversed by brute force in seconds. The salt is a function secret
 * (`IP_HASH_SALT`); with no salt we derive nothing and the caller must refuse
 * the request — falling back to an unsalted digest would store the IP.
 */
export function ipQuotaKey(ip: string, salt: string, scope: string): string {
  if (!salt) throw new Error("IP_HASH_SALT is not configured");
  return sha256Hex(`${salt}:${scope}:${ip}`);
}

/**
 * Compares a presented secret against the stored SHA-256 hex digest without
 * a timing oracle: both sides are hashed, then compared with the runtime's
 * constant-time primitive.
 */
export function verifySecret(presented: unknown, storedHashHex: string): boolean {
  if (typeof presented !== "string" || presented.length === 0 || presented.length > 128) return false;
  const a = Buffer.from(sha256Hex(presented), "utf8");
  const b = Buffer.from(storedHashHex, "utf8");
  if (a.byteLength !== b.byteLength) return false;
  return timingSafeEqual(a, b);
}
