# Architecture

One Flutter app, no backend. The artist's device talks straight to
`api.stripe.com` with a restricted key created by the artist. This document
explains the moving parts and the reasoning.

## The core loop: polling instead of webhooks

Webhooks need a public HTTPS endpoint — a tablet on a stage doesn't have one.
Stripe explicitly supports polling `/v1/events` as a webhook alternative, which
is what `StripeDonationSource` does during a live session:

1. **Prime:** fetch the newest `checkout.session.completed` /
   `checkout.session.async_payment_succeeded` event id → that's the cursor.
   (If the account has none, fall back to `created[gte] = session start − 60 s`
   so device clock drift can't hide tips.)
2. **Tick (every 2–15 s, configurable):** `GET /v1/events?types[]=…&
   ending_before=<cursor>` returns only events newer than the cursor.
   Advance the cursor, keep paging while `has_more`.
3. **Filter:** keep sessions where `payment_link == our link` and
   `payment_status == "paid"`. Both event types can fire for one payment, so
   donations are de-duplicated by Checkout Session id at the source *and* in
   the session model (belt and suspenders — the model survives restarts).
4. Each new donation updates the session total/progress and triggers confetti.

Event payloads embed the full Checkout Session, including `amount_total`,
`currency`, `customer_details`, and our two custom fields (`nickname`,
`message`) — no follow-up API calls needed. This whole pipeline (restricted
key → link → real card payment → polled event with custom fields) is verified
end-to-end against a Stripe sandbox.

Full donation history doesn't use events (30-day API retention); it pages
`GET /v1/checkout/sessions?payment_link=…&status=complete` instead.

Failure handling: 401 → "key revoked" message; 429 → skip a few ticks;
network errors → keep retrying and show a status dot. The poller never
crashes a session.

## The tip jar

Created once in the artist's account, all tagged `metadata[managed_by]=live.tips`:

- **Product** "Tips — <artist>"
- **Price** with `custom_unit_amount[enabled]=true` (pay what you want)
- **Payment Link** with `submit_type=donate`, two optional custom text fields
  (nickname, message), and a custom thank-you confirmation

The link URL (`donate.stripe.com/…`) is rendered as a QR code — on the home
screen, fullscreen for printing, and on the live screen's side panel so the
audience can scan straight from the stage display.

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
├── domain/      # Donation, LiveSession, TipJar, AppSettings (pure Dart)
├── data/        # StripeClient (REST), StripeRequests (typed ops),
│                # DonationSource (stripe poller + demo), stores
├── state/       # Riverpod providers, LiveSessionController
├── features/    # onboarding / setup / home / live / lock / history / settings
└── widgets/     # QR blocks, donation tiles, banners
```

## Stage lock — honest threat model

The lock blocks *casual* interference: a full-screen tap-swallowing overlay
that only yields to Face ID / Touch ID / device passcode (`local_auth`,
`biometricOnly: false`) or the in-app PIN fallback. It cannot block the OS
home gesture — no app can. For a sealed kiosk, pair it with **iOS Guided
Access** or **Android app pinning**; the README and in-app copy say the same
thing. The screen stays awake during sessions via `wakelock_plus`.

## Security posture

- Restricted key, least privilege (5 permissions), verified per-permission at
  connect time with clear errors.
- `sk_live_…` keys are refused outright; test keys get a loud banner.
- No analytics, no third-party services, no network calls except
  `api.stripe.com` and Stripe's own checkout page.
- Pinned `Stripe-Version: 2024-06-20` so parsing is stable regardless of the
  account's default API version.

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
