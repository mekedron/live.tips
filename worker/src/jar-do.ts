/// One Durable Object per jar: ~1 KB of profile, a hashed secret, and the
/// artist's live WebSockets (hibernated between messages). Stores NO tip
/// history — relay() forwards and forgets. Self-destructs via its own alarm
/// 90 days after the artist was last seen; there is no global cleanup job.

import { DurableObject } from "cloudflare:workers";
import { newSecret, sha256Hex, verifySecret } from "./auth";
import { buildRedirectUrl } from "./deeplinks";
import type { Env, JarProfile, TipEvent, TipRequest } from "./types";

const DAY_MS = 86_400_000;
const EXPIRE_DAYS = 90;
const AUTH_DEADLINE_MS = 30_000;
const MAX_SOCKETS = 3;
const MAX_FRAME_BYTES = 4_096;
const TIPS_PER_MINUTE = 6;
const TIPS_PER_HOUR = 60;
const DEDUPE_WINDOW_MS = 60_000;

interface SocketTag {
  authed: boolean;
  since: number;
}

interface RateState {
  minute: number;
  minuteCount: number;
  hour: number;
  hourCount: number;
  recent: { sig: string; ts: number }[];
}

export type AuthedResult = "ok" | "unauthorized" | "gone";

export type RelayResult =
  | { status: "ok"; redirectUrl: string; delivered: number }
  | { status: "gone" }
  | { status: "method-unavailable" }
  | { status: "limited" };

