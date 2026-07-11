/// Durable Object behavior: WebSocket auth handshake, relay delivery,
/// hibernation ping/pong, socket caps, self-destruct alarm, creation quota.

import { SELF, env, fetchMock, runInDurableObject } from "cloudflare:test";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { createJar } from "./helpers";

beforeAll(() => {
  fetchMock.activate();
  fetchMock.disableNetConnect();
});
afterEach(() => fetchMock.assertNoPendingInterceptors());

const DAY_MS = 86_400_000;

function mockTurnstile(times = 1) {
  fetchMock
    .get("https://challenges.cloudflare.com")
    .intercept({ path: "/turnstile/v0/siteverify", method: "POST" })
    .reply(200, { success: true })
    .times(times);
}

async function openSocket(jarId: string): Promise<WebSocket> {
  const res = await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}/ws`, {
    headers: { Upgrade: "websocket" },
  });
  expect(res.status).toBe(101);
  const ws = res.webSocket!;
  ws.accept();
  return ws;
}

function nextMessage(ws: WebSocket, timeoutMs = 2_000): Promise<string> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("timed out waiting for message")), timeoutMs);
    ws.addEventListener(
      "message",
      (ev) => {
        clearTimeout(timer);
        resolve(ev.data as string);
      },
      { once: true },
    );
  });
}

function nextClose(ws: WebSocket, timeoutMs = 2_000): Promise<{ code: number }> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("timed out waiting for close")), timeoutMs);
    ws.addEventListener(
      "close",
      (ev) => {
        clearTimeout(timer);
        resolve({ code: ev.code });
      },
      { once: true },
    );
  });
}

async function authedSocket(jarId: string, secret: string): Promise<WebSocket> {
  const ws = await openSocket(jarId);
  const ready = nextMessage(ws);
  ws.send(JSON.stringify({ type: "auth", secret }));
  expect(JSON.parse(await ready)).toEqual({ type: "ready" });
  return ws;
}

describe("WebSocket auth", () => {
  it("closes with 4401 on a wrong secret", async () => {
    const { jarId } = await createJar();
    const ws = await openSocket(jarId);
    const closed = nextClose(ws);
    ws.send(JSON.stringify({ type: "auth", secret: "wrong" }));
    expect((await closed).code).toBe(4401);
  });

  it("closes with 4401 on a malformed first frame", async () => {
    const { jarId } = await createJar();
    const ws = await openSocket(jarId);
    const closed = nextClose(ws);
    ws.send("not json at all");
    expect((await closed).code).toBe(4401);
  });

  it("closes a socket that never authenticates with 4408, not the terminal 4401", async () => {
    // 4401 means "your secret is no good — re-link". A socket that simply ran
    // out of time on a slow link must not strand the artist there.
    const { jarId } = await createJar();
    const ws = await openSocket(jarId);
    const closed = nextClose(ws);
    const stub = env.JAR.get(env.JAR.idFromName(jarId));
    await runInDurableObject(stub, async (instance, state) => {
      for (const socket of state.getWebSockets()) {
        socket.serializeAttachment({ authed: false, since: Date.now() - 60_000 });
      }
      await instance.alarm();
    });
    expect((await closed).code).toBe(4408);
  });

  it("answers ready on the right secret and pongs pings", async () => {
    const { jarId, secret } = await createJar();
    const ws = await authedSocket(jarId, secret);
    const pong = nextMessage(ws);
    ws.send('{"type":"ping"}');
    expect(JSON.parse(await pong)).toEqual({ type: "pong" });
    ws.close();
  });

  it("completes the upgrade then closes 4410 for a gone jar (terminal re-link signal)", async () => {
    const { jarId, secret } = await createJar();
    await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${secret}` },
    });
    const res = await SELF.fetch(`https://api.live.tips/v1/jars/${jarId}/ws`, {
      headers: { Upgrade: "websocket" },
    });
    expect(res.status).toBe(101);
    const ws = res.webSocket!;
    ws.accept();
    expect((await nextClose(ws)).code).toBe(4410);
  });

  it("also closes 4410 for a never-existed jar id (no DO instantiated)", async () => {
    const res = await SELF.fetch("https://api.live.tips/v1/jars/abcdefghjkmnpqrstvwxyz0123/ws", {
      headers: { Upgrade: "websocket" },
    });
    expect(res.status).toBe(101);
    const ws = res.webSocket!;
    ws.accept();
    expect((await nextClose(ws)).code).toBe(4410);
  });
});

