/// The fan-facing surface: GET /t/:jarId (SSR tip page) and
/// POST /t/:jarId/tips (validate → Turnstile → rate/dedupe → queue → deep link).
/// One https function, routed here by the Hosting rewrite for /t/**.
///
/// Log hygiene: nothing here logs names, messages, secrets, or headers.

import { randomUUID } from "node:crypto";
import type { Request } from "firebase-functions/v2/https";
import type { Response } from "express";
import { Timestamp } from "firebase-admin/firestore";
import { ipQuotaKey } from "./auth";
import { HOSTING_HOPS, clientIp } from "./client-ip";
import { buildRedirectUrl } from "./deeplinks";
import { methodCurrency } from "./methods";
import { IP_HASH_SALT, TURNSTILE_SECRET, TURNSTILE_SITE_KEY } from "./params";
import {
  DAY_MS,
  DEDUPE_WINDOW_MS,
  MAX_PENDING,
  PENDING_TTL_MS,
  TIPS_PER_HOUR,
  TIPS_PER_IP_PER_HOUR,
  TIPS_PER_MINUTE,
  bumpQuota,
  db,
  dedupeSignature,
  jarIsLive,
  jarRateRef,
  jarRef,
  type JarDoc,
  type PendingTipDoc,
  type RateDoc,
} from "./store";
import { renderNotFoundPage, renderTipPage, tipPageCsp } from "./tip-page";
import { verifyTurnstile } from "./turnstile";
import { isValidJarId, parseJsonBody, validateTip } from "./validate";

// Tip pages are served from the Hosting subdomain; the apex stays on Pages.
const CORS_ORIGINS = new Set(["https://tip.live.tips"]);

function sendJson(res: Response, data: unknown, status = 200, extra: Record<string, string> = {}): void {
  res
    .status(status)
    .set({ "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", ...extra })
    .send(JSON.stringify(data));
}

function sendHtml(res: Response, body: string, status: number): void {
  res
    .status(status)
    .set({
      "Content-Type": "text/html; charset=utf-8",
      "Content-Security-Policy": tipPageCsp(),
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      "X-Robots-Tag": "noindex",
    })
    .send(body);
}