export class JarDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    // Exact-match ping/pong answered without waking the object.
    this.ctx.setWebSocketAutoResponse(
      new WebSocketRequestResponsePair('{"type":"ping"}', '{"type":"pong"}'),
    );
  }

  private registry() {
    return this.env.REGISTRY.get(this.env.REGISTRY.idFromName("registry"));
  }

  // -------------------------------------------------------------------------
  // Lifecycle

  async init(jarId: string, profile: JarProfile, secretHash: string): Promise<"ok" | "exists"> {
    if ((await this.ctx.storage.get("secretHash")) !== undefined) return "exists";
    const now = Date.now();
    const today = Math.floor(now / DAY_MS);
    await this.ctx.storage.put({
      jarId,
      profile,
      secretHash,
      createdAt: now,
      lastSeenDay: today,
    });
    await this.ctx.storage.setAlarm(now + EXPIRE_DAYS * DAY_MS);
    return "ok";
  }

  async getProfile(): Promise<JarProfile | null> {
    return (await this.ctx.storage.get<JarProfile>("profile")) ?? null;
  }

  async update(profile: JarProfile, presentedSecret: string): Promise<AuthedResult> {
    const auth = await this.checkSecret(presentedSecret);
    if (auth !== "ok") return auth;
    await this.ctx.storage.put("profile", profile);
    await this.touch();
    return "ok";
  }

  async seen(presentedSecret: string): Promise<AuthedResult> {
    const auth = await this.checkSecret(presentedSecret);
    if (auth !== "ok") return auth;
    await this.touch();
    return "ok";
  }

  async rotateSecret(presentedSecret: string): Promise<{ secret: string } | AuthedResult> {
    const auth = await this.checkSecret(presentedSecret);
    if (auth !== "ok") return auth;
    const secret = newSecret();
    await this.ctx.storage.put("secretHash", await sha256Hex(secret));
    for (const ws of this.ctx.getWebSockets()) ws.close(4401, "secret rotated");
    await this.touch();
    return { secret };
  }

  async destroy(presentedSecret: string): Promise<AuthedResult> {
    const auth = await this.checkSecret(presentedSecret);
    if (auth !== "ok") return auth;
    await this.purge();
    return "ok";
  }

  /** Unconditional removal — reachable only through the admin route. */
  async purge(): Promise<void> {
    const jarId = await this.ctx.storage.get<string>("jarId");
    for (const ws of this.ctx.getWebSockets()) ws.close(4410, "jar deleted");
    await this.ctx.storage.deleteAll();
    await this.ctx.storage.deleteAlarm();
    if (jarId) {
      await this.registry().remove(jarId).catch(() => {});
    }
  }

  // -------------------------------------------------------------------------
  // Tip relay

  async relay(tip: TipRequest): Promise<RelayResult> {
    const profile = await this.ctx.storage.get<JarProfile>("profile");
    if (!profile) return { status: "gone" };

    const redirectUrl = buildRedirectUrl(profile, tip);
    if (!redirectUrl) return { status: "method-unavailable" };

    const now = Date.now();
    const rate = (await this.ctx.storage.get<RateState>("rate")) ?? {
      minute: 0, minuteCount: 0, hour: 0, hourCount: 0, recent: [],
    };
    const minute = Math.floor(now / 60_000);
    const hour = Math.floor(now / 3_600_000);
    if (rate.minute !== minute) { rate.minute = minute; rate.minuteCount = 0; }
    if (rate.hour !== hour) { rate.hour = hour; rate.hourCount = 0; }
    if (rate.minuteCount >= TIPS_PER_MINUTE || rate.hourCount >= TIPS_PER_HOUR) {
      return { status: "limited" };
    }

    // Identical repeats inside the window are accepted but not relayed —
    // the sender learns nothing, the stage stays clean.
    const sig = `${tip.method}|${tip.amountMinor}|${tip.name}|${tip.message}`;
    rate.recent = rate.recent.filter((r) => now - r.ts < DEDUPE_WINDOW_MS);
    const duplicate = rate.recent.some((r) => r.sig === sig);

    rate.minuteCount += 1;
    rate.hourCount += 1;
    if (!duplicate) rate.recent.push({ sig, ts: now });
    await this.ctx.storage.put("rate", rate);

    let delivered = 0;
    if (!duplicate) {
      const event: TipEvent = {
        type: "tip",
        ts: now,
        method: tip.method,
        amountMinor: tip.amountMinor,
        currency: profile.currency,
        name: tip.name,
        message: tip.message,
      };
      const json = JSON.stringify(event);
      for (const ws of this.ctx.getWebSockets()) {
        const tag = ws.deserializeAttachment() as SocketTag | null;
        if (tag?.authed) {
          try {
            ws.send(json);
            delivered += 1;
          } catch {
            // Socket died between getWebSockets() and send — ignore.
          }
        }
      }
      const jarId = await this.ctx.storage.get<string>("jarId");
      if (jarId) {
        await this.registry().bumpTips(jarId, Math.floor(now / DAY_MS)).catch(() => {});
      }
      // A connected device is proof the artist is active.
      if (delivered > 0) await this.touch();
    }

    return { status: "ok", redirectUrl, delivered };
  }

  // -------------------------------------------------------------------------
  // WebSocket (Hibernation API)

  override async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("expected websocket", { status: 426 });
    }
    if ((await this.ctx.storage.get("secretHash")) === undefined) {
      return new Response("not found", { status: 404 });
    }

    const sockets = this.ctx.getWebSockets();
    if (sockets.length >= MAX_SOCKETS) {
      let oldest: WebSocket | null = null;
      let oldestSince = Infinity;
      for (const ws of sockets) {
        const tag = ws.deserializeAttachment() as SocketTag | null;
        const since = tag?.since ?? 0;
        if (since < oldestSince) { oldestSince = since; oldest = ws; }
      }
      oldest?.close(1008, "too many connections");
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ authed: false, since: Date.now() } satisfies SocketTag);

    // Make sure the auth deadline fires even if the socket goes silent.
    const deadline = Date.now() + AUTH_DEADLINE_MS + 5_000;
    const current = await this.ctx.storage.getAlarm();
    if (current === null || current > deadline) await this.ctx.storage.setAlarm(deadline);

    return new Response(null, { status: 101, webSocket: client });
  }

  override async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer): Promise<void> {
    if (typeof message !== "string") { ws.close(1003, "text frames only"); return; }
    if (message.length > MAX_FRAME_BYTES) { ws.close(1009, "frame too large"); return; }

    const tag = ws.deserializeAttachment() as SocketTag | null;
    if (tag?.authed) return; // Authed sockets only ever ping (auto-answered).

    let secret: unknown;
    try {
      const parsed: unknown = JSON.parse(message);
      if (typeof parsed === "object" && parsed !== null && (parsed as { type?: unknown }).type === "auth") {
        secret = (parsed as { secret?: unknown }).secret;
      }
    } catch {
      // fall through to close
    }
    const storedHash = await this.ctx.storage.get<string>("secretHash");
    if (typeof secret !== "string" || !storedHash || !(await verifySecret(secret, storedHash))) {
      ws.close(4401, "unauthorized");
      return;
    }

    ws.serializeAttachment({ authed: true, since: tag?.since ?? Date.now() } satisfies SocketTag);
    await this.touch();
    ws.send('{"type":"ready"}');
  }

  override async webSocketClose(): Promise<void> {
    // Nothing to clean up — state lives in attachments and storage.
  }

  // -------------------------------------------------------------------------
  // Alarm: auth sweeper + 90-day self-destruct

  override async alarm(): Promise<void> {
    const now = Date.now();

    let earliestPending: number | null = null;
    for (const ws of this.ctx.getWebSockets()) {
      const tag = ws.deserializeAttachment() as SocketTag | null;
      if (tag?.authed) continue;
      const deadline = (tag?.since ?? 0) + AUTH_DEADLINE_MS;
      if (now >= deadline) {
        ws.close(4401, "auth timeout");
      } else if (earliestPending === null || deadline < earliestPending) {
        earliestPending = deadline;
      }
    }

    const lastSeenDay = await this.ctx.storage.get<number>("lastSeenDay");
    if (lastSeenDay === undefined) return; // Already purged.

    const expireAt = (lastSeenDay + EXPIRE_DAYS) * DAY_MS;
    if (now >= expireAt) {
      await this.purge();
      return;
    }

    const next = earliestPending === null ? expireAt : Math.min(expireAt, earliestPending + 5_000);
    await this.ctx.storage.setAlarm(next);
  }

  // -------------------------------------------------------------------------
  // Internals

  private async checkSecret(presented: string): Promise<AuthedResult> {
    const storedHash = await this.ctx.storage.get<string>("secretHash");
    if (storedHash === undefined) return "gone";
    return (await verifySecret(presented, storedHash)) ? "ok" : "unauthorized";
  }

  /**
   * Records artist activity. Writes at most once per UTC day and re-arms the
   * self-destruct alarm; same-day touches cost nothing.
   */
  private async touch(): Promise<void> {
    const now = Date.now();
    const today = Math.floor(now / DAY_MS);
    const lastSeenDay = await this.ctx.storage.get<number>("lastSeenDay");
    if (lastSeenDay === today) return;
    await this.ctx.storage.put("lastSeenDay", today);
    const current = await this.ctx.storage.getAlarm();
    const expireAt = now + EXPIRE_DAYS * DAY_MS;
    // Keep a sooner alarm (pending auth sweep) if one is set.
    if (current === null || current > expireAt) await this.ctx.storage.setAlarm(expireAt);
    const jarId = await this.ctx.storage.get<string>("jarId");
    if (jarId) {
      // Awaited (not waitUntil): unfinished background storage access is
      // exactly what the vitest isolated-storage checker flags, and the
      // registry should be consistent before we answer anyway.
      await this.registry().touch(jarId, today).catch(() => {});
    }
  }
}
