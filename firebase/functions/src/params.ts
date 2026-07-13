import { defineSecret, defineString } from "firebase-functions/params";

/**
 * Secrets (never in code or firebase.json): set via
 * `firebase functions:secrets:set TURNSTILE_SECRET` / `IP_HASH_SALT`.
 * IP_HASH_SALT is required: it salts the per-IP quota hashes; unset, the
 * handlers refuse rather than store a reversible digest of a visitor's IP.
 */
export const TURNSTILE_SECRET = defineSecret("TURNSTILE_SECRET");
export const IP_HASH_SALT = defineSecret("IP_HASH_SALT");

/**
 * The public Turnstile sitekey for live.tips — safe to keep in plain config
 * (sitekeys are served in the tip page's HTML); its secret half lives in
 * TURNSTILE_SECRET. Same default as the worker deployed verbatim.
 */
export const TURNSTILE_SITE_KEY = defineString("TURNSTILE_SITE_KEY", {
  default: "0x4AAAAAADxbXSyz6hPQKTiZ",
});