export async function tipHandler(req: Request, res: Response): Promise<void> {
  // The rewrite forwards the original path (/t/:jarId[/tips]); a direct
  // function-URL call carries the same suffix after the function name.
  const match = req.path.match(/\/t\/([^/]+?)(\/tips)?\/?$/);
  if (!match) {
    sendHtml(res, renderNotFoundPage(), 404);
    return;
  }
  const jarId = match[1]!;
  const isTips = match[2] === "/tips";
  const now = Date.now();

  const firestore = db();

  // ------------------------------------------------------------- tip page
  if (!isTips && (req.method === "GET" || req.method === "HEAD")) {
    // Reject junk ids before they ever touch Firestore.
    if (!isValidJarId(jarId)) {
      sendHtml(res, renderNotFoundPage(), 404);
      return;
    }
    const snap = await jarRef(firestore, jarId).get();
    const jar = snap.data() as JarDoc | undefined;
    if (!jarIsLive(jar, now)) {
      sendHtml(res, renderNotFoundPage(), 404);
      return;
    }
    sendHtml(res, renderTipPage(jar.profile, TURNSTILE_SITE_KEY.value()), 200);
    return;
  }

  if (isTips && req.method === "POST") {
    // The form is same-origin by construction; a foreign Origin is a bot.
    const origin = req.get("Origin");
    const self = `${req.protocol}://${req.get("host")}`;
    if (origin && origin !== self && !CORS_ORIGINS.has(origin) && !/^http:\/\/localhost(:\d+)?$/.test(origin)) {
      sendJson(res, { error: "forbidden" }, 403);
      return;
    }

    // Fails closed on a missing salt, like a missing Turnstile secret does:
    // the quota key is a salted hash of the IP, and an unsalted one would be
    // the IP itself in all but name. No salt, no tip accepted.
    const salt = IP_HASH_SALT.value();
    if (!salt) {
      sendJson(res, { error: "server misconfigured" }, 500);
      return;
    }

    // NOT req.ip: the Hosting-appended header entry is the only address a
    // client cannot write (see client-ip.ts).
    const ip = clientIp(req, HOSTING_HOPS);

    if (!isValidJarId(jarId)) {
      sendJson(res, { error: "not found" }, 404);
      return;
    }
    const ref = jarRef(firestore, jarId);
    const snap = await ref.get();
    const jar = snap.data() as JarDoc | undefined;
    if (!jarIsLive(jar, now)) {
      sendJson(res, { error: "not found" }, 404);
      return;
    }
    const profile = jar.profile;

    const body = parseJsonBody(req.rawBody);
    if (!body.ok) {
      sendJson(res, { error: body.error }, body.status);
      return;
    }

    // Song requests (#64) ride the same POST, marked by songId. They are only
    // sellable while the artist's app holds the window open: enabled config
    // AND an unexpired openUntilMs. Closed is a state, not a shape error —
    // 409, so a fan with a stale page gets "requests are closed" rather than
    // a validation complaint. Plain tips never enter this branch.
    if (body.value["songId"] !== undefined) {
      if (jar.requestsConfig?.enabled !== true || (jar.requestsLive?.openUntilMs ?? 0) <= now) {
        sendJson(res, { error: "requests_closed" }, 409);
        return;
      }
    }

    // Request tips are priced HERE from the jar's own config (songId + votes
    // in, server-computed amountMinor out) — a fan-sent amount is rejected.
    const tip = validateTip(body.value, profile.currency, jar.requestsConfig);
    if (!tip.ok) {
      sendJson(res, { error: tip.error }, tip.status);
      return;
    }

    const { turnstileToken, ...tipRequest } = tip.value;
    const redirectUrl = buildRedirectUrl(profile, tipRequest);
    if (!redirectUrl) {
      sendJson(res, { error: "method not available" }, 422);
      return;
    }

    if (!(await verifyTurnstile(turnstileToken, ip, TURNSTILE_SECRET.value()))) {
      sendJson(res, { error: "verification failed" }, 403);
      return;
    }

    // The per-IP quota spends only AFTER Turnstile has vouched for the
    // request: a junk POST must not consume the bucket of whatever address
    // it claims to be, or 120 of them naming a venue's NAT would 429 every
    // fan in the bar for the rest of the hour.
    const hourBucket = Math.floor(now / 3_600_000);
    const ipAllowed = await bumpQuota(
      firestore,
      ipQuotaKey(ip, salt, "tips"),
      hourBucket,
      TIPS_PER_IP_PER_HOUR,
      2 * 3_600_000,
    );
    if (!ipAllowed) {
      sendJson(res, { error: "too many requests" }, 429, { "Retry-After": "30" });
      return;
    }

    // Per-jar rate caps + 60s dedupe, atomically on private/rate. The tip
    // counters ride the same transaction: the jar snapshot above predates the
    // Turnstile round-trip by hundreds of milliseconds, so a read-modify-write
    // from it loses concurrent increments and can mis-reset tipsToday at
    // midnight — and a blind update against a since-deleted jar would throw
    // the whole batch, a 500 to a fan whose single-use Turnstile token is
    // already spent. The worker had all of this for free inside the DO's
    // single-threaded lock; the transaction restores it.
    const sig = dedupeSignature(tipRequest);
    const outcome = await firestore.runTransaction(async (tx) => {
      const snaps = await tx.getAll(ref, jarRateRef(firestore, jarId));
      const [jarSnap, rateSnap] = [snaps[0]!, snaps[1]!];
      // Deleted mid-flight: nothing left to count on, and no rate doc to
      // resurrect under it. The fan still gets their payment link below.
      if (!jarSnap.exists) return "gone" as const;
      const fresh = jarSnap.data() as JarDoc;
      const rate = (rateSnap.data() as RateDoc | undefined) ?? {
        minute: 0, minuteCount: 0, hour: 0, hourCount: 0, recentSigs: [],
      };
      const ts = Date.now();
      const minute = Math.floor(ts / 60_000);
      const hour = Math.floor(ts / 3_600_000);
      if (rate.minute !== minute) { rate.minute = minute; rate.minuteCount = 0; }
      if (rate.hour !== hour) { rate.hour = hour; rate.hourCount = 0; }
      if (rate.minuteCount >= TIPS_PER_MINUTE || rate.hourCount >= TIPS_PER_HOUR) {
        return "limited" as const;
      }
      rate.recentSigs = rate.recentSigs.filter((r) => ts - r.tsMs < DEDUPE_WINDOW_MS);
      const duplicate = rate.recentSigs.some((r) => r.sig === sig);
      rate.minuteCount += 1;
      rate.hourCount += 1;
      if (!duplicate) {
        rate.recentSigs.push({ sig, tsMs: ts });
        const today = Math.floor(ts / DAY_MS);
        // Deliberately NOT lastSeenDay/expiresAt: a fan tip is not the
        // artist. The worker bumped the 90-day clock only while the artist's
        // device was connected ("a connected device is proof the artist is
        // active"); here that signal is jarSeen and the app's daily profile
        // re-push. Stamping it per tip would let anyone keep an abandoned
        // jar's URL alive forever (see expireJarsHandler).
        tx.update(ref, {
          tipsTotal: fresh.tipsTotal + 1,
          tipsToday: fresh.tipsDay === today ? fresh.tipsToday + 1 : 1,
          tipsDay: today,
        });
      }
      tx.set(jarRateRef(firestore, jarId), rate);
      return duplicate ? ("duplicate" as const) : ("ok" as const);
    });

    if (outcome === "limited") {
      sendJson(res, { error: "too many tips right now" }, 429, { "Retry-After": "30" });
      return;
    }

    if (outcome === "ok") {
      const pendingCol = ref.collection("pendingTips");
      const batch = firestore.batch();

      // Over the cap, the oldest goes: a tip that has been waiting an hour is
      // about to be swept anyway, and the one that just landed is the one the
      // artist is most likely still able to thank someone for.
      const existing = await pendingCol.orderBy("tsMs").select().get();
      const overflow = existing.size - (MAX_PENDING - 1);
      if (overflow > 0) {
        for (const doc of existing.docs.slice(0, overflow)) batch.delete(doc.ref);
      }

      const event: PendingTipDoc = {
        tsMs: now,
        method: tipRequest.method,
        amountMinor: tipRequest.amountMinor,
        // The currency the fan actually paid in — EUR for a Box, GBP for
        // Monzo — not the jar's. This is what the artist's device records.
        currency: methodCurrency(tipRequest.method, profile.currency),
        name: tipRequest.name,
        message: tipRequest.message,
        // Request tips carry which song was bought; the title is the server's
        // own config lookup, safe to hand the app verbatim. Absent keys (not
        // undefined — Firestore refuses those) on plain tips.
        ...(tipRequest.songId !== undefined && tipRequest.songTitle !== undefined
          ? { songId: tipRequest.songId, songTitle: tipRequest.songTitle }
          : {}),
        // The sweep must happen even if the artist never comes back.
        expiresAt: Timestamp.fromMillis(now + PENDING_TTL_MS),
      };
      batch.set(pendingCol.doc(randomUUID()), event);
      await batch.commit();
    }

    // A duplicate — or a jar deleted mid-flight — is accepted but not queued:
    // the sender learns nothing, the stage stays clean, and the fan still
    // gets their payment link.
    sendJson(res, { redirectUrl, queued: outcome === "ok" });
    return;
  }

  if (isTips) {
    sendJson(res, { error: "method not allowed" }, 405);
    return;
  }
  sendHtml(res, renderNotFoundPage(), 405);
}
