/// One Durable Object per jar: ~1 KB of profile, a hashed secret, the artist's
/// live WebSockets (hibernated between messages), and — only while the artist's
/// screen is away — the handful of tips that have not reached it yet. Keeps NO
/// tip history: a tip is deleted the moment it is delivered, and swept
/// unseen after PENDING_TTL_MS regardless. Self-destructs via its own alarm 90
/// days after the artist was last seen; there is no global cleanup job.

import { DurableObject } from "cloudflare:workers";
import { newSecret, sha256Hex, verifySecret } from "./auth";
import { buildRedirectUrl } from "./deeplinks";
import { methodCurrency } from "./methods";
import type { Env, JarProfile, TipEvent, TipRequest } from "./types";

const DAY_MS = 86_400_000;
const EXPIRE_DAYS = 90;
const AUTH_DEADLINE_MS = 30_000;
const MAX_SOCKETS = 3;
// At most this many un-authenticated sockets may sit open at once (an
// anonymous flood evicts its own oldest instead of the artist's device).
const MAX_UNAUTHED_SOCKETS = 2;
const MAX_FRAME_BYTES = 4_096;
const TIPS_PER_MINUTE = 6;
const TIPS_PER_HOUR = 60;
const DEDUPE_WINDOW_MS = 60_000;

/**
 * How long an undelivered tip waits for the artist's screen before it is
 * deleted unseen. The artist's device drops its socket for entirely ordinary
 * reasons — the phone locks, they tab over to MobilePay to check a payment,
 * they walk behind a wall — and a fan who has already paid must not lose their
 * message to any of that. Long enough to cover a set break; short enough that
 * the relay never becomes a tip history.
 */
const PENDING_TTL_MS = 60 * 60_000;

/**
 * Hard cap on the queue. TIPS_PER_HOUR already bounds what can arrive inside
 * one TTL window, so this only bites if that quota is ever raised.
 */
const MAX_PENDING = TIPS_PER_HOUR;

/** The secret was wrong, or was rotated away. Terminal: the app must re-link. */
const CLOSE_UNAUTHORIZED = 4401;
/**
 * The socket never authenticated in time. Transient — a slow link, not a bad
 * secret — so this must NOT share 4401, which the app treats as terminal.
 */
