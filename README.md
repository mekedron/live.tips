# live.tips

**An open-source live tip jar for performers.** Cash is gone — the applause isn't.

Musicians, buskers, and street artists put one QR code on stage. Fans scan it, pick an
amount, leave a name and a message. Tips land **directly in the artist's own Stripe
account** — there is no platform, no middleman, no extra cut, and no server anywhere
in between. The artist's tablet or phone shows every tip live, with a goal progress
bar, the latest message, and confetti.

## How it works

- The artist creates a **restricted API key** in their own Stripe dashboard
  (2 minutes, [guided](docs/onboarding/create-restricted-key.md)) and pastes it into
  the app. The key is stored in the device keychain and only ever talks to
  `api.stripe.com`.
- The app creates a **Product + pay-what-you-want Price + Payment Link** in the
  artist's account. The Payment Link URL becomes their QR code — print it, tape it to
  the guitar case, put it on the merch table.
- During a **live session**, the app long-polls Stripe's
  [`/v1/events`](https://docs.stripe.com/api/events) endpoint (the documented
  webhook alternative — perfect for a tablet on a stage) and shows each new donation
  in real time against tonight's goal, which can be edited mid-set.
- **Stage lock** blocks the screen from casual tampering while the device sits on
  stage; unlocking uses Face ID / Touch ID / device passcode, with an in-app PIN as
  fallback.
- Refunds, payouts, and disputes stay where they belong: in the artist's own Stripe
  dashboard.

## Repository layout

| Path | What it is |
| --- | --- |
| [`app/`](app/) | Flutter app (iPhone, iPad, Android phone/tablet, macOS, web; Windows/Linux scaffolded) |
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
donations — useful for UI work and for trying the app before connecting Stripe.

## Security model

- **Bring your own key, keep your own key.** The restricted key never leaves the
  device (keychain/keystore) and is only sent to `api.stripe.com` over TLS.
- **Least privilege.** The key needs only: Checkout Sessions *Read*, Payment Links
  *Write*, Products *Write*, Prices *Write*. It cannot touch balances, payouts,
  refunds, or customer data beyond donation sessions.
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