describe("tip relay to connected device", () => {
  function postTip(jarId: string, amountMinor: number, message = "encore!") {
    return SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
      method: "POST",
      headers: { "content-type": "application/json", "CF-Connecting-IP": "198.51.100.7" },
      body: JSON.stringify({
        method: "revolut",
        amountMinor,
        name: "Grace",
        message,
        turnstileToken: "test-token",
      }),
    });
  }

  it("delivers the tip event to an authed socket", async () => {
    const { jarId, secret } = await createJar();
    const ws = await authedSocket(jarId, secret);
    const incoming = nextMessage(ws);
    mockTurnstile();
    const res = await postTip(jarId, 500);
    expect(res.status).toBe(200);
    expect((await res.json<{ delivered: boolean }>()).delivered).toBe(true);
    const event = JSON.parse(await incoming);
    expect(event).toMatchObject({
      type: "tip",
      method: "revolut",
      amountMinor: 500,
      currency: "eur",
      name: "Grace",
      message: "encore!",
    });
    expect(typeof event.ts).toBe("number");
    ws.close();
  });

  it("delivers a Monzo tip as GBP even though the jar is EUR", async () => {
    // The tip event is what the artist's device records into its local history.
    // If this said "eur", a £5 Monzo tip would be filed as €5 forever — the
    // whole reason a tip's currency follows the method, not the jar.
    const { jarId, secret } = await createJar({
      currency: "eur",
      methods: { revolutUsername: "mekedron", monzoUsername: "daniel" },
    });
    const ws = await authedSocket(jarId, secret);
    const incoming = nextMessage(ws);
    mockTurnstile();
    const res = await SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
      method: "POST",
      headers: { "content-type": "application/json", "CF-Connecting-IP": "198.51.100.9" },
      body: JSON.stringify({
        method: "monzo",
        amountMinor: 500,
        name: "Grace",
        message: "encore!",
        turnstileToken: "test-token",
      }),
    });
    expect(res.status).toBe(200);
    expect(JSON.parse(await incoming)).toMatchObject({
      method: "monzo",
      amountMinor: 500,
      currency: "gbp", // …not the jar's eur
    });
    ws.close();
  });

  it("does not relay identical duplicates inside the window", async () => {
    const { jarId, secret } = await createJar();
    const ws = await authedSocket(jarId, secret);
    const received: string[] = [];
    ws.addEventListener("message", (ev) => received.push(ev.data as string));

    mockTurnstile(3);
    expect((await postTip(jarId, 500)).status).toBe(200);
    expect((await postTip(jarId, 500)).status).toBe(200); // duplicate — accepted, dropped
    expect((await postTip(jarId, 800)).status).toBe(200); // distinct — relayed

    // Drain: wait until the second real event arrives.
    const deadline = Date.now() + 2_000;
    while (received.length < 2 && Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 25));
    }
    expect(received).toHaveLength(2);
    expect(JSON.parse(received[0]!).amountMinor).toBe(500);
    expect(JSON.parse(received[1]!).amountMinor).toBe(800);
    ws.close();
  });
});

describe("socket cap", () => {
  it("evicts the oldest authed connection beyond the limit", async () => {
    const { jarId, secret } = await createJar();
    const first = await authedSocket(jarId, secret);
    const evicted = nextClose(first, 4_000);
    const rest = [
      await authedSocket(jarId, secret),
      await authedSocket(jarId, secret),
      await authedSocket(jarId, secret), // 4th connection → oldest goes
    ];
    expect((await evicted).code).toBe(1008);
    for (const ws of rest) ws.close();
  });

  it("never evicts the artist's authed socket to admit an anonymous flood", async () => {
    const { jarId, secret } = await createJar();
    const artist = await authedSocket(jarId, secret);
    let artistClosed = false;
    artist.addEventListener("close", () => { artistClosed = true; });

    // Flood with silent, never-authenticating sockets.
    for (let i = 0; i < 6; i++) {
      const flood = await openSocket(jarId);
      await new Promise((r) => setTimeout(r, 20));
      // Each is allowed to be closed (1008) — that's the point.
      flood.addEventListener("error", () => {});
    }
    await new Promise((r) => setTimeout(r, 50));
    expect(artistClosed).toBe(false);

    // The artist can still receive a relayed tip.
    const incoming = nextMessage(artist);
    mockTurnstile();
    await SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
      method: "POST",
      headers: { "content-type": "application/json", "CF-Connecting-IP": "198.51.100.9" },
      body: JSON.stringify({ method: "revolut", amountMinor: 500, name: "Ada", message: "hi", turnstileToken: "t" }),
    });
    expect(JSON.parse(await incoming).method).toBe("revolut");
    artist.close();
  });
});

