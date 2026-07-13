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
([`firebase/`](firebase/), `tip.live.tips`) that forwards tip notifications to the
artist's device and **keeps no tip history and never touches money**. Tips from these
methods are shown as *unverified* because live.tips cannot confirm they were actually
paid. Stripe-only setups still talk to no live.tips server at all — see
[Connected mode](#connected-mode-revolut--mobilepay) below.

An **account is optional too.** The default is still a device-local profile, and it
still keeps everything on the device. Signing in buys one thing: the same bands, keys,
settings and history on a second device, and a live session several devices can watch
at once — see [Accounts](#accounts-optional) below.

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
way to confirm a payment, this mode uses a minimal relay ([`firebase/`](firebase/):
Cloud Functions + Firestore, with the fan page at `tip.live.tips`):

- The QR code points to a small hosted page (`tip.live.tips/t/<id>`) that offers every
  method the artist enabled. Card / Apple Pay / Google Pay still go straight to the
  artist's Stripe link; Revolut and MobilePay open a short form (amount, name, message).
- Submitting the form queues the tip for the artist's device and redirects the fan to
  the Revolut/MobilePay deep link. The artist's app listens for it and **deletes it as
  it shows it** — that delete is the delivery receipt. The relay keeps **no tip
  history, no analytics**, and the artist's profile (name, message, payment handles,
  all plain text) self-deletes after 90 days of inactivity.
- A device that is away — phone locked, artist checking their MobilePay app, walked
  out of signal — would otherwise miss the tip entirely, since the fan has already
  paid by then. So an undelivered tip waits in its jar for **up to one hour**, is
  handed over the moment the artist's screen comes back, and is deleted unseen if it
  never does. That is the relay's only storage of fan-written text, and the only exception
  to "no tip history".
- Revolut/MobilePay tips are shown as **unverified**: they appear the moment a fan
  submits the form, whether or not the payment completes. The artist reconciles against
  their own Revolut/MobilePay app.
- If the relay is unreachable, the app falls back to Stripe-only automatically. All tip
  history stays on the device regardless of mode — which is one more reason Stripe (the
  only method with a real payment record) is recommended.

## Accounts (optional)

The app boots into a **local profile** — no sign-in, no uid, nothing off the device.
An artist who wants a second device can sign in with **Apple**, **Google**, or as a
**guest** (an anonymous account: it syncs, but nothing recovers it if the device is
lost). An account owns the artist's **bands** — the per-gig profiles, each with its own
Stripe key, tip jar and QR code.

- **What syncs:** bands, the Stripe restricted key and relay jar secret (kept in each
  device's keychain, mirrored through an owner-only Firestore doc), settings, and tip +
  session history.
- **One live session per account**, enforced by a single Firestore doc rather than by
  policy. The device that starts it polls Stripe; every other device joins from a
  "Live session running in <band>" banner and follows the same tip feed.
- **Devices** are listed in Settings → Security: revoke one, or sign out everywhere
  else. A new device is added by scanning a QR — and the signed-in device has to
  confirm the request before anything is issued.
- **The trade-off, stated plainly:** a signed-in account's tips (names and messages
  included) are stored in Firestore under the artist's own uid, where no other account
  can read them. The local profile stores them nowhere but the device. Syncing is
  opt-in for exactly that reason.

See [architecture notes](docs/architecture.md) for how any of this holds together.

## Repository layout

| Path | What it is |
| --- | --- |
| [`app/`](app/) | Flutter app (iPhone, iPad, Android phone/tablet, macOS, web; Windows/Linux scaffolded) |
| [`firebase/`](firebase/) | Cloud Functions + Firestore relay for optional Revolut/MobilePay tips, and the fan page (`tip.live.tips`) |
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
