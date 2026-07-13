# live.tips relay — Firebase Cloud Functions

The relay: 2nd-gen Cloud Functions (europe-west1, Node 20) + Firestore. It
replaces the Cloudflare Worker relay this project used to run (`worker/`, now
deleted) and keeps its validation, deep-link composition, SSR tip page, rate
caps, dedupe, and privacy invariants; the Worker's Durable Object storage
became the Firestore model below.

Since the cloud-Stripe change it is also the **key-custody backend** for
signed-in accounts: the artist's Stripe restricted key lives here (encrypted,
see below), Stripe pushes tips to a webhook, and the app stops polling. See
[Cloud Stripe](#cloud-stripe-key-custody-webhook-tips-and-the-proxy) — and
read [What changed in the trust model](#what-changed-in-the-trust-model-read-this)
before touching any of it.

## Data model

```
jars/{jarId}                     profile, ownerUid (null unless claimed with
                                 {owned: true}), readerUids[≤5], createdAtMs,
                                 lastSeenDay, tipsDay/tipsToday/tipsTotal,
                                 expiresAt (last activity + 90d)
jars/{jarId}/private/auth        { secretHash }           — server-only
jars/{jarId}/private/rate        minute/hour counters + hashed 60s dedupe sigs
jars/{jarId}/pendingTips/{uuid}  undelivered tips, expiresAt = tsMs + 1h
rateLimits/{key}                 quota buckets (salted IP hashes, uid days)
users/{uid}/devices/{deviceId}   app-written device registry (name, platform,
                                 model?, createdAtMs, lastSeenAtMs); the
                                 revoked/revokedAtMs fields are function-only
                                 (rules pin them; create must say revoked:false)
users/{uid}/private/security     { sessionsValidAfterMs } — function-written
                                 revocation watermark; rules gate all of
                                 users/** on auth_time·1000 ≥ watermark
linkCodes/{codeId}               QR add-device handshake (top-level: the
                                 redeeming device is unauthenticated); uid,
                                 status pending→claimed→confirmed→used |
                                 expired, attempts, requester?, redeemNonceHash,
                                 expiresAt = createdAtMs + 2 min
loginRequests/{requestId}        QR sign-in-on-a-shared-device handshake (the
                                 mirror flow); status pending→approved→used |
                                 expired, displayCode (8 chars), deviceName?,
                                 devicePlatform?, approvedUid?, collectNonceHash,
                                 attempts, expiresAt = createdAtMs + 60 s.
                                 NO client read and NO client write — rules
                                 grant this collection nothing at all
stripeConnections/{connectionId} one connected band's Stripe custody doc:
                                 uid, bandId, key (ENVELOPE — see Cloud
                                 Stripe), livemode, webhookEndpointId,
                                 webhookSecret (envelope), paymentLinkId,
                                 createdAtMs. connectionId is 128-bit random
                                 and doubles as the webhook URL token.
                                 Server-only for EVERY principal, the owner
                                 included — rules grant nothing, explicitly
users/{uid}/private/stripe       { connections: {bandId: connectionId} } —
                                 server-only pointer (NOT client-readable:
                                 rules now open private/security alone)
users/{uid}/bands/{bandId}/      webhook-fed tip queue, doc id = the Stripe
  stripeTips/{cs_…|ch_…}         object id; tsMs, method:"stripe",
                                 amountMinor, currency, name, message,
                                 inPerson, livemode, paymentIntentId?,
                                 expiresAt = arrival + 1h. Owner-readable and
                                 owner-deletable (delivery IS deletion, like
                                 pendingTips); created by the webhook
```

## Functions

- `tip` (https) — GET `/t/:jarId` SSR page, POST `/t/:jarId/tips`. Routed by
  the Hosting rewrite on **tip.live.tips**.
- Callables: `createJar`, `claimJar`, `updateJarProfile`, `deleteJar`,
  `rotateJarSecret`, `jarSeen`. All require Firebase Auth (anonymous ok);
  update/delete/seen accept owner-uid OR the jar secret.
- Device linking (QR handshake, see `src/linkcodes.ts` for the lifecycle):
  `createLinkCode` (auth, NON-anonymous) → `{code, expiresAtMs}`;
  `redeemLinkCode {code, deviceName, devicePlatform}` (no auth, IP-limited)
  → `{nonce}`; `confirmLinkCode {code}` (auth, owner — the anti-phishing
  tap); `collectLinkToken {code, nonce}` (no auth, polled) → `{pending:true}`
  until confirmed, then `{token}` (single-use custom token).
- Shared-device sign-in (the mirror QR handshake, see `src/loginrequests.ts`):
  `createLoginRequest {deviceName, devicePlatform}` (NO auth, IP-limited) →
  `{requestId, displayCode, collectNonce, expiresAtMs}`;
  `describeLoginRequest {code}` (auth) → `{deviceName, devicePlatform,
  expiresAtMs}`; `approveLoginRequest {code}` (auth, **anonymous allowed**);
  `collectLoginToken {requestId, collectNonce}` (no auth, polled ~5 s) →
  `{pending:true}` until approved, then `{token}` (single-use custom token).
  `code` accepts the QR's `requestId` OR the typed `displayCode`.
- Revocation: `revokeDevice {deviceId}` (cooperative flag only) and
  `revokeAllOtherDevices {currentDeviceId}` (NON-anonymous; watermark +
  device flags + `revokeRefreshTokens` — the caller must silently
  re-authenticate afterwards).
- Cloud Stripe (signed-in accounts only, see the dedicated section):
  `stripeConnect`, `stripeProxy`, `stripeDisconnect` (callables) and
  `stripeWebhook` (https, POST `/stripe/webhook/:connectionId` via the
  Hosting rewrite).
- Scheduled: `sweepPendingTips` (10 min — fan text at rest ≤ ~70 min; also
  sweeps the cloud accounts' expired `stripeTips`), `expireJars` (daily;
  unowned jars past expiresAt), `sweepRateLimits` (hourly), `sweepLinkCodes`
  (hourly; link codes AND login requests past expiresAt).

## The two QR flows, side by side

They are mirror images, and confusing them is the only way to get either
wrong. In BOTH, the QR carries an id and nothing else; the token is collectable
only by the device holding a nonce that never appeared in the QR.

|                   | **Add a device** (`linkCodes`)          | **Sign in on a shared device** (`loginRequests`) |
| ----------------- | --------------------------------------- | ------------------------------------------------ |
| Use case          | "Put my account on my new phone."       | "Put my account on the bar's tablet."            |
| Shows the QR      | the **signed-in** device                | the **unsigned** device (the tablet)             |
| Scans the QR      | the new, unsigned device                | the artist's **signed-in** phone                 |
| Who approves      | the signed-in device (`confirmLinkCode`)| the artist's phone (`approveLoginRequest`)       |
| Who gets a token  | the scanner                             | the QR-shower (the tablet)                       |
| Nonce minted at   | redeem (to the scanner)                 | create (to the tablet)                           |
| Statuses          | pending→claimed→confirmed→used          | pending→approved→used                            |
| TTL               | 2 min                                   | **60 s** (the tablet re-mints every ~45 s)       |
| Anonymous callers | may NOT create (would strand a guest)   | **may approve** (a guest's only second screen)   |
| Client reads      | owner may read its own `linkCodes` doc  | **none** — the collection is fully server-only   |

Why each is safe:

- **Add a device.** A photographed QR is useless twice over: redeeming it only
  parks the code in `claimed` until the owner taps confirm on the signed-in
  device, and collecting the token needs the redeem nonce, which only the first
  redeemer ever saw.
- **Sign in on a shared device.** A photographed QR mints nothing: it becomes a
  token only after an already-signed-in human approves it, and only for *that
  human's* uid. So an attacker who scans the tablet's QR can only offer to sign
  **themselves** in to that tablet — they cannot touch the artist's account.
  And they cannot even collect that: `collectLoginToken` requires the
  `collectNonce`, which was handed to the creating tablet alone and is never in
  the QR. The residual risk is a **race**, not a theft (a stranger approving the
  tablet before the artist does), so the tablet must always show *whose* account
  it just signed in as, with a one-tap "not me". 60 s TTL + single use + a
  5-attempt cap per request keeps that window tiny.

The `displayCode` (typed fallback) is 8 characters from a 32-symbol alphabet
with no `0/O/1/I` — 40 bits. `describe`/`approve` are auth-required and
IP-quota'd at 120/h, so a guesser gets ~120 tries an hour against ~2^40 codes,
and a hit buys them nothing but the race above.

## Cloud Stripe (key custody, webhook tips, and the proxy)

For a **signed-in cloud account**, the app no longer holds the artist's
Stripe restricted key and no longer polls `api.stripe.com/v1/events`:

1. `stripeConnect {bandId, key, paymentLinkId?}` validates the key (must be
   `rk_…`; `sk_…` is refused here exactly as the app refuses it at the paste
   box), probes its permissions, **encrypts and stores it server-side**, and
   registers a webhook endpoint on the artist's own Stripe account pointing
   at our receiver. Re-connecting replaces cleanly (new endpoint first, then
   the old endpoint and ciphertext are removed). Returns
   `{ok, livemode, checks}`.
2. Stripe **pushes** each tip to `stripeWebhook`. The per-connection signing
   secret is the authentication; a verified tip is written to
   `users/{uid}/bands/{bandId}/stripeTips/{objectId}` and the artist's
   devices pick it up through the same Firestore-listener mechanism the
   relay's `pendingTips` already uses. No polling at all.
3. `stripeProxy {bandId, op, params?}` covers the handful of non-realtime
   calls the app still needs — a **strict allowlist** (`src/stripe-ops.ts`),
   not a passthrough. The six operations, exactly the calls the app's
   `StripeRequests` makes today (minus the events poll, which no longer
   exists for cloud accounts): `checkKey`, `createTipJar`,
   `updateTipJarDetails`, `deactivatePaymentLink`, `listTips`, `listTaps`.

   `listTips` and `listTaps` are the **reconciliation pair**, and they exist
   because the webhook is a delivery mechanism, not a guarantee: Stripe can
   be late, our function can be down, an artist can disable or delete the
   endpoint in their own dashboard. Both take an optional
   `createdAfterMs` window ("everything since the set started", floored to
   Stripe's whole-second `created[gte]`) plus the usual
   `startingAfter`/`limit` paging, so the app can ask "what did this account
   actually take in since T" on live-session start/resume and periodically
   as a safety net. `listTips` re-reads the QR checkouts; `listTaps`
   (`GET /v1/charges`, filtered server-side to succeeded+paid
   **card-present** charges) is the one that MUST exist: an in-person tap
   appears in no other list, so without it a dropped webhook loses that tip
   from History permanently. The card-present filter is the same
   double-count guard as the webhook's (a QR checkout also produces a
   charge, card-NOT-present), and the sanitizer strips the payer before
   anything goes to a device — above all `billing_details.name`, the
   cardholder read off the chip: a tap is anonymous on stage by design.
   Both return `{…, hasMore, nextCursor}` where `nextCursor` is the last
   RAW item's id — a page can sanitize to nothing (a busy QR night is a
   page of card-not-present charges) and the loop must still advance.
4. `stripeDisconnect {bandId, deactivateLink?}` deletes the webhook endpoint
   from the artist's dashboard (best effort — a revoked key must not strand
   our cleanup), optionally deactivates the payment link, and deletes the
   ciphertext and pointer. Idempotent.

**The local, no-account mode is UNCHANGED and none of this touches it**: its
key stays in the device keychain, its calls go straight to `api.stripe.com`,
and its polling loop is untouched. "No live.tips server between you and
Stripe" remains literally true for that mode — nothing in these functions can
even be addressed without a Firebase uid and a stored connection.

### Key custody: envelope encryption with Cloud KMS

The restricted key and the webhook signing secret are **never stored in
plaintext**. Each is sealed with a fresh one-shot AES-256-GCM data key, and
only that DEK goes to Cloud KMS to be wrapped (`src/stripe-crypto.ts`).
Firestore holds `{wrapped DEK, IV, ciphertext+tag}` — **a Firestore dump
alone is worthless**; reading a key back requires a `cryptoKeys.decrypt`
call that only the functions' service account is allowed to make. KMS never
sees a Stripe key; Firestore never sees a usable one.

One-time setup (owner, `gcloud`), before first deploy of these functions:

```sh
gcloud services enable cloudkms.googleapis.com --project=livetips-app

gcloud kms keyrings create livetips \
  --location=europe-west1 --project=livetips-app

gcloud kms keys create stripe-secrets \
  --keyring=livetips --location=europe-west1 --project=livetips-app \
  --purpose=encryption \
  --rotation-period=90d \
  --next-rotation-time=$(date -u -v+90d +%Y-%m-%dT%H:%M:%SZ)
```

(KMS key rotation re-keys future wraps automatically; old envelopes keep
decrypting because KMS retains prior key versions. Envelopes record the key
resource in `kmsKeyName` so a manual re-wrap migration is possible later.)

IAM — grant the functions' runtime service account encrypt/decrypt on that
key and nothing wider (2nd-gen functions run as the Compute Engine default
service account unless configured otherwise; check with
`gcloud functions describe stripeConnect --region=europe-west1 --format='value(serviceConfig.serviceAccountEmail)'`):

```sh
PROJECT_NUMBER=$(gcloud projects describe livetips-app --format='value(projectNumber)')
gcloud kms keys add-iam-policy-binding stripe-secrets \
  --keyring=livetips --location=europe-west1 --project=livetips-app \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
```

The key resource is resolved at runtime as
`projects/$GCLOUD_PROJECT/locations/europe-west1/keyRings/livetips/cryptoKeys/stripe-secrets`;
override with the `KMS_KEY_RESOURCE` string param if it ever lives elsewhere.
If KMS is unreachable or unconfigured, every custody path **fails closed**
(`internal` / 500) — nothing is ever stored or used unencrypted.

### Stripe restricted-key permissions (the app's onboarding checklist)

The key the artist creates must now carry exactly:

| Resource               | Permission | Why                                            |
| ---------------------- | ---------- | ---------------------------------------------- |
| Checkout Sessions      | **Read**   | History (`listTips`)                           |
| Charges                | **Read**   | in-person tap tips (payloads + `listTaps`)     |
| Payment Links          | **Write**  | create / edit / deactivate the tip link        |
| Products               | **Write**  | the "Tip" product                              |
| Prices                 | **Write**  | the pay-what-you-want price                    |
| Webhook Endpoints      | **Write**  | **NEW** — we register/remove the tip feed      |

**Events — Read is no longer needed** (nothing polls for a cloud account;
the local mode's checklist keeps it). `stripeConnect` probes each of these
read-side and refuses a key that cannot do the job, listing every missing
permission (`failed-precondition`, `details.checks`). Nothing the key can do
moves money: no refunds, no payouts, no transfers, no balance.

### The webhook pipeline, precisely

- **Signature is the auth.** Every request must carry a valid
  `Stripe-Signature` (HMAC-SHA256 over the raw bytes, ±5 min tolerance,
  timing-safe compare — `src/stripe-events.ts`) keyed by *that connection's*
  signing secret. Unverifiable → 400, logged loudly by connectionId, and
  nothing is touched.
- **Filter.** Only `checkout.session.completed` /
  `checkout.session.async_payment_succeeded` for **the band's own payment
  link** with `payment_status == "paid"`, and `charge.succeeded` where
  `payment_method_details.type == "card_present"`, become tips. An artist
  may run other business through the same Stripe account: everything else is
  answered 200 and **not stored** — the privacy policy states this filter.
  The card-present check is the same double-count guard the app's poller
  has always had (a QR checkout also emits `charge.succeeded`).
- **Idempotent by object id.** The queue doc id is the Stripe object id
  (`cs_…`/`ch_…`); `create()` refuses overwrites, so Stripe retries, re-sent
  events, and the completed/async pair for one session all collapse into one
  write (ALREADY_EXISTS → 200). The app's session model dedupes by the same
  id, which also absorbs a redelivery after the doc was consumed.
- **Bounded.** Per-uid quota (600 tips/h across bands; over it → 429 so
  Stripe retries into a later bucket — delayed, not lost) and a 60-doc
  per-band queue cap (oldest goes; a swept QR tip is still in History).
  Undelivered docs expire after 1 h via `sweepPendingTips`.
- **Fast 2xx.** The whole handler is one signature check, one mapping, one
  small batch — far inside Stripe's 20 s timeout.

### What changed in the trust model (read this)

Bluntly: **for a signed-in cloud account, live.tips is now IN the Stripe
path.** Before, the promise was "your key never leaves your device and no
live.tips server sits between you and Stripe" — that promise now belongs to
the local, no-account mode ONLY, where it remains literally true. A cloud
account instead trusts this backend to hold a restricted key and sign Stripe
requests with it.

What a full compromise of this backend (code + KMS decrypt rights) would
allow, and would not:

- **Could:** read connected artists' tip/checkout data (names, messages,
  amounts); create or deactivate payment links, products and prices on their
  accounts; register or delete webhook endpoints; watch tips arrive.
  Payment links it created would still pay **the artist** — the key grants
  no way to redirect funds.
- **Could NOT:** move money out (no refunds, payouts, transfers, balance or
  account permissions on the key); see full card numbers (Stripe never
  exposes them to any key); touch local-mode artists at all (their keys are
  not here); read the keys from a Firestore dump alone (envelope + KMS) or
  from logs (never logged).

The blast radius is bounded by the restricted key's own permission list —
which is why `stripeConnect` refuses anything stronger than it needs, and
especially any `sk_` key, server-side and unconditionally.

## Secrets (required — handlers fail closed when unset)

```sh
firebase functions:secrets:set TURNSTILE_SECRET   # Turnstile server key
firebase functions:secrets:set IP_HASH_SALT      # e.g. `openssl rand -base64 32`
```

Without `IP_HASH_SALT`, jar creation, tip POSTs and both QR flows' IP-quota'd
callables answer 500/internal rather than store an unsalted (brute-forceable)
digest of a visitor's IP. Without
`TURNSTILE_SECRET`, every tip verification fails (403). The public sitekey is
the `TURNSTILE_SITE_KEY` string param (default committed in `src/params.ts`).

The cloud-Stripe surface adds two non-secret **string params** (defaults are
right for production; override for emulators/staging):

- `KMS_KEY_RESOURCE` — the KMS key wrapping the DEKs (default derived from
  the project, see Cloud Stripe above). The Stripe keys themselves are NOT
  function secrets: they are per-artist data, envelope-encrypted in Firestore.
- `STRIPE_WEBHOOK_BASE` — where registered endpoints point (default
  `https://tip.live.tips/stripe/webhook`; the Hosting rewrite routes it to
  the `stripeWebhook` function).

## Firestore TTL policies (recommended)

The scheduled sweeps already delete expired docs, but Firestore TTL policies
are a free backstop. They cannot be declared in firebase.json — set them once
per collection group with gcloud (or Console → Firestore → TTL):

```sh
gcloud firestore fields ttl-policies update expiresAt \
  --collection-group=pendingTips --project=livetips-app
gcloud firestore fields ttl-policies update expiresAt \
  --collection-group=rateLimits --project=livetips-app
gcloud firestore fields ttl-policies update expiresAt \
  --collection-group=linkCodes --project=livetips-app
gcloud firestore fields ttl-policies update expiresAt \
  --collection-group=loginRequests --project=livetips-app
gcloud firestore fields ttl-policies update expiresAt \
  --collection-group=stripeTips --project=livetips-app
```

Do NOT add a TTL policy on `jars.expiresAt`: TTL deletes are unconditional,
but account-owned jars (ownerUid != null) must outlive their expiresAt — only
the `expireJars` sweep checks that, and TTL also would not delete the private/
pendingTips subcollections.

Note: TTL deletes lag up to ~24h; the 10-minute sweep is what actually holds
the "fan text at rest ≤ ~70 min" privacy invariant.

## Hosting / DNS

Hosting serves `firebase/hosting-public/` (a stub that redirects to
https://live.tips) plus the `/t/**` rewrite to the `tip` function. The main
site stays on GitHub Pages at the apex; tip pages move to **tip.live.tips**.

Cutover (later — deploys are wired, DNS is not):

1. Cloudflare DNS: `CNAME tip → livetips-app.web.app`, proxy **OFF** (grey
   cloud — Firebase must terminate TLS to provision its certificate).
2. Firebase console → Hosting → Add custom domain `tip.live.tips`.

## Develop

```sh
cd firebase/functions
npm install
npm run build   # tsc
npm test        # vitest, pure logic only (no emulator)
```

Emulators (auth, firestore, functions, hosting): `firebase emulators:start`
from `firebase/`. Nothing is deployed yet — billing is not enabled.

## Deliberate deviations from the old Worker

- No WebSockets: the artist's app reads `pendingTips` via Firestore listeners
  and deletes docs on display (delivery IS deletion). POST /tips therefore
  can't know `delivered` synchronously and always answers `{redirectUrl,
  queued}` (`queued: false` only for a 60s-window duplicate).
- The per-doc DO alarm becomes the three scheduled sweeps; an unowned jar past
  `expiresAt` is treated as gone by the tip endpoint even before the daily
  sweep removes it.
- The edge burst limiter (12 tips/min/IP) becomes an hourly Firestore bucket
  (120/h/IP, salted hash); per-jar 6/min + 60/h caps are unchanged.
- Jar creation quotas: 20/hour per IP (as before) plus 20/day per uid.
- Receiving a tip extends the jar's `expiresAt`; in the worker only artist
  activity did. (A jar taking tips is not inactive.)
