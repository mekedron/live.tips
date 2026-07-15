/// What a cloud account learns about tips nobody saw land on stage — the
/// bell feed, and the push knock on the door.
///
/// Two halves, joined by one collection:
///
///  * recordTipNotification — called by BOTH money paths (the relay POST in
///    tip.ts, the Stripe webhook) right after the routed tip write. EVERY
///    accepted tip appends users/{uid}/notifications/{tipId} — the bell
///    feed's source of truth and the trigger's kick — whether or not a set
///    is running: a live session no longer swallows the notification for
///    the whole account (it did at first, and Nikita's phone stayed silent
///    through an entire "live" evening because a background tab held the
///    session lease).
///
///  * sendTipPush (onDocumentCreated on that collection — index.ts) — reads
///    the account's notification prefs and its device registry, and fans the
///    FCM message out to every non-revoked device that registered a token,
///    worded per device in the language that device's screen speaks
///    (push-strings.ts). The ONE device it skips is a device whose STAGE
///    SCREEN is visibly open right now (fresh `liveOpenAtMs` heartbeat on
///    its device doc, written by the app's LiveScreen): that screen already
///    shows every tip landing, confetti and all — a default OS banner on
///    top of it is noise. Decoupled from the money paths on purpose: a cold
///    start here delays a push by seconds, never a fan's payment redirect,
///    and FCM being down loses nothing — the feed doc IS the notification,
///    the push is just its delivery.
///
/// The collection is server-written only (rules deny every client write) and
/// the doc id is the tip id: on the Stripe path the doc rides the tombstone
/// batch, so a redelivery race collapses exactly like the tip doc beside it.
/// Unlike relayTips this is NOT a second donation history — it is capped at
/// [MAX_NOTIFICATIONS] and trimmed by the trigger itself; the durable record
/// stays the tip doc.

import type {
  CollectionReference,
  DocumentReference,
  Firestore,
  WriteBatch,
} from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import type { MulticastMessage } from "firebase-admin/messaging";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { fcm } from "./fcm";
import { dataObject, requireUid } from "./jars";
import { pushStrings } from "./push-strings";
import { bumpQuota, db, devicesCol, deviceRef } from "./store";
import { isValidDeviceId, ZERO_DECIMAL } from "./validate";

/** The bell feed's cap — enough to scroll back a busy week, not an archive. */
export const MAX_NOTIFICATIONS = 100;

/** Where a tapped notification lands: the PWA, already on the bell page. */
export const NOTIFICATIONS_LINK = "https://live.tips/app/?open=notifications";

export function notificationsCol(firestore: Firestore, uid: string): CollectionReference {
  return firestore.collection("users").doc(uid).collection("notifications");
}

export function notificationRef(firestore: Firestore, uid: string, tipId: string): DocumentReference {
  return notificationsCol(firestore, uid).doc(tipId);
}

/** users/{uid}/settings/notifications — the app's opt-out flags (see below). */
export function notificationSettingsRef(firestore: Firestore, uid: string): DocumentReference {
  return firestore.collection("users").doc(uid).collection("settings").doc("notifications");
}

/** What either money path knows about an accepted tip, notification-sized. */
export interface TipNotificationInput {
  /** Doc id of the routed tip — becomes this doc's id too. */
  tipId: string;
  amountMinor: number;
  /** Lowercase ISO-4217, the currency the fan actually paid in. */
  currency: string;
  /** Possibly "" — empty means absent on the wire, Tip.toJson style. */
  name: string;
  /** Set on song-request tips (#64); presence decides the kind. */
  songId?: string;
  songTitle?: string;
}

/**
 * The feed write — for EVERY accepted tip, set running or not: whether a
 * given device should stay quiet is that device's own affair (the stage
 * skip in [sendTipPushHandler]), never the account's. Callers must not let
 * this fail the tip: the relay path wraps it in try/catch AFTER its own
 * write landed; the Stripe path hands in its tombstone `batch`, which makes
 * this a free rider on the existing all-or-nothing commit.
 */
