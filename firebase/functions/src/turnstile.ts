/// Server-side Turnstile verification. Tokens are single-use; siteverify
/// handles replay. Fails closed: an unreachable siteverify rejects the tip
/// (the tip page keeps a bare deep-link fallback, so payment still works).

export async function verifyTurnstile(token: string, remoteIp: string | null, secret: string): Promise<boolean> {
  if (!secret) return false; // Fail closed on a missing secret, like the salt.
  const body = new FormData();
  body.set("secret", secret);
  body.set("response", token);
  if (remoteIp) body.set("remoteip", remoteIp);
  try {
    const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
      method: "POST",
      body,
    });
    if (!res.ok) return false;
    const data = (await res.json()) as { success?: boolean };
    return data.success === true;
  } catch {
    return false;
  }
}