function postSecretTip(jarId: string) {
  return SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
    method: "POST",
    headers: { "content-type": "application/json", "CF-Connecting-IP": "198.51.100.11" },
    body: JSON.stringify({
      method: "revolut",
      amountMinor: 500,
      name: "SecretName",
      message: "SecretMessage",
      turnstileToken: "t",
    }),
  });
}

function postTipNamed(jarId: string, amountMinor: number, message: string) {
  return SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
    method: "POST",
    headers: { "content-type": "application/json", "CF-Connecting-IP": "198.51.100.12" },
    body: JSON.stringify({ method: "revolut", amountMinor, name: "Zoe", message, turnstileToken: "t" }),
  });
}

async function storageDump(jarId: string): Promise<string> {
  const stub = env.JAR.get(env.JAR.idFromName(jarId));
  let dump = "";
  await runInDurableObject(stub, async (_instance, state) => {
    dump = JSON.stringify([...(await state.storage.list()).entries()]);
  });
  return dump;
}

describe("no donor content at rest", () => {
  it("keeps nothing but a hashed dedupe signature once the tip is delivered", async () => {
    const { jarId, secret } = await createJar();
    const ws = await authedSocket(jarId, secret);
    const incoming = nextMessage(ws);
    mockTurnstile();
    await postSecretTip(jarId);
    await incoming; // delivered live — never queued

    const dump = await storageDump(jarId);
    expect(dump).not.toContain("SecretName");
    expect(dump).not.toContain("SecretMessage");
    expect(dump).not.toContain("pending");
    ws.close();
  });

  it("holds an UNDELIVERED tip only under `pending`, and lets go of it on delivery", async () => {
    const { jarId, secret } = await createJar();
    mockTurnstile();
    await postSecretTip(jarId); // nobody connected → queued

    // The one exception to "no donor content at rest": a tip in flight to a
    // screen that is away. It lives under `pending` and nowhere else.
    const entries = JSON.parse(await storageDump(jarId)) as [string, unknown][];
    const keysHoldingTheName = entries
      .filter(([, value]) => JSON.stringify(value).includes("SecretName"))
      .map(([key]) => key);
    expect(keysHoldingTheName).toEqual(["pending"]);

    // The artist comes back: the tip is handed over and immediately forgotten.
    const ws = await authedSocket(jarId, secret);
    const replayed = JSON.parse(await nextMessage(ws));
    expect(replayed).toMatchObject({ type: "tip", name: "SecretName", message: "SecretMessage" });

    const after = await storageDump(jarId);
    expect(after).not.toContain("SecretName");
    expect(after).not.toContain("SecretMessage");
    ws.close();
  });

  it("sweeps an undelivered tip after the TTL even if the artist never returns", async () => {
    const { jarId } = await createJar();
    mockTurnstile();
    await postSecretTip(jarId);
    expect(await storageDump(jarId)).toContain("SecretName");

    const stub = env.JAR.get(env.JAR.idFromName(jarId));
    await runInDurableObject(stub, async (instance, state) => {
      // Age the queue past PENDING_TTL_MS (1 h), then let the alarm sweep it.
      const pending = (await state.storage.get<{ ts: number }[]>("pending"))!;
      await state.storage.put(
        "pending",
        pending.map((event) => ({ ...event, ts: event.ts - 2 * 3_600_000 })),
      );
      await instance.alarm!();
    });

    const dump = await storageDump(jarId);
    expect(dump).not.toContain("SecretName");
    expect(dump).not.toContain("SecretMessage");
  });
});

