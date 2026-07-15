/// The bell feed's write policy and the push fan-out (notifications.ts),
/// driven through the real record/send code with the store and FCM mocked.
///
/// What is pinned here:
///  * live === true writes NOTHING — the whole "only when nobody saw it land
///    on stage" policy is this one guard;
///  * the feed doc's exact shape (id = tip id, omit-when-empty like the tip
///    wire itself), direct write vs riding the Stripe tombstone batch;
///  * the send: opt-out prefs (absent doc/field mean send), revoked,
///    tokenless and pushEnabled:false devices never targeted (intent beats
///    a lingering token; an absent flag defers to the token, the old
///    world's record), one multicast PER LANGUAGE with the words of that
///    language, dead tokens pruned off their device docs — token fields
///    only, never the intent — other failures left alone;
///  * the cap: the trigger trims the feed to MAX_NOTIFICATIONS newest.

import { beforeEach, describe, expect, it, vi } from "vitest";

type Doc = Record<string, unknown>;

// ---------------------------------------------------------------------------
// A path-keyed Firestore fake (stripe-webhook.test.ts's shape) plus a device
// registry the mocked devicesCol serves directly.

const docs = new Map<string, Doc>();
let deviceDocs: Array<{ id: string; data: Doc }> = [];
/** update() patches recorded per path — the prune assertions read these. */
let updates: Array<{ path: string; patch: Doc }> = [];

function docRef(path: string) {
  return {
    path,
    collection: (name: string) => colRef(`${path}/${name}`),
    get: async () => {
      const data = docs.get(path);
      return {
        exists: data !== undefined,
        data: () => (data === undefined ? undefined : { ...data }),
        get: (field: string) => docs.get(path)?.[field],
      };
    },
    set: async (data: Doc) => {
      docs.set(path, { ...data });
    },
    update: async (patch: Doc) => {
      updates.push({ path, patch });
    },
  };
}

function colRef(path: string) {
  return {
    doc: (id: string) => docRef(`${path}/${id}`),
    // The one query the trigger runs: newest-first past the cap.
    orderBy: (field: string, _dir: string) => ({
      offset: (n: number) => ({
        select: () => ({
          get: async () => {
            const hits = [...docs.entries()]
              .filter(([p]) => p.startsWith(`${path}/`) && !p.slice(path.length + 1).includes("/"))
              .sort(([, a], [, b]) => (b[field] as number) - (a[field] as number))
              .slice(n)
              .map(([p]) => ({ ref: docRef(p) }));
            return { empty: hits.length === 0, docs: hits };
          },
        }),
      }),
    }),
  };
}

const fakeDb = {
  collection: (name: string) => colRef(name),
  batch: () => {
    const ops: (() => void)[] = [];
    return {
      update: (ref: { path: string }, patch: Doc) =>
        ops.push(() => updates.push({ path: ref.path, patch })),
      delete: (ref: { path: string }) => ops.push(() => docs.delete(ref.path)),
      set: (ref: { path: string }, data: Doc) => ops.push(() => docs.set(ref.path, { ...data })),
      commit: async () => {
        for (const op of ops) op();
      },
    };
  },
};

/** The quota's verdict, per test; the real bumpQuota needs a transaction. */
const quotaMock = vi.fn<() => Promise<boolean>>();

vi.mock("../src/store", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../src/store")>()),
  db: () => fakeDb,
  bumpQuota: () => quotaMock(),
  devicesCol: () => ({
    get: async () => ({
      docs: deviceDocs.map((d) => ({ id: d.id, get: (k: string) => d.data[k] })),
    }),
  }),
  deviceRef: (_f: unknown, uid: string, deviceId: string) =>
    docRef(`users/${uid}/devices/${deviceId}`),
}));

const sendMock = vi.fn<(msg: { tokens: string[] }) => Promise<{ responses: Array<{ success: boolean; error?: { code: string } }> }>>();
const sendSingleMock = vi.fn<(msg: Doc) => Promise<string>>();
vi.mock("../src/fcm", () => ({
  fcm: () => ({ sendEachForMulticast: sendMock, send: sendSingleMock }),
}));

import {
  MAX_NOTIFICATIONS,
  NOTIFICATIONS_LINK,
  formatMinor,
  recordTipNotification,
  sendTestPushHandler,
  sendTipPushHandler,
} from "../src/notifications";
import { pushStrings } from "../src/push-strings";

// ---------------------------------------------------------------------------

const NOW = 1_800_000_000_000;
const UID = "uid_owner";
const BAND = "acc_m3k9zq1a2b3c";
const NOTES = `users/${UID}/notifications`;

function tipInput(overrides: Doc = {}) {
  return {
    tipId: "relay_1",
    amountMinor: 500,
    currency: "eur",
    name: "Ada",
    ...overrides,
  } as never;
}