const CLOSE_AUTH_TIMEOUT = 4408;
/** The jar is gone. Terminal. */
const CLOSE_JAR_DELETED = 4410;

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
  | { status: "ok"; redirectUrl: string; delivered: number; queued: boolean }
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
    for (const ws of this.ctx.getWebSockets()) ws.close(CLOSE_UNAUTHORIZED, "secret rotated");
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
    for (const ws of this.ctx.getWebSockets()) ws.close(CLOSE_JAR_DELETED, "jar deleted");
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
    // the sender learns nothing, the stage stays clean. The signature is
    // HASHED before it touches storage so fan name/message text is never
    // written at rest (the whole point of the relay). `\u0000` separates the
    // fields so `|` inside a name/message can't forge a collision.
    const sig = await sha256Hex(`${tip.method}\u0000${tip.amountMinor}\u0000${tip.name}\u0000${tip.message}`);
    rate.recent = rate.recent.filter((r) => now - r.ts < DEDUPE_WINDOW_MS);
    const duplicate = rate.recent.some((r) => r.sig === sig);

    rate.minuteCount += 1;
    rate.hourCount += 1;
    if (!duplicate) rate.recent.push({ sig, ts: now });
    await this.ctx.storage.put("rate", rate);

    let delivered = 0;
    let queued = false;
    if (!duplicate) {
      const event: TipEvent = {
        type: "tip",
        id: crypto.randomUUID(),
        ts: now,
        method: tip.method,
        amountMinor: tip.amountMinor,
        // The currency the fan actually paid in — EUR for a Box, GBP for
        // Monzo — not the jar's. This is what the artist's device records.
        currency: methodCurrency(tip.method, profile.currency),
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
      // Nobody is holding the other end. The fan is being redirected to pay
      // right now, so dropping the tip here would take their money and lose
      // their message. Hold it for the artist's return instead.
      if (delivered === 0) {
        await this.enqueue(event);
        queued = true;
      }
      const jarId = await this.ctx.storage.get<string>("jarId");
      if (jarId) {
        await this.registry().bumpTips(jarId, Math.floor(now / DAY_MS)).catch(() => {});
      }
      // A connected device is proof the artist is active.
      if (delivered > 0) await this.touch();
    }

    return { status: "ok", redirectUrl, delivered, queued };
  }

  // -------------------------------------------------------------------------
  // Undelivered tips

  /** Everything still inside the TTL window, oldest first. */
  private async freshPending(now: number): Promise<TipEvent[]> {
    const pending = (await this.ctx.storage.get<TipEvent[]>("pending")) ?? [];
    return pending.filter((event) => now - event.ts < PENDING_TTL_MS);
  }

  private async enqueue(event: TipEvent): Promise<void> {
    const pending = await this.freshPending(event.ts);
    pending.push(event);
    // Over the cap, the oldest goes: a tip that has been waiting an hour is
    // about to be swept anyway, and the one that just landed is the one the
    // artist is most likely still able to thank someone for.
    if (pending.length > MAX_PENDING) pending.splice(0, pending.length - MAX_PENDING);
    await this.ctx.storage.put("pending", pending);
    // The sweep must happen even if the artist never comes back.
    await this.armAlarm(event.ts + PENDING_TTL_MS);
  }

  /**
   * Hands a freshly authenticated screen everything it missed, then forgets it.
   * Sends first and deletes after: a crash in between replays the batch to the
   * next socket, and replay is harmless because every tip carries a stable id
   * the app dedupes on. Deleting first would risk the one outcome this whole
   * queue exists to prevent — a paid tip that nobody ever sees.
   */
  private async flushPending(ws: WebSocket): Promise<number> {
    const stored = await this.ctx.storage.get<TipEvent[]>("pending");
    if (!stored?.length) return 0;
    const fresh = stored.filter((event) => Date.now() - event.ts < PENDING_TTL_MS);
    try {
      for (const event of fresh) ws.send(JSON.stringify(event));
    } catch {
      // The socket died mid-flush. Leave the queue for the next device to
      // claim; the TTL sweep still guarantees it cannot outlive its window.
      return 0;
    }
    await this.ctx.storage.delete("pending");
    return fresh.length;
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

    // Evict to make room, but NEVER drop the artist's authenticated socket to
    // admit an anonymous one: the jarId is public (it's on the QR), so anyone
    // can open unauthed sockets. Prefer evicting an unauthed socket; only when
    // every slot is a legitimate authed device do we drop the oldest of those.
    const sockets = this.ctx.getWebSockets();
    const authedCount = sockets.filter(
      (ws) => (ws.deserializeAttachment() as SocketTag | null)?.authed,
    ).length;
    const unauthedCount = sockets.length - authedCount;
    if (unauthedCount >= MAX_UNAUTHED_SOCKETS || sockets.length >= MAX_SOCKETS) {
      let victim: WebSocket | null = null;
      let victimSince = Infinity;
      for (const ws of sockets) {
        const tag = ws.deserializeAttachment() as SocketTag | null;
        const authed = tag?.authed ?? false;
        const since = tag?.since ?? 0;
        // An unauthed socket always outranks an authed one as the victim.
        const rank = (authed ? 1e15 : 0) + since;
        if (rank < victimSince) { victimSince = rank; victim = ws; }
      }
      victim?.close(1008, "too many connections");
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ authed: false, since: Date.now() } satisfies SocketTag);

    // Make sure the auth deadline fires even if the socket goes silent.
    await this.armAlarm(Date.now() + AUTH_DEADLINE_MS + 5_000);

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
      ws.close(CLOSE_UNAUTHORIZED, "unauthorized");
      return;
    }

    ws.serializeAttachment({ authed: true, since: tag?.since ?? Date.now() } satisfies SocketTag);
    // Answer before any bookkeeping. `ready` is the only thing the app waits
    // for, and it gives up after ten seconds; nothing below it — a day-rollover
    // write, a cross-object RPC — is worth making the artist's stage look dead.
    ws.send('{"type":"ready"}');
    await this.flushPending(ws);
    await this.touch();
  }

  override async webSocketClose(): Promise<void> {
    // Nothing to clean up — state lives in attachments and storage.
  }

  // -------------------------------------------------------------------------
  // Alarm: auth sweeper + undelivered-tip sweeper + 90-day self-destruct

  override async alarm(): Promise<void> {
    const now = Date.now();

    let earliestAuthDeadline: number | null = null;
    for (const ws of this.ctx.getWebSockets()) {
      const tag = ws.deserializeAttachment() as SocketTag | null;
      if (tag?.authed) continue;
      const deadline = (tag?.since ?? 0) + AUTH_DEADLINE_MS;
      if (now >= deadline) {
        ws.close(CLOSE_AUTH_TIMEOUT, "auth timeout");
      } else if (earliestAuthDeadline === null || deadline < earliestAuthDeadline) {
        earliestAuthDeadline = deadline;
      }
    }

    // Undelivered tips are the only thing here with a fan's name on it, so
    // they age out on schedule whether or not the artist ever comes back.
    let nextPendingExpiry: number | null = null;
    const pending = await this.ctx.storage.get<TipEvent[]>("pending");
    if (pending?.length) {
      const fresh = pending.filter((event) => now - event.ts < PENDING_TTL_MS);
      if (fresh.length !== pending.length) {
        if (fresh.length === 0) await this.ctx.storage.delete("pending");
        else await this.ctx.storage.put("pending", fresh);
      }
      if (fresh.length > 0) {
        nextPendingExpiry = Math.min(...fresh.map((event) => event.ts)) + PENDING_TTL_MS;
      }
    }

    const lastSeenDay = await this.ctx.storage.get<number>("lastSeenDay");
    if (lastSeenDay === undefined) return; // Already purged.

    const expireAt = (lastSeenDay + EXPIRE_DAYS) * DAY_MS;
    if (now >= expireAt) {
      await this.purge();
      return;
    }

    let next = expireAt;
    if (earliestAuthDeadline !== null) next = Math.min(next, earliestAuthDeadline + 5_000);
    if (nextPendingExpiry !== null) next = Math.min(next, nextPendingExpiry + 1_000);
    await this.ctx.storage.setAlarm(next);
  }

  // -------------------------------------------------------------------------
  // Internals

  private async checkSecret(presented: string): Promise<AuthedResult> {
    const storedHash = await this.ctx.storage.get<string>("secretHash");
    if (storedHash === undefined) return "gone";
    return (await verifySecret(presented, storedHash)) ? "ok" : "unauthorized";
  }

  /** Brings the alarm forward to [at]; never pushes an earlier one back. */
  private async armAlarm(at: number): Promise<void> {
    const current = await this.ctx.storage.getAlarm();
    if (current === null || current > at) await this.ctx.storage.setAlarm(at);
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
    // Keeps a sooner alarm (auth sweep, tip sweep) if one is already set.
    await this.armAlarm(now + EXPIRE_DAYS * DAY_MS);
    const jarId = await this.ctx.storage.get<string>("jarId");
    if (jarId) {
      // Awaited (not waitUntil): unfinished background storage access is
      // exactly what the vitest isolated-storage checker flags, and the
      // registry should be consistent before we answer anyway.
      await this.registry().touch(jarId, today).catch(() => {});
    }
  }
}