describe("undelivered tips wait for the artist", () => {
  it("queues a tip when no screen is connected, and says so", async () => {
    const { jarId } = await createJar();
    mockTurnstile();
    const res = await postSecretTip(jarId);
    expect(res.status).toBe(200);
    const body = await res.json<{ delivered: boolean; queued: boolean; redirectUrl: string }>();
    // The fan is still sent off to pay — that must never depend on the artist.
    expect(body.redirectUrl).toContain("revolut.me");
    expect(body.delivered).toBe(false);
    expect(body.queued).toBe(true);
  });

  it("replays the backlog in arrival order to the next screen that authenticates", async () => {
    const { jarId, secret } = await createJar();
    mockTurnstile(2);
    await postTipNamed(jarId, 100, "first");
    await postTipNamed(jarId, 200, "second");

    const ws = await authedSocket(jarId, secret);
    const first = JSON.parse(await nextMessage(ws));
    const second = JSON.parse(await nextMessage(ws));
    expect([first.message, second.message]).toEqual(["first", "second"]);
    expect([first.amountMinor, second.amountMinor]).toEqual([100, 200]);
    ws.close();
  });

  it("replays a tip under the id it was queued with, so the app can dedupe it", async () => {
    const { jarId, secret } = await createJar();
    mockTurnstile();
    await postTipNamed(jarId, 700, "solo");

    // flushPending() sends before it deletes, so a crash mid-flush replays the
    // batch. That is only safe because the id is minted once, at arrival.
    const stub = env.JAR.get(env.JAR.idFromName(jarId));
    let queuedId = "";
    await runInDurableObject(stub, async (_instance, state) => {
      queuedId = (await state.storage.get<{ id: string }[]>("pending"))![0]!.id;
    });
    expect(queuedId).not.toBe("");

    const ws = await authedSocket(jarId, secret);
    const event = JSON.parse(await nextMessage(ws));
    expect(event.id).toBe(queuedId);
    ws.close();
  });

  it("caps the queue at the hourly quota, dropping the oldest", async () => {
    const { jarId } = await createJar();
    const stub = env.JAR.get(env.JAR.idFromName(jarId));

    // The hourly quota buckets on wall-clock hours, so a set spanning a bucket
    // boundary really can push more than TIPS_PER_HOUR into one TTL window.
    // Seed the queue full, then relay one more.
    const seededAt = Date.now() - 1_000;
    await runInDurableObject(stub, async (_instance, state) => {
      await state.storage.put(
        "pending",
        Array.from({ length: 60 }, (_unused, i) => ({
          type: "tip",
          id: `old-${i}`,
          ts: seededAt,
          method: "revolut",
          amountMinor: 100,
          currency: "eur",
          name: "",
          message: `m${i}`,
        })),
      );
    });

    await runInDurableObject(stub, async (instance) => {
      const result = await instance.relay({
        method: "revolut",
        amountMinor: 999,
        name: "",
        message: "newest",
      });
      expect(result.status).toBe("ok");
    });

    await runInDurableObject(stub, async (_instance, state) => {
      const pending = (await state.storage.get<{ id: string; message: string }[]>("pending"))!;
      expect(pending).toHaveLength(60);
      expect(pending[0]!.id).toBe("old-1"); // "old-0" evicted
      expect(pending.at(-1)!.message).toBe("newest");
    });
  });
});

describe("self-destruct alarm", () => {
  // The alarm handler is invoked directly on the instance: scheduling real
  // alarms through runDurableObjectAlarm races vitest-pool-workers' isolated
  // storage teardown (SQLite WAL) and flakes the whole file.
  it("wipes storage 90 days after last activity", async () => {
    const { jarId } = await createJar();
    const stub = env.JAR.get(env.JAR.idFromName(jarId));

    await runInDurableObject(stub, async (instance, state) => {
      await state.storage.put("lastSeenDay", Math.floor(Date.now() / DAY_MS) - 91);
      await instance.alarm();
      expect(await state.storage.get("profile")).toBeUndefined();
      expect(await state.storage.get("secretHash")).toBeUndefined();
      expect(await state.storage.getAlarm()).toBeNull();
    });

    expect((await SELF.fetch(`https://live.tips/t/${jarId}`)).status).toBe(404);
  });

  it("keeps a fresh jar alive and re-arms the alarm", async () => {
    const { jarId } = await createJar();
    const stub = env.JAR.get(env.JAR.idFromName(jarId));

    await runInDurableObject(stub, async (instance, state) => {
      await instance.alarm();
      expect(await state.storage.get("profile")).toBeDefined();
      const alarm = await state.storage.getAlarm();
      expect(alarm).not.toBeNull();
      expect(alarm!).toBeGreaterThan(Date.now() + 80 * DAY_MS);
    });
  });
});

describe("creation quota", () => {
  it("allows 20 creates per hour per IP hash, then refuses", async () => {
    const registry = env.REGISTRY.get(env.REGISTRY.idFromName("registry"));
    await runInDurableObject(registry, async (instance) => {
      for (let i = 0; i < 20; i++) {
        expect(await instance.checkCreateAllowed("hash-a")).toBe(true);
      }
      expect(await instance.checkCreateAllowed("hash-a")).toBe(false);
      expect(await instance.checkCreateAllowed("hash-b")).toBe(true);
    });
  });
});
