# live.tips relay — Firebase Cloud Functions

The relay: 2nd-gen Cloud Functions (europe-west1, Node 20) + Firestore. It
replaces the Cloudflare Worker relay this project used to run (`worker/`, now
deleted) and keeps its validation, deep-link composition, SSR tip page, rate
caps, dedupe, and privacy invariants; the Worker's Durable Object storage
became the Firestore model below.

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
- Scheduled: `sweepPendingTips` (10 min — fan text at rest ≤ ~70 min),
  `expireJars` (daily; unowned jars past expiresAt), `sweepRateLimits`
  (hourly), `sweepLinkCodes` (hourly; link codes AND login requests past
  expiresAt).

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