export function recordTipNotification(
  firestore: Firestore,
  uid: string,
  bandId: string,
  tip: TipNotificationInput,
  nowMs: number,
  batch?: WriteBatch,
): Promise<void> | void {
  const doc = {
    kind: tip.songId !== undefined ? "songRequest" : "tip",
    bandId,
    tipId: tip.tipId,
    amountMinor: tip.amountMinor,
    currency: tip.currency,
    ...(tip.name !== "" ? { name: tip.name } : {}),
    ...(tip.songTitle !== undefined && tip.songTitle !== "" ? { songTitle: tip.songTitle } : {}),
    createdAtMs: nowMs,
  };
  const ref = notificationRef(firestore, uid, tip.tipId);
  if (batch !== undefined) {
    batch.set(ref, doc);
    return;
  }
  return ref.set(doc).then(() => undefined);
}

/**
 * "€5.00" in the reader's own conventions. Minor units are Stripe's:
 * hundredths everywhere except the zero-decimal currencies (validate.ts),
 * where minor IS major. Intl never gets to throw a push away — an unknown
 * locale or currency code falls back to a plain "5.00 EUR".
 */
export function formatMinor(amountMinor: number, currency: string, locale: string | undefined): string {
  const major = ZERO_DECIMAL.has(currency) ? amountMinor : amountMinor / 100;
  const upper = currency.toUpperCase();
  try {
    return new Intl.NumberFormat(locale ?? "en", { style: "currency", currency: upper }).format(major);
  } catch {
    return `${major.toFixed(ZERO_DECIMAL.has(currency) ? 0 : 2)} ${upper}`;
  }
}

/** The trigger's event, structurally — kept minimal so tests need no
 * firebase-functions plumbing to drive the handler. */
export interface NotificationCreatedEvent {
  params: { uid: string };
  data?: { data(): Record<string, unknown> };
}

/**
 * How fresh a device's `liveOpenAtMs` heartbeat must be to count as "the
 * stage screen is open here right now". The app beats every 60s while the
 * stage is visible and deletes the field on leave/background; two missed
 * beats plus slack means a crashed tab suppresses its own pushes for at
 * most this long.
 */
export const LIVE_SCREEN_STALE_MS = 150_000;

/** A device worth pushing to: registered a token, not revoked. */
interface PushTarget {
  deviceId: string;
  token: string;
  locale: string | undefined;
}

/**
 * onDocumentCreated("users/{uid}/notifications/{noteId}") — index.ts.
 *
 * Prefs are OPT-OUT: an absent settings/notifications doc (every account
 * until it first touches the new Settings section) and an absent field both
 * mean "send" — the real opt-in already happened when the device asked for
 * OS permission and registered its token; without that there is nothing to
 * send to anyway.
 *
 * Dead tokens (uninstalled PWA, browser data cleared) come back as
 * registration-token-not-registered / invalid-argument and get their field
 * deleted, so the registry self-heals; every other failure is logged and
 * dropped — the feed doc already holds the notification, and this trigger
 * deliberately does not retry (see index.ts).
 */