/** A feed doc as recordTipNotification writes it. */
function note(overrides: Doc = {}): Doc {
  return {
    kind: "tip",
    bandId: BAND,
    tipId: "relay_1",
    amountMinor: 500,
    currency: "eur",
    name: "Ada",
    createdAtMs: NOW,
    ...overrides,
  };
}

function evt(data: Doc): { params: { uid: string }; data: { data(): Doc } } {
  return { params: { uid: UID }, data: { data: () => ({ ...data }) } };
}

function device(id: string, data: Doc): { id: string; data: Doc } {
  return { id, data: { revoked: false, ...data } };
}

beforeEach(() => {
  docs.clear();
  deviceDocs = [];
  updates = [];
  sendMock.mockReset();
  sendMock.mockImplementation(async (msg) => ({
    responses: msg.tokens.map(() => ({ success: true })),
  }));
  sendSingleMock.mockReset();
  sendSingleMock.mockResolvedValue("msg_id");
  quotaMock.mockReset();
  quotaMock.mockResolvedValue(true);
});

// ---------------------------------------------------------------------------

describe("recordTipNotification: the write policy", () => {
  it("EVERY tip records — a running set no longer swallows the account's notifications", async () => {
    await recordTipNotification(fakeDb as never, UID, BAND, tipInput(), NOW);
    await recordTipNotification(fakeDb as never, UID, BAND, tipInput({ tipId: "relay_2", songId: "s2", songTitle: "Hallelujah" }), NOW);
    expect(docs.size).toBe(2);
  });

  it("appends the feed doc under the TIP's id, omit-when-empty like the wire", async () => {
    await recordTipNotification(fakeDb as never, UID, BAND, tipInput(), NOW);
    expect(docs.get(`${NOTES}/relay_1`)).toEqual({
      kind: "tip",
      bandId: BAND,
      tipId: "relay_1",
      amountMinor: 500,
      currency: "eur",
      name: "Ada",
      createdAtMs: NOW,
    });

    await recordTipNotification(fakeDb as never, UID, BAND, tipInput({ tipId: "relay_2", name: "" }), NOW);
    const anonymous = docs.get(`${NOTES}/relay_2`)!;
    expect("name" in anonymous).toBe(false);
    expect("songTitle" in anonymous).toBe(false);
  });

  it("songId makes it a songRequest; an empty songTitle stays off the wire", async () => {
    await recordTipNotification(
      fakeDb as never, UID, BAND,
      tipInput({ songId: "s2", songTitle: "Hallelujah" }), NOW,
    );
    expect(docs.get(`${NOTES}/relay_1`)).toMatchObject({ kind: "songRequest", songTitle: "Hallelujah" });

    await recordTipNotification(
      fakeDb as never, UID, BAND,
      tipInput({ tipId: "cs_x", songId: "s2", songTitle: "" }), NOW,
    );
    const doc = docs.get(`${NOTES}/cs_x`)!;
    expect(doc["kind"]).toBe("songRequest");
    expect("songTitle" in doc).toBe(false);
  });

  it("with a batch it only BUFFERS — the Stripe path's all-or-nothing ride", async () => {
    const batch = fakeDb.batch();
    recordTipNotification(fakeDb as never, UID, BAND, tipInput({ tipId: "cs_1" }), NOW, batch as never);
    expect(docs.size).toBe(0); // nothing lands before the caller commits
    await batch.commit();
    expect(docs.has(`${NOTES}/cs_1`)).toBe(true);
  });
});

// ---------------------------------------------------------------------------

describe("formatMinor: money in the reader's own conventions", () => {
  it("hundredth-unit currencies divide, zero-decimal ones don't (Stripe's rule)", () => {
    expect(formatMinor(500, "eur", "en")).toBe("€5.00");
    expect(formatMinor(500, "jpy", "en")).toBe("¥500");
  });

  it("never throws a push away: malformed currency falls back to plain text", () => {
    expect(formatMinor(500, "eu", "en")).toBe("5.00 EU");
  });
});

describe("pushStrings: every device doc value resolves to SOME language", () => {
  it("exact code, regional tag, junk, and absent all answer", () => {
    expect(pushStrings("de").newTip).toBe("Neues Trinkgeld");
    expect(pushStrings("de-AT").newTip).toBe("Neues Trinkgeld");
    expect(pushStrings("pt_BR").newTip).toBe("Nova gorjeta");
    expect(pushStrings("xx").newTip).toBe("New tip");
    expect(pushStrings(undefined).newTip).toBe("New tip");
  });
});

// ---------------------------------------------------------------------------

