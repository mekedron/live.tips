# Architecture

One Flutter app, serverless by default. In the default Stripe-only mode the
artist's device talks straight to `api.stripe.com` with a restricted key
created by the artist — there is no live.tips backend. An **optional connected
mode** adds Revolut/MobilePay via a minimal relay (`worker/`,
`api.live.tips`); it is described in [Optional relay](#optional-relay-workerapilivetips)
below and keeps no donation history. This document explains the moving parts and
the reasoning.

## The core loop: polling instead of webhooks

Webhooks need a public HTTPS endpoint — a tablet on a stage doesn't have one.
Stripe recommends webhooks and does **not** document polling as a sanctioned
alternative; `/v1/events` is a documented endpoint that we poll deliberately,
accepting the trade-off, which is what `StripeDonationSource` does during a live
session:

Two limits this buys us, and they set the poll interval:

- `/v1/events` only lists events **going back 30 days** — fine for a live set,
  useless as a donation ledger. Tip history lives on the device.
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
4. Each new donation updates the session total/progress and triggers confetti.

Donations are de-duplicated by id at the source *and* in the session model
(belt and suspenders — the model survives restarts).

### Two observed paths, and why they can't collide

live.tips never *takes* a payment. It watches the artist's account and
recognizes tips in it. Two kinds arrive:

| | Event | Object | Id | Donor |
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
`donation_source_test.dart` pins it.

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

Full donation history doesn't use events (30-day API retention); it pages
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

## Bands (local multi-account)

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
socket — the controller additionally snapshots the account id at start so
its writes can't leak across bands). The relay keepalive pings **every**
band's jar, not just the active one, so idle donor pages never hit the
90-day expiry. Removing a band deletes its data + secrets (best-effort
relay DELETE included); secrets that survive a locked keychain are
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

## Sessions & persistence

`LiveSessionController` (Riverpod `Notifier`) owns the active session: polling
timer, donations, editable goal, stage lock. Every mutation persists the
session + event cursor to `SharedPreferences`, so a crash or app restart can
**resume** the session — and the stored cursor means donations made while the
app was dead are still collected. Completed sessions are archived locally and
shown in History → Sessions.

Secrets live elsewhere: the API key and the (salted SHA-256) PIN go in the
platform keychain/keystore via `flutter_secure_storage`.

```
lib/
├── core/        # money/currency helpers, theme, onboarding constants
├── domain/      # Donation, LiveSession, TipJar, BandAccount, BandSettings,
│                # AppSettings, StageSettings, JarTipAttribution (pure Dart)
├── data/        # StripeClient (REST), StripeRequests (typed ops),
│                # DonationSource (stripe poller + demo), stores, migrations
├── state/       # Riverpod providers, LiveSessionController
├── features/    # onboarding / setup / home / live / lock / history / settings
│                # live/stage/ = the stage visualizations (see below)
└── widgets/     # QR blocks, donation tiles, banners, band switcher
```

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
immediately and persists), and each donation is attributed at receipt
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
- No analytics, no third-party services. In Stripe-only mode the app makes no
  network calls except `api.stripe.com` and Stripe's own checkout page; in
  connected mode it additionally talks to `api.live.tips` (see below).
- Pinned `Stripe-Version: 2024-06-20` so parsing is stable regardless of the
  account's default API version.

## Optional relay (`worker/`, api.live.tips)

Revolut and MobilePay Box have no API to confirm a payment, so tips through
them cannot be verified — but artists still want to accept them. The relay is
the smallest server that makes this possible:

- **One Durable Object per jar** stores ~1 KB of plain text: artist name,
  message, currency, and validated payment *atoms* (a Stripe payment-link code,
  a Revolut username, a MobilePay box UUID — never free-form URLs). A SHA-256
  hash of the device's secret, never the secret itself.
- The QR points to `live.tips/t/<jarId>` — a server-rendered page offering the
  enabled methods. Revolut/MobilePay show a Turnstile-gated form (amount, name,
  message). Submitting relays a `tip` event over a WebSocket to the artist's
  device (first-message auth, hibernation-friendly), then redirects the fan to
  the payment deep link.
- **A tip outlives a missing screen, but only just.** The artist's socket dies
  for ordinary reasons — the phone locks, they switch to MobilePay to check a
  payment, they walk behind a wall — and the fan has already been sent off to
  pay by the time we notice. So an undelivered `tip` event is queued in the jar
  (bounded by `MAX_PENDING`, swept after `PENDING_TTL_MS` = 1 h by the same
  alarm that handles the 90-day expiry), flushed to the next socket that
  authenticates, and deleted on delivery. Every event carries a server-minted
  `id`, so the flush can send before it deletes: a crash mid-flush redelivers,
  and the app's dedupe-by-id keeps the tip off the stage twice. This queue is
  the *only* place donor text is ever written server-side.
- The app treats relayed tips as **unverified**: they count toward the session
  with a visible badge, never get the "big tipper" treatment, and History
  labels them as reported-not-confirmed.
- Lifecycle: the device pings `/seen` at most once a day; the jar's own alarm
  deletes everything 90 days after the last activity. Deleting or regenerating
  the link wipes it immediately. There is no account system.
- Abuse controls: strict validation and length caps on every field, per-IP and
  per-jar rate limits, duplicate suppression, Turnstile on the donor form, and
  a maintainer-only registry (metadata + counters, no content) behind an admin
  token.
- The live session keeps two independent channels: the unchanged Stripe poller
  and the relay WebSocket. Relay failures degrade to Stripe-only with a status
  pill; they never block a session. Returning to the foreground redials the
  socket at once (`RelayTipChannel.reconnectNow`) rather than waiting out a
  backoff on a connection the OS has not yet admitted is dead.
- Close codes are a contract: `4401` (bad or rotated secret) and `4410` (jar
  gone) are terminal and send the artist to re-link; everything else, including
  `4408` (auth deadline missed on a slow link), is transient and retried.

## Testing

- Unit: money formatting/parsing (incl. zero-decimal currencies), checkout
  session parsing (custom fields, fallbacks), session accounting (dedupe,
  progress, JSON round-trip), poller cursor semantics (`ending_before`
  advancement, resume cursor, filtering) against a fake `StripeRequests`.
- Widget: boot → demo mode → home smoke test.
- Integration (`flutter drive`): full demo session on a simulator — start,
  donations arrive, stop, summary — with screenshots.

## Platform notes

- **Android:** `MainActivity` extends `FlutterFragmentActivity` (required by
  `local_auth`), `INTERNET` + `USE_BIOMETRIC` permissions.
- **iOS:** `NSFaceIDUsageDescription` for the stage lock.
- **macOS:** `com.apple.security.network.client` entitlement in debug and
  release.
- `scripts/run.sh iphone|ipad|mac|android` launches the debug build on the
  most recently used simulator/emulator of that type.
