/// live.tips relay on Firebase — function exports only; logic lives in the
/// per-surface modules. 2nd gen, europe-west1, Node 20.

import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  claimJarHandler,
  createJarHandler,
  deleteJarHandler,
  jarSeenHandler,
  rotateJarSecretHandler,
  updateJarProfileHandler,
} from "./jars";
import {
  collectLinkTokenHandler,
  confirmLinkCodeHandler,
  createLinkCodeHandler,
  redeemLinkCodeHandler,
  revokeAllOtherDevicesHandler,
  revokeDeviceHandler,
} from "./devices";
import { IP_HASH_SALT, TURNSTILE_SECRET } from "./params";
import {
  expireJarsHandler,
  sweepLinkCodesHandler,
  sweepPendingTipsHandler,
  sweepRateLimitsHandler,
} from "./sweeps";
import { tipHandler } from "./tip";

setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

// ---------------------------------------------------------------- fan surface

/** GET /t/:jarId (SSR tip page) + POST /t/:jarId/tips, via Hosting rewrite. */
export const tip = onRequest(
  { secrets: [TURNSTILE_SECRET, IP_HASH_SALT] },
  tipHandler,
);

// -------------------------------------------------------------- device surface

export const createJar = onCall({ cors: true, secrets: [IP_HASH_SALT] }, createJarHandler);
export const claimJar = onCall({ cors: true }, claimJarHandler);
export const updateJarProfile = onCall({ cors: true }, updateJarProfileHandler);
export const deleteJar = onCall({ cors: true }, deleteJarHandler);
export const rotateJarSecret = onCall({ cors: true }, rotateJarSecretHandler);
export const jarSeen = onCall({ cors: true }, jarSeenHandler);

// ------------------------------------- device management + QR add-device link

// Signed-in side of the handshake (A). Non-anonymous only for create.
export const createLinkCode = onCall({ cors: true }, createLinkCodeHandler);
export const confirmLinkCode = onCall({ cors: true }, confirmLinkCodeHandler);
// New-device side (B): unauthenticated, hence the salted per-IP quotas.
export const redeemLinkCode = onCall({ cors: true, secrets: [IP_HASH_SALT] }, redeemLinkCodeHandler);
export const collectLinkToken = onCall({ cors: true, secrets: [IP_HASH_SALT] }, collectLinkTokenHandler);
// Revocation: cooperative per-device flag, and the real (token) kill switch.
export const revokeDevice = onCall({ cors: true }, revokeDeviceHandler);
export const revokeAllOtherDevices = onCall({ cors: true }, revokeAllOtherDevicesHandler);

// ------------------------------------------------------------------- cleanup

export const sweepPendingTips = onSchedule("every 10 minutes", sweepPendingTipsHandler);
export const expireJars = onSchedule("every day 03:00", expireJarsHandler);
export const sweepRateLimits = onSchedule("every 1 hours", sweepRateLimitsHandler);
export const sweepLinkCodes = onSchedule("every 1 hours", sweepLinkCodesHandler);