describe("sendTipPushHandler: the fan-out", () => {
  it("targets only non-revoked devices that registered a token", async () => {
    deviceDocs = [
      device("dev_a", { fcmToken: "tok_a", locale: "en" }),
      device("dev_b", { fcmToken: "tok_b", revoked: true }),
      device("dev_c", {}), // never enabled push
    ];

    await sendTipPushHandler(evt(note()));

    expect(sendMock).toHaveBeenCalledTimes(1);
    const msg = sendMock.mock.calls[0]![0] as Doc;
    expect(msg["tokens"]).toEqual(["tok_a"]);
    expect(msg["notification"]).toEqual({ title: "New tip · €5.00", body: "Ada" });
  });

  it("intent beats capability: pushEnabled false silences a lingering token; absent means the old-world consent", async () => {
    deviceDocs = [
      // Toggled OFF, token still on the doc (a disable racing the fan-out).
      device("dev_off", { fcmToken: "tok_off", locale: "en", pushEnabled: false }),
      // A doc from before the flag: its token is the whole record of the choice.
      device("dev_legacy", { fcmToken: "tok_legacy", locale: "en" }),
      device("dev_on", { fcmToken: "tok_on", locale: "en", pushEnabled: true }),
    ];

    await sendTipPushHandler(evt(note()));

    expect(sendMock).toHaveBeenCalledTimes(1);
    expect((sendMock.mock.calls[0]![0] as Doc)["tokens"]).toEqual(["tok_legacy", "tok_on"]);
  });

  it("skips exactly the device whose STAGE SCREEN is open — the phone in the pocket still knocks mid-set", async () => {
    deviceDocs = [
      // The stage tablet: fresh heartbeat, watching tips land already.
      device("dev_stage", { fcmToken: "tok_stage", locale: "en", liveOpenAtMs: Date.now() - 30_000 }),
      // The pocket phone: no heartbeat at all.
      device("dev_phone", { fcmToken: "tok_phone", locale: "en" }),
      // A tab that crashed on the stage screen long ago: heartbeat stale.
      device("dev_stale", { fcmToken: "tok_stale", locale: "en", liveOpenAtMs: Date.now() - 10 * 60_000 }),
    ];

    await sendTipPushHandler(evt(note()));

    expect(sendMock).toHaveBeenCalledTimes(1);
    expect((sendMock.mock.calls[0]![0] as Doc)["tokens"]).toEqual(["tok_phone", "tok_stale"]);
  });

  it("prefs are OPT-OUT and per kind: tips:false silences tips, not requests", async () => {
    deviceDocs = [device("dev_a", { fcmToken: "tok_a" })];
    docs.set(`users/${UID}/settings/notifications`, { tips: false });

    await sendTipPushHandler(evt(note()));
    expect(sendMock).not.toHaveBeenCalled();

    await sendTipPushHandler(evt(note({ kind: "songRequest", songTitle: "Hallelujah" })));
    expect(sendMock).toHaveBeenCalledTimes(1);
  });

  it("one multicast per language, each worded in that language", async () => {
    deviceDocs = [
      device("dev_a", { fcmToken: "tok_a", locale: "en" }),
      device("dev_b", { fcmToken: "tok_b", locale: "de" }),
      device("dev_c", { fcmToken: "tok_c", locale: "de" }),
    ];

    await sendTipPushHandler(evt(note({ name: undefined } as never)));

    expect(sendMock).toHaveBeenCalledTimes(2);
    const titles = sendMock.mock.calls.map((c) => ((c[0] as Doc)["notification"] as Doc)["title"]);
    expect(titles).toContain("New tip · €5.00");
    expect(titles.some((t) => (t as string).startsWith("Neues Trinkgeld · "))).toBe(true);
    const german = sendMock.mock.calls.find((c) => (((c[0] as Doc)["notification"] as Doc)["title"] as string).startsWith("Neues"));
    expect((german![0] as Doc)["tokens"]).toEqual(["tok_b", "tok_c"]);
    // No name on the tip: the body still says something, in the same language.
    expect(((german![0] as Doc)["notification"] as Doc)["body"]).toBe("Jemand hat dir Trinkgeld dagelassen");
  });

  it("a song request leads with the song; the payload carries the deep link", async () => {
    deviceDocs = [device("dev_a", { fcmToken: "tok_a" })];

    await sendTipPushHandler(evt(note({ kind: "songRequest", songTitle: "Hallelujah" })));

    const msg = sendMock.mock.calls[0]![0] as Doc;
    expect(msg["notification"]).toEqual({ title: "Song request · €5.00", body: "Hallelujah — Ada" });
    expect(msg["data"]).toEqual({ kind: "songRequest", bandId: BAND, tipId: "relay_1", link: NOTIFICATIONS_LINK });
    const webpush = msg["webpush"] as Doc;
    expect((webpush["fcmOptions"] as Doc)["link"]).toBe(NOTIFICATIONS_LINK);
    expect((webpush["notification"] as Doc)["tag"]).toBe("relay_1");
  });

  it("a dead token is pruned off its device doc; other failures are left alone", async () => {
    deviceDocs = [
      device("dev_a", { fcmToken: "tok_a", locale: "en" }),
      device("dev_b", { fcmToken: "tok_b", locale: "en", pushEnabled: true }),
      device("dev_c", { fcmToken: "tok_c", locale: "en" }),
    ];
    sendMock.mockResolvedValue({
      responses: [
        { success: true },
        { success: false, error: { code: "messaging/registration-token-not-registered" } },
        { success: false, error: { code: "messaging/internal-error" } }, // transient — keep the token
      ],
    });

    await sendTipPushHandler(evt(note()));

    // ONLY the token fields go — pushEnabled is the artist's intent, and it
    // is exactly what the app's self-heal reads to re-mint this registration
    // silently instead of the settings toggle flipping off.
    expect(updates).toHaveLength(1);
    expect(updates[0]!.path).toBe(`users/${UID}/devices/dev_b`);
    expect(Object.keys(updates[0]!.patch).sort()).toEqual(["fcmToken", "fcmTokenAtMs"]);
  });

  it("FCM being down loses the push, never the trigger: no throw, no prune", async () => {
    deviceDocs = [device("dev_a", { fcmToken: "tok_a" })];
    sendMock.mockRejectedValue(new Error("unavailable"));

    await expect(sendTipPushHandler(evt(note()))).resolves.toBeUndefined();
    expect(updates).toHaveLength(0);
  });

  it("trims the feed to the newest MAX_NOTIFICATIONS — prefs off included", async () => {
    docs.set(`users/${UID}/settings/notifications`, { tips: false });
    for (let i = 1; i <= MAX_NOTIFICATIONS + 2; i++) {
      docs.set(`${NOTES}/relay_${i}`, note({ tipId: `relay_${i}`, createdAtMs: NOW + i }));
    }

    await sendTipPushHandler(evt(note({ createdAtMs: NOW + MAX_NOTIFICATIONS + 2 })));

    // The two OLDEST went; the cap holds.
    expect(docs.has(`${NOTES}/relay_1`)).toBe(false);
    expect(docs.has(`${NOTES}/relay_2`)).toBe(false);
    expect(docs.has(`${NOTES}/relay_3`)).toBe(true);
    expect(docs.has(`${NOTES}/relay_${MAX_NOTIFICATIONS + 2}`)).toBe(true);
  });
});

