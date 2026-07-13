/// IDs, secrets, and hashing. The jarId doubles as the DO address
/// (idFromName), so it must be unguessable: 128 bits of entropy.

const CROCKFORD = "0123456789abcdefghjkmnpqrstvwxyz";

/** 16 random bytes → 26-char lowercase Crockford base32 (URL/QR friendly). */
export function newJarId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
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
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

export async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * Key for the per-IP jar-creation quota. The salt is what makes this a hash
 * rather than an encoding: IPv4 is only 2^32 values, so an unsalted SHA-256 of
 * an IP is reversed by brute force in seconds. The salt is a Worker secret
 * (`IP_HASH_SALT`); with no salt we derive nothing and the caller must refuse
 * the request — falling back to an unsalted digest would store the IP.
 */
export async function ipQuotaKey(ip: string, salt: string): Promise<string> {
  if (!salt) throw new Error("IP_HASH_SALT is not configured");
  return sha256Hex(`${salt}:create:${ip}`);
}

/**
 * Compares a presented secret against the stored SHA-256 hex digest without
 * a timing oracle: both sides are hashed, then compared with the runtime's
 * constant-time primitive.
 */
export async function verifySecret(presented: string, storedHashHex: string): Promise<boolean> {
  if (typeof presented !== "string" || presented.length === 0 || presented.length > 128) return false;
  const presentedHash = await sha256Hex(presented);
  const a = new TextEncoder().encode(presentedHash);
  const b = new TextEncoder().encode(storedHashHex);
  if (a.byteLength !== b.byteLength) return false;
  return crypto.subtle.timingSafeEqual(a, b);
}

/** Constant-time string equality for bearer tokens (admin). */
export async function timingSafeStringEqual(a: string, b: string): Promise<boolean> {
  // Hash both sides so length differences don't leak through byteLength.
  const [ha, hb] = await Promise.all([sha256Hex(a), sha256Hex(b)]);
  return crypto.subtle.timingSafeEqual(new TextEncoder().encode(ha), new TextEncoder().encode(hb));
}
