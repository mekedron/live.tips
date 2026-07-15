/// The one Messaging client, lazily — db()'s twin (store.ts, where the Admin
/// SDK app itself is initialized at module load). Its own module so tests can
/// vi.mock the FCM edge and drive sendTipPushHandler without the Admin SDK.

import { getApps, initializeApp } from "firebase-admin/app";
import { getMessaging, type Messaging } from "firebase-admin/messaging";

let cached: Messaging | null = null;

export function fcm(): Messaging {
  if (cached === null) {
    if (getApps().length === 0) initializeApp();
    cached = getMessaging();
  }
  return cached;
}
