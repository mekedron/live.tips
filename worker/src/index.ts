/// live.tips relay — router.
///
/// Origins: api.live.tips (custom domain: device API + WS + admin) and
/// live.tips/t/* (zone route: donor pages). Same worker, same handlers.
///
/// Log hygiene: nothing here logs names, messages, secrets, or headers.

import { isAdmin, renderAdminPage, adminPageCsp } from "./admin";
import { newJarId, newSecret, sha256Hex } from "./auth";
import { donorPageCsp, renderDonorPage, renderNotFoundPage } from "./donor-page";
import { verifyTurnstile } from "./turnstile";
import { isValidJarId, readJsonBody, validateProfile, validateTip } from "./validate";
import type { Env, JarProfile } from "./types";

export { JarDO } from "./jar-do";
export { RegistryDO } from "./registry-do";

const DONATE_URL_BASE = "https://live.tips/t/";

const CORS_ORIGINS = new Set(["https://live.tips"]);

function corsHeaders(request: Request): Record<string, string> {
  const origin = request.headers.get("Origin");
  if (!origin) return {};
  const allowed = CORS_ORIGINS.has(origin) || /^http:\/\/localhost(:\d+)?$/.test(origin);
  if (!allowed) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

function json(data: unknown, status = 200, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store", ...extra },
  });
}

async function htmlPage(body: string, status: number, csp: string): Promise<Response> {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Content-Security-Policy": csp,
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      "X-Robots-Tag": "noindex",
    },
  });
}

function bearer(request: Request): string | null {
  const header = request.headers.get("Authorization") ?? "";
  return header.startsWith("Bearer ") ? header.slice(7) : null;
}

/** Accept the WS upgrade then immediately close 4410 — the "jar gone" signal. */
function closeGoneWebSocket(): Response {
  const pair = new WebSocketPair();
  const client = pair[0];
  const server = pair[1];
  server.accept();
  server.close(4410, "jar deleted");
  return new Response(null, { status: 101, webSocket: client });
}

function jarStub(env: Env, jarId: string) {
  return env.JAR.get(env.JAR.idFromName(jarId));
}

function registryStub(env: Env) {
  return env.REGISTRY.get(env.REGISTRY.idFromName("registry"));
}

