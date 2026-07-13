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
import { mintSessionTokenHandler } from "./session-token";
import {
  expireJarsHandler,
  sweepLinkCodesHandler,
  sweepPendingTipsHandler,
  sweepRateLimitsHandler,
} from "./sweeps";
import { stripeConnectHandler, stripeDisconnectHandler } from "./stripe-connect";
import { stripeProxyHandler } from "./stripe-proxy";
import { stripeWebhookHandler } from "./stripe-webhook";
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

// ----------------------------------------------- web sign-in bridge (Safari)

// The auth.live.tips bridge page (hosting-public/signin.html) finishes a
// redirect sign-in on its own origin — the only one where Firebase's redirect
// flow survives Safari's storage partitioning — and carries the session back
// to the app as a custom token. A caller mints only for the uid it already is.
export const mintSessionToken = onCall({ cors: true }, mintSessionTokenHandler);

// ------------------------------------------- cloud Stripe (key custody path)
//
// Signed-in cloud accounts only — every handler enforces it with
// requireNonAnonymousUid. The artist's restricted key lives here —
// envelope-encrypted, KMS-wrapped, never on a device — and Stripe pushes
// tips to the webhook; the app stops polling entirely. The local no-account
// mode never touches any of these functions: its key stays in the device
// keychain and talks to api.stripe.com directly, exactly as before.

export const stripeConnect = onCall({ cors: true }, stripeConnectHandler);
export const stripeProxy = onCall({ cors: true }, stripeProxyHandler);
export const stripeDisconnect = onCall({ cors: true }, stripeDisconnectHandler);
/** POST /stripe/webhook/:connectionId, via the Hosting rewrite. Public; the
 * per-connection Stripe signature is the authentication. */
export const stripeWebhook = onRequest(stripeWebhookHandler);

// ------------------------------------------------------------------- cleanup

export const sweepPendingTips = onSchedule("every 10 minutes", sweepPendingTipsHandler);
export const expireJars = onSchedule("every day 03:00", expireJarsHandler);
export const sweepRateLimits = onSchedule("every 1 hours", sweepRateLimitsHandler);
// The QR handshake's short-lived state (linkCodes).
export const sweepLinkCodes = onSchedule("every 1 hours", sweepLinkCodesHandler);