export async function sendTipPushHandler(event: NotificationCreatedEvent): Promise<void> {
  const note = event.data?.data();
  if (note === undefined) return;
  const uid = event.params.uid;
  const firestore = db();

  const kind = note["kind"] === "songRequest" ? "songRequest" : "tip";
  const prefs = (await notificationSettingsRef(firestore, uid).get()).data() ?? {};
  const enabled = kind === "songRequest" ? prefs["songRequests"] !== false : prefs["tips"] !== false;

  if (enabled) {
    const nowMs = Date.now();
    const devices = await devicesCol(firestore, uid).get();
    const targets: PushTarget[] = [];
    for (const doc of devices.docs) {
      if (doc.get("revoked") === true) continue;
      const token = doc.get("fcmToken");
      if (typeof token !== "string" || token === "") continue;
      // The stage skip: THIS device is showing the live screen right now —
      // it watches every tip land with confetti; the phone in the pocket
      // (and every other device) still gets knocked, mid-set included.
      const liveOpen = doc.get("liveOpenAtMs");
      if (typeof liveOpen === "number" && nowMs - liveOpen < LIVE_SCREEN_STALE_MS) continue;
      const locale = doc.get("locale");
      targets.push({
        deviceId: doc.id,
        token,
        locale: typeof locale === "string" ? locale : undefined,
      });
    }
    if (targets.length > 0) {
      // One send per language, not per device: sendEachForMulticast carries
      // one payload for the whole token list, and the words differ by locale.
      const groups = new Map<string, PushTarget[]>();
      for (const t of targets) {
        const key = t.locale ?? "";
        let bucket = groups.get(key);
        if (bucket === undefined) {
          bucket = [];
          groups.set(key, bucket);
        }
        bucket.push(t);
      }
      const dead: string[] = [];
      for (const group of groups.values()) {
        const sent = await sendToGroup(note, kind, group);
        dead.push(...sent);
      }
      if (dead.length > 0) {
        const prune = firestore.batch();
        for (const deviceId of dead) {
          prune.update(deviceRef(firestore, uid, deviceId), {
            fcmToken: FieldValue.delete(),
            fcmTokenAtMs: FieldValue.delete(),
          });
        }
        await prune.commit().catch((e) => {
          console.error(`sendTipPush: token prune failed for ${uid}`, e instanceof Error ? e.message : "");
        });
      }
    }
  }

  // The cap, enforced at the only place that grows the collection — prefs
  // off included, since the feed doc was written either way. Newest
  // MAX_NOTIFICATIONS stay; the durable history remains the tip docs.
  const overflow = await notificationsCol(firestore, uid)
    .orderBy("createdAtMs", "desc")
    .offset(MAX_NOTIFICATIONS)
    .select()
    .get();
  if (!overflow.empty) {
    const trim = firestore.batch();
    for (const doc of overflow.docs) trim.delete(doc.ref);
    await trim.commit();
  }
}

/// How many "Send test notification" taps one account gets per hour — a
/// device check, not a toy siren. The button targets only the caller's own
/// devices, so this bound is about Firestore/FCM churn, not abuse of others.
export const TEST_PUSHES_PER_UID_PER_HOUR = 20;

/**
 * sendTestPush callable — the settings page's "is this device actually
 * reachable?" answered with a REAL push through the whole pipeline, to ONE
 * device: the caller's own, named by deviceId. Returns an honest verdict
 * instead of throwing, so the page can say exactly what to fix: `no-token`
 * (push never enabled here / registration lost), `dead-token` (FCM rejected
 * the stored token) or `send-failed`.
 *
 * A dead token is NOT pruned here, unlike the fan-out path: the device
 * asking is by definition present and watching its own toggle, which streams
 * this very doc — a server-side delete flips that toggle off under the
 * artist's finger with no explanation. The caller repairs instead: discard
 * the stale registration, mint a fresh one, retry — and only switch the
 * toggle off itself, with words, if even that is rejected.
 */
