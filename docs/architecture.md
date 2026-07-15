# Architecture

One Flutter app, serverless by default. With **no account** (the default) the
artist's device talks straight to `api.stripe.com` with a restricted key
created by the artist — there is no live.tips backend. An **optional connected
mode** adds Revolut/MobilePay via a minimal relay (`firebase/`,
`tip.live.tips`); it is described in [Optional relay](#optional-relay-firebasetiplivetips)
below and keeps no tip history for a no-account jar. An **optional account**
(Firebase Auth) syncs bands, settings and history across an artist's devices and
lets several of them watch one live session — see
[Accounts](#accounts-optional-and-what-signing-in-changes). Signing in also
**moves the Stripe key off the device to the server** (envelope-encrypted under
Cloud KMS) so Stripe can deliver that account's tips to a server webhook, and
turns on push notifications; the details are in
[Signing in moves the key and the ingestion path](#signing-in-moves-the-key-and-the-ingestion-path).
Without an account, the app is as device-local as it ever was. This document
explains the moving parts and the reasoning.

## The core loop: polling instead of webhooks

> **This section describes the no-account (device-local) path.** A tablet on a
> stage has no public HTTPS endpoint, so a no-account setup polls Stripe from the
> device. **Once the artist signs in, the key lives on the server**, which *does*
> have an endpoint — so Stripe delivers that account's tips to a server webhook
> and the app stops polling entirely. See
> [Signing in moves the key and the ingestion path](#signing-in-moves-the-key-and-the-ingestion-path).
> The event-shape and dedupe reasoning below is identical on both paths; only who
> makes the Stripe call moves.

Webhooks need a public HTTPS endpoint — a tablet on a stage doesn't have one.
Stripe recommends webhooks and does **not** document polling as a sanctioned
alternative; `/v1/events` is a documented endpoint that we poll deliberately,
accepting the trade-off, which is what `StripeTipSource` does during a live
session for a no-account jar:

Two limits this buys us, and they set the poll interval:

- `/v1/events` only lists events **going back 30 days** — fine for a live set,
  useless as a tip ledger. Tip history lives on the device.
- Stripe allows roughly **500 read requests per transaction** over a rolling
  30 days, with a floor of **10,000 reads/month**. A 4-second poll across a
  3-hour set is ~2,700 reads, so a busy month of long sets on a quiet account can
  approach the floor. This is why the default interval is 4 s and not 1 s.

1. **Prime:** fetch the newest event id of the polled types → that's the cursor.
   (If the account has none, fall back to `created[gte] = session start − 60 s`
   so device clock drift can't hide tips.)
2. **Tick (every 2–15 s, configurable):** `GET /v1/events?types[]=…&
   ending_before=<cursor>` returns only events newer than the cursor.
   Advance the cursor, keep paging while `has_more`.
3. **Filter:** see the two observed paths below.
4. Each new tip updates the session total/progress and triggers confetti.

Tips are de-duplicated by id at the source *and* in the session model
(belt and suspenders — the model survives restarts).

### Two observed paths, and why they can't collide

live.tips never *takes* a payment. It watches the artist's account and
recognizes tips in it. Two kinds arrive:

| | Event | Object | Id | Tipper |
| --- | --- | --- | --- | --- |
| **Online (QR)** | `checkout.session.completed`, `checkout.session.async_payment_succeeded` | Checkout Session | `cs_…` | name + message, if they typed them |
| **In person (tap)** | `charge.succeeded` | Charge | `ch_…` | none — anonymous |

- **Online.** Keep sessions where `payment_link == our link` and
  `payment_status == "paid"`. Both event types can fire for one payment; the id
  is the same, so the dedupe absorbs it.
- **In person.** The artist takes a contactless tap into the same Stripe
  account — Tap to Pay in Stripe's own Dashboard app, or a Terminal reader.
  live.tips does not drive the reader and knows nothing about it; it just sees
  the Charge. Keep charges where
  **`payment_method_details.type == "card_present"`** (plus `status ==
  "succeeded"` and `paid == true`).

That `card_present` check is load-bearing. **A Checkout Session payment also
emits `charge.succeeded`** — so accepting charges without it would count every
QR tip twice, once as `cs_…` and once as `ch_…`, under two ids that no
de-duplication can tie together. The card in a reader is card-*present*; a card
typed into a Checkout page is not. That single field is the whole guard, and
`tip_source_test.dart` pins it.

We watch the **Charge**, not the PaymentIntent: the Charge is the object that
carries `payment_method_details` (the discriminator) together with the settled
`amount` and `currency`. A PaymentIntent carries neither — its payment-method
detail hangs off `latest_charge`, unexpanded in the event payload — so
`payment_intent.succeeded` would cost an extra API call per tip and an extra
read scope. See <https://docs.stripe.com/api/charges/object>.

> **The assumption in-person tips rest on: the artist's Stripe account is
> dedicated to tips.** A tap has no payment link, no product, nothing of ours
> on it — we cannot narrow it to "a live.tips tip" the way we narrow a Checkout
> Session to our link. So live.tips treats *any* card-present payment in the
> account as a tip. Sell merch on a card reader through the same account and
> the merch sale drops into the jar. This is stated in the onboarding doc as
> well; if it ever stops being true, the in-person path needs a real
> discriminator (a dedicated Terminal location, or metadata on the charge).

Event payloads embed the full object, including `amount_total` /
`amount`, `currency`, `customer_details`, and our two custom fields
(`nickname`, `message`) — no follow-up API calls needed. This whole pipeline
(restricted key → link → real card payment → polled event with custom fields)
is verified end-to-end against a Stripe sandbox.

Full tip history doesn't use events (30-day API retention); it pages
`GET /v1/checkout/sessions?payment_link=…&status=complete` instead. Note that
in-person taps are *not* Checkout Sessions, so they don't appear in that list:
they live in the session record they arrived in (History → Sessions) and, of
course, in the artist's own Stripe dashboard.

Failure handling: 401 → "key revoked" message; 429 → skip a few ticks;
network errors → keep retrying and show a status dot. The poller never
crashes a session.

## The tip jar

Created once in the artist's account, all tagged `metadata[managed_by]=live.tips`:

- **Product** "Tips — <artist>"
- **Price** with `custom_unit_amount[enabled]=true` (pay what you want)
- **Payment Link** with `submit_type=pay`, two optional custom text fields
  (nickname, message), and a custom thank-you confirmation

`submit_type` is load-bearing and it is not cosmetic: it also picks the checkout
**hostname**. `donate` — which this used to send — puts the link on
`donate.stripe.com` behind a "Donate" button, i.e. every artist's printed QR code
told them, and Stripe, that they were collecting donations. They are not. A tip
is paid for a service rendered (the performance); a donation is tied to a
charitable purpose. Stripe treats those as different businesses, and charitable
fundraising is approval-gated — *prohibited* outside AU/CA/GB/US, which is most
of where live.tips artists are. Sending `pay` keeps the link on
`checkout.stripe.com` and stops the app priming its own users into a category
that gets them refused. See [tips, not donations](onboarding/tips-not-donations.md).

The link URL is rendered as a QR code — on the home screen, fullscreen for
printing, and on the live screen's side panel so the audience can scan straight
from the stage display.

## Bands (multi-account)

One artist, several acts: a solo set tonight, the band on Friday — each with
its own links, so nothing gets re-generated or renamed between gigs. A
**band** owns everything payment- and identity-shaped: the Stripe restricted
key + tip jar, the relay jar (Revolut/MobilePay), QR mode, last goal, poster
wording, session history, the relay-tip archive, and the resumable session.
Device-wide preferences (theme, stage look, poll cadence) stay shared.

Mechanically: a registry (`accounts_v1`: `{activeId, accounts:[{id,name,…}]}`)
plus per-band namespacing — every per-band SharedPreferences key and keychain
entry is suffixed with the band's account id (`tip_jar_v1_<id>`,
`stripe_api_key_<id>`, …). `AppState` carries the active band; `RootGate`
keys its subtree by account id so a switch remounts every screen. Switching
loads the target band's secrets from the keychain at runtime; it is refused
while a live session runs (a session is bound to its band's key and relay
jar — the controller additionally snapshots the account id at start so
its writes can't leak across bands). The relay keepalive pings **every**
band's jar, not just the active one, so idle tip pages never hit the
90-day expiry. Removing a band deletes its data + secrets (a best-effort
`deleteJar` included); secrets that survive a locked keychain are
tombstoned and wiped on a later boot.

Migration from the single-band layout is crash-safe and two-phase: the prefs
phase copies the legacy blobs into namespaced keys (type-aware, byte-
identical, under an id persisted *before* anything moves), lifts the
band-scoped fields out of `settings_v1`, commits by writing the registry,
and only then deletes the legacy keys. The keychain phase is retried each
boot until it succeeds (a locked keychain just means booting signed-out
once, exactly like today) and adopts secrets surviving an app reinstall.
Legacy keys written by a downgraded build are swept into a fresh band on
the next boot instead of being ignored.

The switcher lives where the band name shows: the name on Home (and a chip
on the side rail, welcome, and jar-setup screens) opens a sheet listing
every band with its configured methods, plus "Add a band" — which creates
an empty active band and runs the normal onboarding, since every screen
already reads "the active band". Abandoned, never-configured bands are
garbage-collected on switch-away.

## Accounts (optional), and what signing in changes

A band is a gig identity; an **account** is a person, and it owns bands.
Accounts are optional and off by default: the app still boots into the **local
profile**, which is exactly what it always was — SharedPreferences plus the
keychain, no uid, no live.tips backend at all. Everything in this section
happens only when the artist deliberately signs in.

Four ways to be, three of them Firebase Auth:

- **No account** — the default, device-local, unchanged.
- **Apple** or **Google**.
- **Guest** — an *explicit* anonymous account. It syncs and can be revoked, but
  there is nothing to recover it with if the device is lost.

Sign-in flows that hand the artist to Google or Apple bounce through Firebase
Auth's OAuth handler, and the artist reads that domain in the popup's address
bar — so it is **`auth.live.tips`**, not `livetips-app.firebaseapp.com`. It is a
custom domain on the same Hosting site as `tip.live.tips`, and Hosting serves the
reserved `/__/auth/*` handler on every custom domain attached to a site. The web
SDK takes the domain from `FirebaseOptions.authDomain`; the Android/Apple SDKs
ignore that field and read `FirebaseAuth.customAuthDomain` instead (which is what
Sign in with Apple *on Android* rides, having no native sheet). Both are set in
`data/firebase/auth_domain.dart` and applied at boot in `main.dart` — deliberately
not in the generated `firebase_options.dart`, which `flutterfire configure`
would overwrite. `livetips-app.firebaseapp.com` stays authorized as a fallback.

That last one collides with something: the relay *also* signs in anonymously,
purely as a transport credential (see [Optional relay](#optional-relay-firebasetiplivetips)),
so "is this Firebase user anonymous?" cannot be the question that decides
whether the artist has an account. The **accounts directory** — the device-local
list of profiles this device knows (`AccountsDirectory`, in prefs) — is the
discriminator instead: a uid is an account **iff the directory says so**, and
the only thing that puts one there is `AuthController._run`, i.e. a sign-in the
artist actually asked for. A relay transport uid is a Firebase user like any
other and still never reaches the switcher, the repository selection, or the
device list.

### What syncs, and what deliberately does not

`AccountDataRepository` is the seam: one contract, two implementations —
`LocalStoreRepository` (prefs + keychain, unchanged) and `FirestoreRepository`
(`users/{uid}/**`). The contract's reads are **synchronous** and Firestore has
no synchronous reads, so every non-secret read is served from an in-memory
mirror fed by snapshot listeners: writes update the mirror *before* the network
ack (a read-back right after a write must see the new value, exactly like
prefs), and offline persistence means the first snapshot after a restart
arrives from cache. Another device's edit lands as a mirror update plus an
`onChanged` nudge, which is how it reaches the UI.

Synced under the account: the band list, each band's Stripe tip jar and relay
jar, band settings, app settings, session history, the relay-tip archive, and
the song-request library. Deliberately **not** synced, in every implementation:
which band is active (what a device is looking at is a device's business) and the
in-flight session crash snapshot (two devices' half-finished sets must never
overwrite each other). Both stay in prefs.

The **relay jar secret** stays keychain-first: it lives under the account (hashed
in the relay's own `jars/{jarId}/private/auth`, and mirrored to the device
keychain for the fast path) so any device can serve the tip page offline. The
**Stripe restricted key does not** — it moves to a separate, harder custody, next.

### Signing in moves the key and the ingestion path

Two things change the moment a real (Apple/Google) account owns a band. Both are
new since the device-local era, and both are why a signed-in account has a server
in its data path where the local profile has none.

- **Key custody.** On connect, the key is validated, then sealed with envelope
  encryption — a per-secret AES-256-GCM data key wrapped by **Cloud KMS**
  (`europe-west1`, key ring `livetips/stripe-secrets`) — and stored in a top-level
  `stripeConnections/{connectionId}` doc. The Firestore rules deny that doc to
  **every** principal, the owning artist included (`allow read, write: if false`):
  it is unsealed only inside Cloud Functions, used, and **never handed back to a
  device**. A guest (anonymous) account cannot use this — a key sealed under an
  unrecoverable uid would strand its live webhook — so Stripe custody is
  Apple/Google-only.
- **Ingestion.** Because the key lives server-side, each connected band registers
  a webhook on the artist's own Stripe account pointing at
  `tip.live.tips/stripe/webhook/{connectionId}`. Stripe pushes tip / song-request /
  card-present events there; the function verifies the signature against that
  connection's sealed signing secret and writes the tip **straight into the
  account** via the shared destination router (`tip-destination.ts`) — into
  `sessions/{id}/tips` if a set is live, else the band's `relayTips` archive. The
  app no longer polls Stripe for a signed-in account; it reaches Stripe only
  through the strict-allowlist `stripeProxy` callable (create tip link, mint a
  song-request link, list tips/taps for reconciliation) — the device never sees
  the key.

The **relay** money path converges on the same router: for a **cloud** jar
(carrying `ownerUid` + `bandId`) a Revolut/MobilePay/Monzo tip is written directly
into the account too, with **no consume-once queue and no one-hour TTL** — those
collections are the artist's own history, kept as long as the band. The
`pendingTips` delivery queue described under [Optional relay](#optional-relay-firebasetiplivetips)
is now taken **only** for a jar without a complete route — i.e. no-account jars
(forever) and old cloud jars until their next claim installs the route.

**Signing in changes the privacy story, and the change deserves to be said out
loud.** In the local profile the device is the only witness: tips, fan names and
fan messages never leave it, and the Stripe key never leaves the keychain. In a
signed-in account both do — a night's tips (messages included) are written **by the
server** into Firestore under the artist's own uid, and the key is sealed on the
server. No other account can read any of it: the rules grant `users/{uid}/**` to
that uid alone, and `stripeConnections/*` to nobody, so cross-account reads
(URL-guessing included) are impossible by construction. But "no server ever sees a
tip" holds only for the local profile now. That is the price of the second device,
and it is the artist's to pay or refuse.

## Sessions & persistence

`LiveSessionController` (Riverpod `Notifier`) owns the active session: polling
timer, tips, editable goal, stage lock. Every mutation persists the
session + event cursor to `SharedPreferences`, so a crash or app restart can
**resume** the session — and the stored cursor means tips made while the
app was dead are still collected. Completed sessions are archived locally and
shown in History → Sessions.

Secrets live elsewhere: the API key and the (salted SHA-256) PIN go in the
platform keychain/keystore via `flutter_secure_storage`.

```
lib/
├── core/        # money/currency helpers, theme, onboarding constants
├── domain/      # Tip, LiveSession, TipJar, BandAccount, BandSettings,
│                # AppSettings, StageSettings, JarTipAttribution (pure Dart)
├── data/        # StripeClient (REST), StripeRequests (typed ops),
│                # TipSource (stripe poller + demo), stores, migrations
├── state/       # Riverpod providers, LiveSessionController
├── features/    # onboarding / setup / home / live / lock / history / settings
│                # live/stage/ = the stage visualizations (see below)
└── widgets/     # QR blocks, tip tiles, banners, band switcher
```

## Live sessions across devices

Only for signed-in accounts: the local profile keeps its sessions device-local
through `LocalSessionCoordinator`, exactly as before. `CloudSessionCoordinator`
implements the same `SessionCoordinator` seam over Firestore.

**One live session per account, and it is structural rather than policed.** The
coordination doc sits at a *fixed* path — `users/{uid}/live/current` — so two
"Go live" taps contend on the same document and the claim transaction lets
exactly one through. The loser is told which band is already live, and the shell
shows "Live session running in {band}" with a Join button instead.

> **Tip ingestion is now server-side for a cloud jar.** Stripe tips arrive by
> webhook and relay tips are written straight into the account (see
> [Signing in moves the key and the ingestion path](#signing-in-moves-the-key-and-the-ingestion-path)),
> so for a signed-in account the leader no longer polls Stripe to fill the session.
> The server writes into the same `sessions/{sessionId}/tips` subcollection the
> devices listen to, and it reads the leader lease to decide *live session vs.
> archive*. What the leader still owns is coordination and publishing the fan-page
> request-queue aggregate; presentation ("shown", confetti) is device-local. A jar
> that predates this — or a no-account jar — still ingests through a polling/relay
> **leader** exactly as below.

Two roles:

- The **leader** (the device that started, or resumed, the session) coordinates
  the set and, for a jar not yet on the server-direct path, runs the Stripe poll
  and the relay listener and writes every fresh tip to
  `users/{uid}/bands/{bandId}/sessions/{sessionId}/tips/{tipId}` — doc id = tip id,
  and Stripe and relay ids are both stable, so redeliveries and racing writers
  (a device or the server webhook) overwrite instead of duplicating.
- **Every** device, the leader included, *ingests* only from a listener on that
  subcollection. One code path, identical ordering everywhere, whether the writer
  was a device or the server. The leader's own tips come back through Firestore's
  latency-compensated local echo, so nothing is delayed, and the dedupe-by-id makes
  the echo free.

The leader holds a **lease**: `leaderLeaseUntilMs = now + 45 s`, stamped on
every poll tick — and stamped *before* the poll, so a failing Stripe call still
keeps the lease. (An outage must not hand leadership around for nobody's
benefit.) A follower that sees the lease stale by more than two minutes may take
over, in another transaction, and backfills the session window in case the dead
leader died holding unpublished tips. It may do so **only if it has the band's
Stripe key** to poll with — a key-less device (someone's tablet on the merch
table) stays a follower forever. A zombie leader waking from a long sleep keeps
polling harmlessly: its writes are idempotent and its stop still flips the same
doc.

Stop belongs to the stopping device: it flips `active: false` — but only if the
doc still names *its* session, because a stale-lease successor's night is not
its to end — and finalizes `sessions/{sessionId}` with the full assembled set.
That finalized doc **is** the history entry, which is exactly why stop must not
also append through the repository: the night would be archived twice. Every
other device watches the doc go inactive, tears down, and drops its snapshot.

## Devices, revocation, and adding one by QR

Settings → Security lists the account's devices (`users/{uid}/devices/{deviceId}`).
The app writes its own row — name, platform, model, timestamps — but `revoked` /
`revokedAtMs` are function-owned and pinned by the rules, and clients may not
delete a device row at all: delete-and-recreate would launder a revocation away.

Revocation comes in two strengths, and it is worth being clear which is which:

- **Revoke a device** is *cooperative*. It sets the flag; the device watches its
  own doc and signs itself out when it sees it. A device that never comes back
  online never finds out.
- **Sign out everywhere else** is the real kill switch. `revokeAllOtherDevices`
  stamps a watermark at `users/{uid}/private/security.sessionsValidAfterMs` and
  calls Firebase's `revokeRefreshTokens`. Every rule under `users/**` compares
  the caller's token `auth_time` against that watermark, so an ID token minted
  before the revocation loses the whole subtree **immediately**, rather than
  after the ≤1 h of cryptographic validity it has left. Accounts that never
  revoked have no security doc and short-circuit on `exists()`. The caller's own
  session dies with the rest — so the callable mints it a custom token *after*
  the revoke and returns it, and the calling device signs straight back in with
  that. No provider round-trip at the one moment the account's credentials are
  down, which is also why a **guest account** may pull this switch.

Adding a device is a QR handshake, and the load-bearing part is that the
already-signed-in device must **confirm** it. The signed-in device displays
`https://tip.live.tips/link#c=<code>`. The new device is unauthenticated — which
is why `linkCodes/{codeId}` is a top-level collection and why redeeming is
IP-quota'd — so it redeems the code, names itself, and then polls. Nothing has
been minted yet: the signed-in device sees the requester's name appear and must
tap to confirm, and only then does `collectLinkToken` return a single-use custom
token. Codes are single-use, attempt-capped, and expire in two minutes. Without
that confirm tap a code shoulder-surfed off a screen would be a silent account
takeover; with it, it is a request the artist can refuse.

## Push notifications (signed-in accounts, opt-in)

Push exists for one case: a tip or song request that lands **while no set is
running** — the artist isn't watching the stage, so tell them. A tip that arrives
during a live set pushes nothing.

- **Chokepoint.** `recordTipNotification` (`notifications.ts`) is called from both
  money paths (`tip.ts`, `stripe-webhook.ts`) and fires **only when the routed tip
  is not live**. It appends `users/{uid}/notifications/{tipId}` — a
  server-written-only bell feed capped at 100 entries, holding kind, band, amount,
  currency, and the fan's name / song title if present.
- **Fan-out.** An `onDocumentCreated` trigger reads the account's device rows,
  localizes the message per device (`push-strings.ts`, 20 languages, keyed on the
  device's stored `locale`), and sends via **Firebase Cloud Messaging**. Dead
  tokens (`registration-token-not-registered`) are pruned from the device doc on
  send.
- **Tokens** live on `users/{uid}/devices/{deviceId}.fcmToken` (+ `fcmTokenAtMs`,
  `locale`), written only after the user enables notifications on that device and
  the OS grants permission. Sign-out, revocation, and toggling off all delete the
  field. A guest account and a no-account device never register one, so they never
  get a push.
- **Web** registers `firebase-messaging-sw.js` at the **origin root** (the FCM SDK
  ignores the `/app/` base href), which `pages.yml` copies to `_site/`. The SW
  pulls the Firebase messaging SDK from `gstatic.com` on first use. iOS/macOS/
  Android native blocks are wired but inert until the APNs auth key is uploaded.
- **Read state** is a watermark in `users/{uid}/settings/notifications`
  (`markAllRead(newestSeenMs:)` — the newest entry *shown*, not device-now, or the
  badge never clears); per-type opt-out flags live there too (absent = send).

## The stage (live-screen visualization)

The live screen renders through one seam — `JarStageView` — with three
user-selectable styles (`AppSettings.stage`, settings → "Stage look"):

- **classic** — the original numbers-first screen (native, works everywhere;
  also the terminal fallback).
- **jar2d / jar3d** — a glass tip jar that fills with coins toward the goal,
  spills over past 100%, and at 200% retires the full jar to a trophy shelf
  while a fresh one takes its place. Both are renderers inside ONE embedded
  JS "stage library" (`/renderer` at the repo root, built into
  `app/assets/stage/` — see `renderer/README.md`), hosted in a
  `webview_flutter` WebView and driven exclusively over a JSON bridge
  (`renderer/PROTOCOL.md`). jar3d is three.js with 11 vessels and 6 backdrop
  scenes; jar2d is a lightweight Canvas twin for weak tablets.

Money truth never leaves Dart. `LiveSession` banks rollovers **eagerly**
(`bankedMinor`/`bankedJars`: every full `2 × goal` in the current jar retires
immediately and persists), and each tip is attributed at receipt
(`JarTipAttribution`: fill delta, absolute fill after, rollovers) — the
renderer only choreographs what it is told, so a WebView crash can never lose
or invent a cent. All HUD text (session total, "this jar: X of Y", trophy
line) is native Flutter on top of the WebView.

Runtime resilience lives in `stage_resolver.dart` + `web_stage.dart`: a
handshake (`hello → init → ready`) with an 8-second deadline, a perf heartbeat
watchdog, one silent reload, then graceful fallback jar3d → jar2d → classic —
the persisted preference is never mutated by a fallback.

## Stage lock — honest threat model

The lock blocks *casual* interference: a full-screen tap-swallowing overlay
that only yields to Face ID / Touch ID / device passcode (`local_auth`,
`biometricOnly: false`) or the in-app PIN fallback. It cannot block the OS
home gesture — no app can. For a sealed kiosk, pair it with **iOS Guided
Access** or **Android app pinning**; the README and in-app copy say the same
thing. The screen stays awake during sessions via `wakelock_plus`.

## Security posture

- Restricted key, least privilege (6 permissions — three of them read-only, and
  the in-person path added a read, never a write), verified per-permission at
  connect time with clear errors. Nothing the key can do moves money: no
  refunds, no balance, no payouts.
- `sk_live_…` keys are refused outright; test keys get a loud banner.
- No analytics, no ad tech, no crash reporter. In Stripe-only mode on the local
  profile the app makes no network calls except `api.stripe.com` and Stripe's
  own checkout page; connected mode adds the relay, and a signed-in account
  adds Firebase Auth + Firestore, the server-side Stripe custody (Cloud KMS +
  webhook), and — if turned on — Firebase Cloud Messaging for push (see below).
- Signing in moves data off the device on purpose: an account's bands, settings
  and tip history (fan names and messages included) live in Firestore under its
  own uid, readable by that uid alone. The **Stripe key is stricter still** — it
  lives in `stripeConnections/*`, KMS-sealed and readable by no principal, the
  owner included. The local profile stores none of it anywhere but the device.
- Pinned `Stripe-Version: 2024-06-20` so parsing is stable regardless of the
  account's default API version.

## Optional relay (`firebase/`, tip.live.tips)

Revolut and MobilePay Box have no API to confirm a payment, so tips through
them cannot be verified — but artists still want to accept them. The relay is
the smallest server that makes this possible: Cloud Functions (2nd gen, Node
20, `europe-west1`) over Firestore, with the fan page on Firebase Hosting.

- **One `jars/{jarId}` document** holds ~1 KB of plain text: artist name,
  message, currency, and validated payment *atoms* (a Stripe payment-link code,
  a Revolut username, a MobilePay box UUID — never free-form URLs). The
  device's secret lives beside it as a SHA-256 hash under `private/auth`,
  never the secret itself, and is compared in constant time.
- The QR points to `tip.live.tips/t/<jarId>` — a page rendered by the `tip`
  function (a Hosting rewrite of `/t/**`) offering the enabled methods.
  Revolut/MobilePay show a Turnstile-gated form (amount, name, message).
  Submitting writes the tip to the jar and redirects the fan to the payment
  deep link. Fans never touch Firestore from the browser.
- **Delivery is deletion — for a no-account jar.** A tip on an unrouted jar is
  written to `jars/{jarId}/pendingTips/{id}` and the artist's device listens to
  that collection; showing a tip means deleting its document, and that delete is
  the only acknowledgement there is. The device emits the tip *before* it deletes,
  so a crash in between redelivers rather than loses — the app dedupes by document
  id. The queue is bounded (`MAX_PENDING`) and swept after `PENDING_TTL_MS` = 1 h
  whether or not anyone came back for it. For a no-account jar this queue is the
  *only* place fan-written text is stored server-side, and nothing in it is a tip
  history: it is a delivery buffer that empties itself. **A cloud jar skips the
  queue entirely** — the server writes the tip straight into the account's own
  kept history (see [Signing in moves the key and the ingestion path](#signing-in-moves-the-key-and-the-ingestion-path)),
  which is fan-written text at rest with no TTL, under the artist's uid.
- Jar lifecycle runs through six callables — `createJar`, `claimJar`,
  `updateJarProfile`, `rotateJarSecret`, `jarSeen`, `deleteJar`. The secret
  remains the root credential; `claimJar` exchanges it for read access by
  adding the caller's uid to the jar's `readerUids`, which is what the Firestore
  rules check. `rotateJarSecret` empties that list, so every other device must
  re-claim with the new secret or stay out.
- **Every caller is signed in, and most of them are nobody.** The callables and
  the rules need a uid, but a local-profile artist has no account — so the app
  signs in anonymously purely as a *transport credential*
  (`RelayAuth.ensureRelayUid`). That uid never enters the accounts directory,
  the switcher, or the cloud repository: it exists to be authorized and nothing
  else. Only a real (Apple/Google) account is recorded as a jar's `ownerUid`.
- The app treats relayed tips as **unverified**: they count toward the session
  with a visible badge, never get the "big tipper" treatment, and History
  labels them as reported-not-confirmed.
- Lifecycle: the device calls `jarSeen` at most once a day; a scheduled sweep
  deletes everything 90 days after the last activity (`EXPIRE_DAYS`), and an
  expired jar is treated as gone the moment it lapses, before the sweep reaches
  it. Deleting or regenerating the link wipes it immediately.
- Abuse controls: strict validation and length caps on every field, per-IP
  (salted-hash) and per-uid quotas, duplicate suppression, and Turnstile on the
  tip form. The Firestore rules are default-deny: no client writes a jar, ever;
  the artist's devices may only read and delete their own pending tips.
- The live session keeps two independent channels: the unchanged Stripe poller
  and the Firestore listener. Relay failures degrade to Stripe-only with a
  status pill; they never block a session. Returning to the foreground
  re-attaches the listener at once (`FirestoreTipChannel.reconnectNow`) rather
  than waiting out a backoff on a stream the OS has not yet admitted is dead.
- Health is a contract: a jar that is gone (`not-found`) or a secret that no
  longer works (`unauthenticated` / `permission-denied`, from the claim or from
  the listener) is **terminal** — no retry can fix it and the artist is sent to
  re-link. Everything else, including an unreachable backend, is transient and
  retried with backoff.

## Testing

- Unit: money formatting/parsing (incl. zero-decimal currencies), checkout
  session parsing (custom fields, fallbacks), session accounting (dedupe,
  progress, JSON round-trip), poller cursor semantics (`ending_before`
  advancement, resume cursor, filtering) against a fake `StripeRequests`.
- Widget: boot → demo mode → home smoke test.
- Integration (`flutter drive`): full demo session on a simulator — start,
  tips arrive, stop, summary — with screenshots.

## Platform notes

- **Android:** `MainActivity` extends `FlutterFragmentActivity` (required by
  `local_auth`), `INTERNET` + `USE_BIOMETRIC` permissions.
- **iOS:** `NSFaceIDUsageDescription` for the stage lock.
- **macOS:** `com.apple.security.network.client` entitlement in debug and
  release.
- `scripts/run.sh iphone|ipad|mac|android` launches the debug build on the
  most recently used simulator/emulator of that type.
