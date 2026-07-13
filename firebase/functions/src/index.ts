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
import { IP_HASH_SALT, TURNSTILE_SECRET } from "./params";
import { expireJarsHandler, sweepPendingTipsHandler, sweepRateLimitsHandler } from "./sweeps";
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

// ------------------------------------------------------------------- cleanup

export const sweepPendingTips = onSchedule("every 10 minutes", sweepPendingTipsHandler);
export const expireJars = onSchedule("every day 03:00", expireJarsHandler);
export const sweepRateLimits = onSchedule("every 1 hours", sweepRateLimitsHandler);