export async function sendTestPushHandler(
  request: CallableRequest,
): Promise<{ sent: boolean; reason?: string }> {
  const uid = requireUid(request);
  const data = dataObject(request);
  const deviceId = data["deviceId"];
  if (typeof deviceId !== "string" || !isValidDeviceId(deviceId)) {
    throw new HttpsError("invalid-argument", "deviceId is required");
  }
  const firestore = db();
  const allowed = await bumpQuota(
    firestore,
    `test-push-${uid}`,
    Math.floor(Date.now() / 3_600_000),
    TEST_PUSHES_PER_UID_PER_HOUR,
    2 * 3_600_000,
  );
  if (!allowed) {
    throw new HttpsError("resource-exhausted", "too many test notifications — try again later");
  }

  const ref = deviceRef(firestore, uid, deviceId);
  const snap = await ref.get();
  const token = snap.get("fcmToken");
  if (typeof token !== "string" || token === "") {
    console.log(`sendTestPush: no token on ${uid}/${deviceId}`);
    return { sent: false, reason: "no-token" };
  }
  const locale = snap.get("locale");
  const strings = pushStrings(typeof locale === "string" ? locale : undefined);

  try {
    await fcm().send({
      token,
      notification: { title: strings.testTitle, body: strings.testBody },
      // kind:"test" is what the page's foreground listener matches on to
      // show "received ✓" when the app is open and the OS banner (rightly)
      // stays away.
      data: { kind: "test" },
      webpush: {
        // A test is NOW or never — nobody wants it landing tomorrow.
        headers: { TTL: "300", Urgency: "high" },
        fcmOptions: { link: "https://live.tips/app/" },
        notification: { icon: "https://live.tips/app/icons/Icon-192.png", tag: "livetips-test" },
      },
      apns: { payload: { aps: { sound: "default" } } },
      android: { notification: { channelId: "tips" } },
    });
    console.log(`sendTestPush: sent to ${uid}/${deviceId}`);
    return { sent: true };
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-argument") {
      console.warn(`sendTestPush: token rejected (${code}) on ${uid}/${deviceId}`);
      return { sent: false, reason: "dead-token" };
    }
    console.error("sendTestPush: send failed", e instanceof Error ? e.message : "");
    return { sent: false, reason: "send-failed" };
  }
}

/** Send one locale group's message; returns deviceIds whose token is dead. */
async function sendToGroup(
  note: Record<string, unknown>,
  kind: "tip" | "songRequest",
  group: PushTarget[],
): Promise<string[]> {
  const locale = group[0]?.locale;
  const strings = pushStrings(locale);
  const amountMinor = typeof note["amountMinor"] === "number" ? note["amountMinor"] : 0;
  const currency = typeof note["currency"] === "string" ? note["currency"] : "eur";
  const name = typeof note["name"] === "string" ? note["name"] : "";
  const songTitle = typeof note["songTitle"] === "string" ? note["songTitle"] : "";
  const bandId = typeof note["bandId"] === "string" ? note["bandId"] : "";
  const tipId = typeof note["tipId"] === "string" ? note["tipId"] : "";

  const amount = formatMinor(amountMinor, currency, locale);
  const title = `${kind === "songRequest" ? strings.songRequest : strings.newTip} · ${amount}`;
  const body = kind === "songRequest"
    ? [songTitle, name].filter((s) => s !== "").join(" — ") || strings.someone
    : (name !== "" ? name : strings.someone);

  const message: MulticastMessage = {
    tokens: group.map((t) => t.token),
    // A notification-message, not data-only, on purpose: the web SDK
    // displays it from the service worker and handles click → link without
    // any handler code of ours in the SW (app/web/firebase-messaging-sw.js
    // stays a config-only shim).
    notification: { title, body },
    data: { kind, bandId, tipId, link: NOTIFICATIONS_LINK },
    webpush: {
      // A day, then let it go: a phone off overnight should catch up from
      // the bell, not from a wall of stale banners. tag keeps every tip its
      // own banner rather than each replacing the last.
      headers: { TTL: "86400", Urgency: "high" },
      fcmOptions: { link: NOTIFICATIONS_LINK },
      notification: { icon: "https://live.tips/app/icons/Icon-192.png", tag: tipId },
    },
    // Wired now, exercised when the native builds get their APNs key /
    // notification channel (phase 2). Harmless on web.
    apns: { payload: { aps: { sound: "default", threadId: bandId } } },
    android: { notification: { channelId: "tips" } },
  };

  try {
    const outcome = await fcm().sendEachForMulticast(message);
    const dead: string[] = [];
    outcome.responses.forEach((r, i) => {
      if (r.success) return;
      const target = group[i];
      const code = r.error?.code;
      if (target !== undefined
          && (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-argument")) {
        dead.push(target.deviceId);
      } else {
        console.warn(`sendTipPush: send failed (${code ?? "unknown"})`);
      }
    });
    return dead;
  } catch (e) {
    // FCM itself down: the push is lost, the feed entry is not. No retry —
    // a late knock for a tip the bell already shows is worse than none.
    console.error("sendTipPush: multicast failed", e instanceof Error ? e.message : "");
    return [];
  }
}