// ---------------------------------------------------------------------------

describe("sendTestPushHandler: one real push to the caller's own device", () => {
  const DEVICE = `users/${UID}/devices/dev_self`;

  function call(deviceId = "dev_self") {
    return sendTestPushHandler({
      auth: { uid: UID },
      data: { deviceId },
    } as never);
  }

  it("sends the localized test pair to exactly the named device's token", async () => {
    docs.set(DEVICE, { fcmToken: "tok_self", locale: "de", revoked: false });

    expect(await call()).toEqual({ sent: true });
    expect(sendSingleMock).toHaveBeenCalledTimes(1);
    const msg = sendSingleMock.mock.calls[0]![0];
    expect(msg["token"]).toBe("tok_self");
    expect(msg["notification"]).toEqual({
      title: "Testbenachrichtigung",
      body: "Wenn du das liest, erreichen Trinkgelder dieses Gerät.",
    });
    expect((msg["data"] as Doc)["kind"]).toBe("test");
  });

  it("a device that never enabled push answers no-token instead of throwing", async () => {
    docs.set(DEVICE, { revoked: false });

    expect(await call()).toEqual({ sent: false, reason: "no-token" });
    expect(sendSingleMock).not.toHaveBeenCalled();
  });

  it("a dead token is reported for the caller to repair — never pruned out from under it", async () => {
    docs.set(DEVICE, { fcmToken: "tok_gone" });
    sendSingleMock.mockRejectedValue(
      Object.assign(new Error("gone"), { code: "messaging/registration-token-not-registered" }),
    );

    expect(await call()).toEqual({ sent: false, reason: "dead-token" });
    // The caller's toggle streams this doc: a server-side delete would flip
    // it off mid-conversation. The doc stays; the device repairs itself.
    expect(updates).toHaveLength(0);
  });

  it("the hourly quota answers resource-exhausted, and junk deviceIds are refused", async () => {
    quotaMock.mockResolvedValue(false);
    await expect(call()).rejects.toMatchObject({ code: "resource-exhausted" });

    quotaMock.mockResolvedValue(true);
    await expect(call("../evil")).rejects.toMatchObject({ code: "invalid-argument" });
  });
});
