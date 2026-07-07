/// Server-side Turnstile verification. Tokens are single-use; siteverify
/// handles replay. Fails closed: an unreachable siteverify rejects the tip
/// (the donor page keeps a bare deep-link fallback, so payment still works).

import type { Env } from "./types";

export async function verifyTurnstile(token: string, remoteIp: string | null, env: Env): Promise<boolean> {
  const body = new FormData();
  body.set("secret", env.TURNSTILE_SECRET);
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
