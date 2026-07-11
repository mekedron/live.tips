# Stripe App Marketplace companion — plan

Goal: make onboarding effortless enough that a musician who has never seen an
API key can start collecting tips. This document captures what a Stripe App
(marketplace.stripe.com) can and cannot do for us, and the plan.

## Findings (verified against Stripe docs, 2026-07)

1. **A Stripe App cannot hand credentials to our mobile app without a
   middleman.** Distributed apps authenticate either via OAuth (install
   redirects the browser; the token lands on the *app developer's backend*) or
   via signature-based auth (the app's frontend gets a signature that the *app
   developer's backend* combines with the developer's own platform key). Both
   models put a server we own between the artist and Stripe — exactly what
   live.tips promises not to have.
2. **Dashboard-only apps (UI extensions) need no backend.** They run inside
   the artist's dashboard, authenticated by the dashboard session itself, with
   the permissions declared in the app manifest.
3. **The dashboard supports pre-filled restricted-key creation URLs.** We
   verified the format and slugs by creating and exercising a key end-to-end:

   ```
   https://dashboard.stripe.com/apikeys/create
     ?name=live.tips%20app
     &permissions[0]=rak_bucket_checkout_read     # Checkout Sessions: Read
     &permissions[1]=rak_event_read               # Events: Read
     &permissions[2]=rak_bucket_payment_links_write
     &permissions[3]=rak_product_write
     &permissions[4]=rak_plan_write               # "Prices" row (legacy name)
     &thirdparty_integration_name=live.tips
     &thirdparty_integration_url=https%3A%2F%2Flive.tips
   ```

   The mobile app already uses this link (button + QR on the connect screen),
   which removes most of the manual permission-picking pain **without any
   marketplace app at all**.

## Phase 2 proposal: "live.tips Setup Assistant" (dashboard-only app)

A UI-extension-only Stripe App — no backend, consistent with our no-middleman
principle — that lives in the artist's dashboard and:

1. **Creates the tip jar in one click** (product + pay-what-you-want price +
   payment link with nickname/message fields), using the dashboard session and
   manifest permissions (`product_write`, `plan_write`,
   `payment_link_write`).
2. **Shows the QR code** immediately, printable from the dashboard.
3. **Guides key creation** with a deep link to the pre-filled restricted-key
   form — but a *smaller* one: because the jar already exists, the mobile app
   then only needs **Checkout Sessions: Read + Events: Read**. A read-only
   key on the device is a meaningfully better security story.
4. **Shows recent tips** in a dashboard widget (nice-to-have).

The mobile app gains a matching "I already have a tip link" path in setup:
paste/pick the existing payment link (found via `GET /v1/payment_links`, which
read access covers) instead of creating one.

### Marketplace requirements to plan for

- App manifest with minimal permissions + OAuth-less (dashboard-only) auth.
- App listing: name, icons, screenshots, support URL, privacy policy
  (live.tips website), demo video.
- Stripe review: dashboard-only apps with narrow permissions are the simplest
  review category.
- Versioning via `stripe apps` CLI; test on the sandbox before submission.

### Explicitly rejected for now

- **Connect OAuth (Standard accounts)** — requires our hosted platform +
  token custody; contradicts the trust model. Could return later as an
  *optional, self-hostable* relay for users who prefer login-style onboarding.
- **Backend-based Stripe App** — same reason.

## Sequencing

1. ✅ MVP with restricted key + pre-filled deep link (done, verified).
2. Ship mobile app, gather feedback on where onboarding actually hurts.
3. Build Setup Assistant app with `stripe apps create`; internal/private
   distribution first.
4. Marketplace listing once the OSS repo is public (listing links to repo).
