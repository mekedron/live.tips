# live.tips

[![live.tips on Product Hunt](https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1191308&theme=light)](https://www.producthunt.com/products/live-tips?utm_source=badge-featured&utm_medium=badge&utm_campaign=badge-live-tips)

**An open-source live tip jar for performers.** Cash is gone — the applause isn't.

Musicians, buskers, and street artists put one QR code on stage. Fans scan it, pick an
amount, leave a name and a message. With Stripe — the recommended default — tips land
**directly in the artist's own Stripe account**, with no platform, no middleman, no
extra cut, and no server anywhere in between. The artist's tablet or phone shows every
tip live, with a goal progress bar, the latest message, and confetti.

Artists can optionally also accept **Revolut** and **MobilePay Box** tips. Those two
have no API to confirm a payment, so they route through a tiny open-source relay
([`worker/`](worker/), `api.live.tips`) that forwards tip notifications to the artist's
device and **keeps no tip history and never touches money**. Tips from these
methods are shown as *unverified* because live.tips cannot confirm they were actually
paid. Stripe-only setups still talk to no live.tips server at all — see
[Connected mode](#connected-mode-revolut--mobilepay) below.

## How it works

- The artist creates a **restricted API key** in their own Stripe dashboard
  (2 minutes, [guided](docs/onboarding/create-restricted-key.md)) and pastes it into
  the app. The key is stored in the device keychain and only ever talks to
  `api.stripe.com`.
- The app creates a **Product + pay-what-you-want Price + Payment Link** in the
  artist's account. The Payment Link URL becomes their QR code — print it, tape it to
  the guitar case, put it on the merch table.
- During a **live session**, the app polls Stripe's
  [`/v1/events`](https://docs.stripe.com/api/events) endpoint and shows each new
  tip in real time against tonight's goal, which can be edited mid-set.
  Stripe recommends webhooks; a tablet on a stage has no public HTTPS endpoint to
  receive one, so this polls a documented endpoint instead — a deliberate trade-off,
  not a blessed path. See [architecture notes](docs/architecture.md).
- **Stage lock** blocks the screen from casual tampering while the device sits on
  stage; unlocking uses Face ID / Touch ID / device passcode, with an in-app PIN as
  fallback.
- Refunds, payouts, and disputes stay where they belong: in the artist's own Stripe
  dashboard.

These are **tips for a performance, not charitable donations** — Stripe treats those
as two different businesses, and only one of them is you. Artists should describe
their Stripe account as live performance, not fundraising: see
[tips, not donations](docs/onboarding/tips-not-donations.md).

## Connected mode (Revolut & MobilePay)

Stripe is the default and needs no server. Artists who also want to accept **Revolut**
or **MobilePay Box** tips can opt in during onboarding. Because those services offer no
way to confirm a payment, this mode uses a minimal relay ([`worker/`](worker/), running
on Cloudflare at `api.live.tips`):

- The QR code points to a small hosted page (`live.tips/t/<id>`) that offers every
  method the artist enabled. Card / Apple Pay / Google Pay still go straight to the
  artist's Stripe link; Revolut and MobilePay open a short form (amount, name, message).
- Submitting the form relays the tip to the artist's device over a WebSocket and
  redirects the fan to the Revolut/MobilePay deep link. The relay keeps **no tip
  history, no accounts, no analytics**, and the artist's profile (name, message,
  payment handles, all plain text) self-deletes after 90 days of inactivity.
- A device that is away — phone locked, artist checking their MobilePay app, walked
  out of signal — would otherwise miss the tip entirely, since the fan has already
  paid by then. So an undelivered tip waits in its jar for **up to one hour**, is
  handed over the moment the artist's screen reconnects, and is deleted unseen if it
  never does. That is the relay's only storage of fan-written text, and the only exception
  to "no tip history".
- Revolut/MobilePay tips are shown as **unverified**: they appear the moment a fan
  submits the form, whether or not the payment completes. The artist reconciles against
  their own Revolut/MobilePay app.
- If the relay is unreachable, the app falls back to Stripe-only automatically. All tip
  history stays on the device regardless of mode — which is one more reason Stripe (the
  only method with a real payment record) is recommended.

## Repository layout

| Path | What it is |
| --- | --- |
| [`app/`](app/) | Flutter app (iPhone, iPad, Android phone/tablet, macOS, web; Windows/Linux scaffolded) |
| [`worker/`](worker/) | Cloudflare Worker relay for optional Revolut/MobilePay tips (`api.live.tips`) |
| [`docs/`](docs/) | Onboarding guide, architecture notes |
| [`docs/stripe-app-plan.md`](docs/stripe-app-plan.md) | Plan for the phase-2 Stripe App Marketplace companion |
| [`stripe-app/`](stripe-app/) | The future Stripe Apps (marketplace) companion — not started |

## Quick start (development)

```bash
cd app
flutter pub get
flutter run            # pick a device; try "Try the demo" — no Stripe account needed
flutter test           # unit + widget tests
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/demo_flow_test.dart   # e2e demo flow with screenshots
```

The **demo mode** on the welcome screen simulates a live session with generated
tips — useful for UI work and for trying the app before connecting Stripe.

## Security model

- **Bring your own key, keep your own key.** The restricted key never leaves the
  device (keychain/keystore) and is only sent to `api.stripe.com` over TLS.
- **Least privilege.** The key needs only: Checkout Sessions *Read*, Events *Read*,
  Charges *Read* (to see in-person taps), Payment Links *Write*, Products *Write*,
  Prices *Write*. It cannot touch balances, payouts, refunds, or customer data
  beyond the payments behind its own tips.
- **Live secret keys are refused.** The app rejects `sk_live_…` keys outright and
  explains how to create a restricted one instead.
- **Test mode is loud.** Sandbox/test keys get a permanent orange banner.
- Stage lock is honest about its limits: it stops casual taps, not theft. For a
  sealed kiosk, combine it with iOS Guided Access or Android app pinning
  (see [architecture notes](docs/architecture.md)).

## Status

MVP under active development in a private repo; will be open-sourced once verified
end-to-end. Roadmap highlights:

- [ ] Stripe App Marketplace companion for one-click onboarding ([plan](docs/stripe-app-plan.md))
- [ ] Create-key deep link with pre-selected permissions
- [ ] Windows build
- [ ] Optional sounds / external display mode for the live screen

## License

[MIT](LICENSE)
