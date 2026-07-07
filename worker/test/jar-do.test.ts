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

describe("no donor content at rest", () => {
  it("stores only a hash of the dedupe signature, never the name/message", async () => {
    const { jarId } = await createJar();
    mockTurnstile();
    await SELF.fetch(`https://live.tips/t/${jarId}/tips`, {
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
    const stub = env.JAR.get(env.JAR.idFromName(jarId));
    await runInDurableObject(stub, async (_instance, state) => {
      const dump = JSON.stringify([...(await state.storage.list()).entries()]);
      expect(dump).not.toContain("SecretName");
      expect(dump).not.toContain("SecretMessage");
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