function methodsSummary(profile: JarProfile): string {
  const parts: string[] = [];
  if (profile.methods.stripeUrl) parts.push("stripe");
  if (profile.methods.revolutUsername) parts.push(`revolut:${profile.methods.revolutUsername}`);
  if (profile.methods.mobilepayBoxId) parts.push("mobilepay");
  if (profile.methods.monzoUsername) parts.push(`monzo:${profile.methods.monzoUsername}`);
  return parts.join(", ");
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";

    if (request.method === "OPTIONS" && path.startsWith("/v1/")) {
      return new Response(null, { status: 204, headers: corsHeaders(request) });
    }

    if (path === "/healthz") return new Response("ok", { headers: { "Cache-Control": "no-store" } });
    if (path === "/robots.txt") return new Response("User-agent: *\nDisallow: /\n");

    // ---------------------------------------------------------------- donor
    const donorMatch = path.match(/^\/t\/([^/]+)(\/tips)?$/);
    if (donorMatch) {
      const jarId = donorMatch[1]!;
      const isTips = donorMatch[2] === "/tips";
      // The registry is the existence gate: unknown ids never instantiate a
      // JarDO, so id-guessing costs one registry lookup and nothing else.
      if (!isValidJarId(jarId) || !(await registryStub(env).has(jarId))) {
        if (isTips) return json({ error: "not found" }, 404);
        return htmlPage(renderNotFoundPage(), 404, await donorPageCsp());
      }

      if (!isTips && (request.method === "GET" || request.method === "HEAD")) {
        const profile = await jarStub(env, jarId).getProfile();
        if (!profile) return htmlPage(renderNotFoundPage(), 404, await donorPageCsp());
        return htmlPage(renderDonorPage(profile, env.TURNSTILE_SITE_KEY), 200, await donorPageCsp());
      }

      if (isTips && request.method === "POST") {
        // The form is same-origin by construction; a foreign Origin is a bot.
        const origin = request.headers.get("Origin");
        if (origin && origin !== url.origin && !CORS_ORIGINS.has(origin)) {
          return json({ error: "forbidden" }, 403);
        }
        if (env.TIPS_LIMITER) {
          const { success } = await env.TIPS_LIMITER.limit({ key: ip });
          if (!success) return json({ error: "too many requests" }, 429, { "Retry-After": "30" });
        }
        const stub = jarStub(env, jarId);
        const profile = await stub.getProfile();
        if (!profile) return json({ error: "not found" }, 404);

        const body = await readJsonBody(request);
        if (!body.ok) return json({ error: body.error }, body.status);
        const tip = validateTip(body.value, profile.currency);
        if (!tip.ok) return json({ error: tip.error }, tip.status);

        if (!(await verifyTurnstile(tip.value.turnstileToken, ip, env))) {
          return json({ error: "verification failed" }, 403);
        }

        const { turnstileToken: _token, ...tipRequest } = tip.value;
        const result = await stub.relay(tipRequest);
        switch (result.status) {
          case "ok":
            // `delivered` = a screen had it in hand; `queued` = it is being
            // held for an artist whose screen is away. Either way the fan's
            // message will be seen; neither is a reason to hide the deep link.
            return json({
              redirectUrl: result.redirectUrl,
              delivered: result.delivered > 0,
              queued: result.queued,
            });
          case "gone":
            return json({ error: "not found" }, 404);
          case "method-unavailable":
            return json({ error: "method not available" }, 422);
          case "limited":
            return json({ error: "too many tips right now" }, 429, { "Retry-After": "30" });
        }
      }

      return json({ error: "method not allowed" }, 405);
    }

    // ---------------------------------------------------------------- admin
    if (path === "/admin" && request.method === "GET") {
      return htmlPage(renderAdminPage(), 200, await adminPageCsp());
    }
    if (path === "/admin/jars" && request.method === "GET") {
      if (!(await isAdmin(request, env))) return json({ error: "unauthorized" }, 401);
      return json(await registryStub(env).list());
    }
    const adminJarMatch = path.match(/^\/admin\/jars\/([^/]+)$/);
    if (adminJarMatch && request.method === "DELETE") {
      if (!(await isAdmin(request, env))) return json({ error: "unauthorized" }, 401);
      const jarId = adminJarMatch[1]!;
      if (isValidJarId(jarId)) {
        await jarStub(env, jarId).purge();
        await registryStub(env).remove(jarId);
      }
      return new Response(null, { status: 204 });
    }

    // ------------------------------------------------------------ device API
    if (path === "/v1/jars" && request.method === "POST") {
      const cors = corsHeaders(request);
      if (env.CREATE_LIMITER) {
        const { success } = await env.CREATE_LIMITER.limit({ key: ip });
        if (!success) return json({ error: "too many requests" }, 429, { "Retry-After": "60", ...cors });
      }
      const allowed = await registryStub(env).checkCreateAllowed(await sha256Hex(`create:${ip}`));
      if (!allowed) return json({ error: "creation limit reached, try later" }, 429, { "Retry-After": "3600", ...cors });

      const body = await readJsonBody(request);
      if (!body.ok) return json({ error: body.error }, body.status, cors);
      const profile = validateProfile(body.value);
      if (!profile.ok) return json({ error: profile.error }, profile.status, cors);

      const jarId = newJarId();
      const secret = newSecret();
      const created = await jarStub(env, jarId).init(jarId, profile.value, await sha256Hex(secret));
      if (created !== "ok") return json({ error: "please retry" }, 500, cors);

      // Awaited (not waitUntil): the registry gates existence for every
      // other route, so it must know the jar before the client does.
      await registryStub(env).upsert({
        jarId,
        artistName: profile.value.artistName,
        methods: methodsSummary(profile.value),
        createdAt: Date.now(),
        lastSeenDay: Math.floor(Date.now() / 86_400_000),
      });

      return json({ jarId, secret, donateUrl: `${DONATE_URL_BASE}${jarId}` }, 201, cors);
    }

    const jarMatch = path.match(/^\/v1\/jars\/([^/]+)(\/ws|\/seen|\/rotate-secret)?$/);
    if (jarMatch) {
      const cors = corsHeaders(request);
      const jarId = jarMatch[1]!;
      const sub = jarMatch[2] ?? "";
      const known = isValidJarId(jarId) && (await registryStub(env).has(jarId));

      if (sub === "/ws" && request.method === "GET") {
        if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
          return json({ error: "expected websocket" }, 426);
        }
        // A gone jar must still speak the WS terminal-close contract: complete
        // the upgrade, then close 4410 — so the artist's app hears "re-link"
        // instead of an HTTP 404 it reads as a transient blip and retries on
        // forever. No Durable Object is touched for an unknown id.
        if (!known) return closeGoneWebSocket();
        return jarStub(env, jarId).fetch(request);
      }

      if (!known) return json({ error: "not found" }, 404, cors);
      const stub = jarStub(env, jarId);

      const secret = bearer(request);
      if (!secret) return json({ error: "unauthorized" }, 401, cors);

      const fail = (r: "unauthorized" | "gone") =>
        r === "gone" ? json({ error: "not found" }, 404, cors) : json({ error: "unauthorized" }, 401, cors);

      if (sub === "/seen" && request.method === "POST") {
        const r = await stub.seen(secret);
        return r === "ok" ? new Response(null, { status: 204, headers: cors }) : fail(r);
      }

      if (sub === "/rotate-secret" && request.method === "POST") {
        const r = await stub.rotateSecret(secret);
        if (typeof r === "string") return fail(r === "gone" ? "gone" : "unauthorized");
        return json({ secret: r.secret }, 200, cors);
      }

      if (sub === "" && request.method === "PUT") {
        const body = await readJsonBody(request);
        if (!body.ok) return json({ error: body.error }, body.status, cors);
        const profile = validateProfile(body.value);
        if (!profile.ok) return json({ error: profile.error }, profile.status, cors);
        const r = await stub.update(profile.value, secret);
        if (r !== "ok") return fail(r);
        ctx.waitUntil(
          registryStub(env)
            .upsert({
              jarId,
              artistName: profile.value.artistName,
              methods: methodsSummary(profile.value),
              createdAt: Date.now(),
              lastSeenDay: Math.floor(Date.now() / 86_400_000),
            })
            .catch(() => {}),
        );
        return json({ ok: true }, 200, cors);
      }

      if (sub === "" && request.method === "DELETE") {
        const r = await stub.destroy(secret);
        if (r !== "ok") return fail(r);
        // Awaited so the donate URL is dead the moment the app hears 204.
        await registryStub(env).remove(jarId);
        return new Response(null, { status: 204, headers: cors });
      }

      return json({ error: "method not allowed" }, 405, cors);
    }

    return json({ error: "not found" }, 404);
  },
} satisfies ExportedHandler<Env>;
