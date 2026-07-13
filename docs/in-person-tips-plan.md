# In-person tips — plan

Cash is gone, and the app already answers that with a QR code. But a QR code
assumes the fan has a phone, a data connection, and the habit of paying with it.
Some of them just have a card in their pocket. This document is about taking
*that* tip: a physical tap, at the stage, into the artist's own Stripe account.

Everything below is measured against the three promises the project actually
makes (see [README](../README.md)):

1. **Bring your own restricted key** — the artist's credential, on the artist's
   device, least privilege.
2. **No live.tips server in the money path** — we are not a platform, we take no
   cut, and nothing we run can see or hold a payment.
3. **It runs in the browser, no install, no signup** — the Flutter client is a
   web target as much as a native one.

An option that breaks one of those has to earn it out loud. Three of the four
paths below don't break any; the interesting one (Option A) breaks two, and I
still can't recommend it.

All Stripe rates, prices, package versions and doc quotes here were **verified on
11 July 2026**. Rates and hardware prices move — re-check before you spend money
on the strength of a number in this file.

---

## 1. Why — and what this does *not* fix

**What it fixes.** The fan standing three feet away with a contactless card and
no interest in scanning anything. Today they walk away. A tap is a two-second
interaction the artist can initiate ("card? here—") without the fan installing,
scanning, typing, or trusting anything. It is also the only path that works when
the venue's wifi is fine but the fan's phone is at 2%.

**What it does not fix: fees.** In-person acceptance is *not* meaningfully
cheaper than the Payment Link, and I want that stated before anyone reads a task
list and gets excited. On a **€2 tip** ([Stripe EU pricing](https://stripe.com/en-fi/pricing),
11 July 2026):

| Path | Rate | Fee on €2 | Artist keeps |
| --- | --- | --- | --- |
| Payment Link (today) | 1.5% + €0.25 | €0.28 | **€1.72** |
| Stripe Tap to Pay (Option A) | 1.4% + €0.10 **+ €0.10 Tap-to-Pay surcharge** | €0.23 | **€1.77** |
| Stripe Terminal, physical reader (Option B) | 1.4% + €0.10 | €0.13 | **€1.87** |
| SumUp Air (not us) | 1.39–1.69%, **no fixed fee** | €0.03 | **€1.97** |

Stripe's Tap to Pay is billed as the base in-person rate **plus a per-authorization
surcharge** — in the UK that is 1.4% + £0.10 + £0.10 = **1.4% + £0.20**, an
*identical fixed fee* to the 1.5% + £0.20 online rate. In the EEA the surcharge
turns 1.4% + €0.10 into 1.4% + €0.20, versus €0.25 online: **a five-cent saving**.

So: **building Tap to Pay does not solve the small-tip problem.** A fixed fee of
€0.20–€0.25 on a €2 tip is a 10–12% haircut no matter which Stripe surface takes
it, and a €59 SumUp-class terminal beats every Stripe path on economics because
it has no fixed fee at all. If an artist's tips are mostly €1–€3 coins-equivalent,
the honest advice is a fixed-fee-free acquirer, and we should say so rather than
pretend otherwise.

We build in-person tips for **product** reasons, not fee reasons:

- One app, one jar, one stage screen. A SumUp tap lands in SumUp, not on the
  stage, not in the goal bar, not in the confetti.
- The artist keeps a single merchant relationship (their own Stripe account),
  not two.
- The physical-reader path (Option B) *is* the cheapest Stripe surface — €0.13
  vs €0.28 on a €2 tip — which is a real 15-cent improvement over the Payment
  Link, just not one that changes the economics of a €2 tip.

---

## 2. What we will not do, and why

These are non-goals, and they stay non-goals across every option below.

**We will not become a Stripe platform (Connect).** Connect is how you'd build
this if you wanted to be the middleman: onboard artists as connected accounts,
route charges through your platform, take an application fee. Terminal does *not*
require it — a physical reader and a card-present PaymentIntent work perfectly
well on the artist's plain standard account. Adopting Connect would mean live.tips
appears in the money flow, acquires compliance obligations, and gains the ability
to take a cut. We would rather not have the ability.

**We will not hold a secret key.** Nothing below asks for `sk_…`. Where Stripe's
docs assume a secret key on a server (connection tokens — see Option A), the
question we ask is "does a *restricted* key do it", and if the answer is no, the
option gets reconsidered rather than the promise.

**We will not put a live.tips server in the money path.** The relay
(`firebase/`) exists, but it forwards notifications for payment methods with no API
— it never touches money, and it never will. If an in-person option needs a
server that mints credentials or initiates charges, that server is a middleman
regardless of how thin it is, and the option loses.

**We will not ship a native-only feature that silently kills the web client.**
The browser client is a promise, not an implementation detail. Option A cannot be
done on the web — that is stated as a cost, not glossed over.

---

## 3. Phase 0 — "Observer" (shipping now)

**Status: being implemented.** This is the change landing in `app/lib/data/**`
and `docs/architecture.md` as this plan is being written.

### What it is

live.tips already drives nothing. It polls the artist's own account through
[`/v1/events`](https://docs.stripe.com/api/events) and renders whatever shows up
against tonight's goal. The Observer change widens what "shows up" means: in
addition to `checkout.session.*`, the poller picks up **card-present** payments
(`payment_intent.succeeded` / `charge.succeeded` with a `card_present` payment
method).

The consequence is disproportionate to the effort. The artist can take a tap in
**Stripe's own Dashboard app** — [Tap to Pay on iPhone and
Android](https://docs.stripe.com/terminal/payments/setup-reader/tap-to-pay) is
built into it, no hardware, no code, nothing from us — or on a Stripe Terminal
reader, and **it lands in the jar automatically**. Stage screen, goal bar,
confetti, session total, local history. We wrote no payment code to make that
happen.

### What it costs

Two additional **read** scopes on the restricted key:

| Resource | Permission | Why |
| --- | --- | --- |
| **PaymentIntents** | Read | The card-present event payload |
| **Charges** | Read | Payment-method details (`card_present`), amount, currency |

(Exact deep-link permission slugs for the pre-filled key URL live in
[`docs/onboarding/create-restricted-key.md`](onboarding/create-restricted-key.md)
and the [Stripe App plan](stripe-app-plan.md); they are being updated by the same
change.)

Reads only. No write scope. No new dependency, no new platform, no new server.
**All three promises intact.** This is as close to free as a feature gets.

### Its two limitations — both real

**1. A tap collects an amount and nothing else.** No fan name, no message. The
custom fields that make the stage screen worth looking at (`nickname`, `message`
on the Payment Link) do not exist in a card-present flow initiated from Stripe's
Dashboard app. A tapped tip renders as an amount, and the stage shows an amount.
That is a genuine downgrade in the product's whole point.

**2. A Dashboard-app tap has no metadata, so we cannot tell a tip from any other
card-present payment in that account.** There is no field to tag it with — the
Dashboard app does not expose `metadata` on the charge it creates. If the artist
also sells merch, teaches lessons, or runs a coffee stand out of the same Stripe
account, every one of those taps would land on the stage as a tip.

**The decision: artists who want tapped tips use a dedicated Stripe account for
tips.** This is not a workaround, it is the fix — it makes "every card-present
payment in this account is a tip" true *by construction*, with no heuristics, no
filtering, and no false positives. Stripe accounts are free; a second one is a
five-minute chore. The onboarding copy should say this plainly, and the app
should say it too when the observer is enabled. (The **Bands** feature already
gives us the shape for this: one band, one key, one account.)

Note that Option B removes limitation 2 entirely (metadata works on a
server-driven card-present PaymentIntent), and softens limitation 1. That is a
large part of why it's the recommendation.

---

## 4. Option A — Tap to Pay on the artist's own iPhone, driven by live.tips

The artist opens live.tips, taps "Take a tip", the fan holds their card to the
back of the artist's phone. No hardware, no second app. It is the most obviously
desirable version of this feature, and it is the one I am recommending **against**.

### Structural prerequisites (none of them optional)

**A payment service provider is mandatory, by Apple's design.** From
[Apple's Tap to Pay on iPhone developer page](https://developer.apple.com/tap-to-pay/):
app developers *"will first need to integrate with a supported payment service
provider … The PSP is responsible for all the necessary certifications"*. There
is no path where an app talks to the NFC hardware itself. Stripe Terminal would
be our PSP. Fine — but note what it means: this option is *defined* by depending
on a payments SDK, which is a category of dependency the project has so far
avoided entirely.

**The Apple entitlement, twice.**
[`com.apple.developer.proximity-reader.payment.acceptance`](https://developer.apple.com/documentation/BundleResources/Entitlements/com.apple.developer.proximity-reader.payment.acceptance)
must be requested from Apple — a **development entitlement first, then a separate
distribution entitlement**; App Store builds fail to sign without the latter. The
maintainer has an Apple developer account and is comfortable with the process, so
this is a schedule item, not a blocker. Worth flagging for anyone forking the
repo: **they would need their own entitlement grant**, which makes this feature
non-portable in a way nothing else in the codebase is.

**Native app only — the web client cannot do this.** [Web NFC](https://developer.mozilla.org/en-US/docs/Web/API/Web_NFC_API)
is NDEF-only: it reads and writes tags. It cannot run an EMV kernel, cannot do
contactless card authentication, and is not a payment API. There is no browser
route to Tap to Pay and there will not be one. **This option abandons the browser
client for the tap**, and pulls in App Store + Play Store distribution and
payments-app review — an ongoing operational commitment for a hobby project, not
a one-off.

**Device bar.** ([Stripe Tap to Pay
requirements](https://docs.stripe.com/terminal/payments/setup-reader/tap-to-pay))

- **iOS:** iPhone XS or newer, iOS 16.4+. **Never iPad — no iPad has NFC.** The
  stage device is very often an iPad. So on Apple, the tap phone and the stage
  device are *necessarily two devices*.
- **Android:** Android 13+, NFC hardware, unrooted, locked bootloader, Google
  Mobile Services, developer options off.
- **But Android tablets DO support Tap to Pay.** That makes an NFC-equipped
  Android tablet the **only single-device configuration in this entire document**:
  one slab, on a stand, showing the stage *and* accepting the tap. Worth
  remembering — see the parking lot.

### The gating experiment — do this first, before any other task

Stripe says: *"Always create Connection Tokens from your backend server"*
([Terminal setup](https://docs.stripe.com/terminal/payments/setup-integration)).
Read the stated **reason**, though: it is *don't embed your secret key in the
client*. live.tips does not have a secret key. It has the **artist's own
restricted key**, which is a different object with a different threat model — and
Stripe's own **Aptos One** POS app documents holding an `rk_live_…` restricted key
**on the device** (observed 11 July 2026).

So an on-device restricted key with **Terminal write** *probably* mints a
connection token. **This is unverified, and everything in Option A depends on it.**

> **Experiment A-0 (30 minutes, zero cost, gates the entire option).**
> In a Stripe sandbox, create an `rk_test_…` restricted key with **Terminal:
> Write**, and from a plain HTTP client:
> ```
> POST https://api.stripe.com/v1/terminal/connection_tokens
> Authorization: Bearer rk_test_…
> ```
> - **200 + a `secret`** → the option is structurally viable with no live.tips
>   server, and the tasks below become real.
> - **403 / permission error** → connection tokens require a secret key, which
>   requires a server we own, which is a middleman. Option A is then in direct
>   conflict with promise 2 and should be **dropped**, not worked around.
>
> Nothing else in this section should be started until this returns 200.

### If it returns 200 — the tasks

1. Apple: request the **development** entitlement; add it to the iOS target.
2. Android: confirm the device bar; add the Terminal SDK's manifest requirements.
3. Wire `mek_stripe_terminal` (see risk below) with a `TokenProvider` backed by
   the on-device restricted key.
4. Discover / connect the local reader (`localMobile` / Tap to Pay reader type),
   `createPaymentIntent` with `payment_method_types=[card_present]`,
   `collectPaymentMethod`, `confirmPaymentIntent`.
5. Stage UX: a "Take a tip" mode with a numeric pad and the Apple-mandated
   Tap-to-Pay presentation (Apple's UI is non-negotiable and takes over the
   screen — so the stage device cannot be showing the stage while it is taking a
   tap, another reason the two-device split is forced).
6. The tapped tip enters the session through the **existing observer path**
   (Phase 0), not a second ingestion route. One source of truth for money.
7. Apple: request the **distribution** entitlement; App Store + Play Store
   payments review.

### Risks

**The Flutter SDK is a single-maintainer package in the money path.** There is
**no official Stripe Terminal Flutter SDK**. The only real option is
[`mek_stripe_terminal`](https://pub.dev/packages/mek_stripe_terminal) — v4.6.3,
one maintainer, ~6 months since the last publish, wrapping Terminal **4.6.0**
while Stripe's iOS SDK has moved to **5.x**, and offline mode unsupported.
Stripe explicitly warns that device and SDK minimums change **for compliance
reasons** — meaning a stale wrapper is not merely stale, it can become
*non-functional* on a Stripe deadline the wrapper's maintainer may not meet.

*Mitigation:* vendor or fork the package into the repo so we can bump the native
SDK ourselves, or write the platform channels directly (the Terminal surface we
need is small: token provider, discover, connect, collect, confirm). Either way,
**budget for owning it**. Do not take this dependency and hope.

**The tap collects no name and no message.** Same as Phase 0 limitation 1: a
tapped tip is an amount. One mitigation idea — *and it is an idea, not a design*:
the artist takes the tap while the fan, if they feel like it, scans the stage QR
to attach a name and message, which the app then correlates by proximity in time.
That correlation is fuzzy (two fans, ten seconds apart, and it's wrong), the UX is
two interactions where the pitch was one, and nothing about it is verified.
**Flagged as an open problem, not a solved one.**

### What it costs in promises

| Promise | Verdict |
| --- | --- |
| Bring your own restricted key | **Kept** — *if* experiment A-0 passes. Adds Terminal: Write. |
| No live.tips server in the money path | **Kept** — *if* A-0 passes; **broken** if it doesn't. |
| Runs in the browser, no install | **Broken.** Native only, App Store distribution, payments review. |

**Connect is not required** — Terminal runs on the artist's plain standard
account, we never enter the money flow, we take no cut. The "no middleman"
promise survives even here. It is the browser promise that dies.

---

## 5. Option B — Server-driven Terminal with a physical Stripe reader — **recommended**

This is the one to build.

### Why it is different from Option A in kind, not degree

Stripe's own guidance: *"For BBPOS WisePOS E and Stripe Reader S700/S710, we
recommend server-side integration because it uses the **Stripe API instead of a
Terminal SDK** to collect payments."*
([Terminal setup](https://docs.stripe.com/terminal/payments/setup-integration).)
And in the [Terminal deployment
checklist](https://docs.stripe.com/terminal/deployment-checklist), the
connection-token endpoint is annotated **"(SDK only)"**.

Read that carefully, because it dissolves almost every obstacle in Option A. A
server-driven Terminal integration is **two plain REST calls to `api.stripe.com`**:

```http
POST /v1/payment_intents
  amount=500
  currency=eur
  payment_method_types[]=card_present
  metadata[managed_by]=live.tips
  metadata[nickname]=Maya
  metadata[message]=Play one more!

POST /v1/terminal/readers/{reader_id}/process_payment_intent
  payment_intent=pi_…
```

…and then the existing `/v1/events` poller sees the result, exactly as it does
today. The reader does the EMV work; the API does the orchestration; the app does
neither.

Therefore, and this is the whole argument:

- **No Terminal SDK.** No `mek_stripe_terminal`, no single-maintainer dependency,
  no native SDK version treadmill.
- **No connection token.** The thing that gates Option A does not exist here.
- **No Apple entitlement.** None.
- **No native app, no App Store, no payments review.**
- **It works from the browser client that already exists.** Same
  `StripeClient` / `StripeRequests` seam, two new typed operations.

All three promises intact. Nothing is abandoned.

### And metadata works — which is the real prize

Because *we* create the PaymentIntent, we set `metadata` on it. That means:

- The tip is **tagged** (`managed_by=live.tips`), so the identification problem
  from Phase 0 **disappears** — no dedicated Stripe account required, no
  false-positive merch sales on the stage screen. (A dedicated account is still a
  fine idea; it is no longer *load-bearing*.)
- **Name and message plausibly come back.** The artist's screen can collect them
  *before* initiating the charge and stuff them into `metadata[nickname]` /
  `metadata[message]`. The stage screen gets its message back and the feature
  stops being a downgrade.

  **This is unverified.** Design it and test it (Experiment B-2 below). The UX is
  the hard part, not the API: asking a fan for their name while holding a card
  reader is a different social interaction from typing it into a checkout page,
  and the answer might be "offer it, don't require it".

### Cost to the artist: one reader, once

[stripe.com/terminal](https://stripe.com/terminal), **observed 11 July 2026** —
re-verify, hardware prices and line-ups move:

| Reader | Price | Notes |
| --- | --- | --- |
| **BBPOS WisePad 3** | **€59** | Cheapest; **SDK-driven, not server-driven** — see caveat |
| **BBPOS WisePOS E** | **€199** | Server-driven, Stripe's recommended integration |
| **Stripe Reader S700** | **€259** | Server-driven; also does standalone mode (§6) |

> **Caveat that matters:** the €59 WisePad 3 is a *mobile* reader — it pairs over
> Bluetooth to an SDK, which puts it back in Option A's world (Terminal SDK,
> `mek_stripe_terminal`, native only). The **server-driven** guarantee — and
> therefore the browser client, and therefore this entire option — applies to the
> **smart readers (WisePOS E, S700/S710)**, which are the €199+ ones. Do not
> quote the €59 figure to an artist as the price of this feature.

So the honest artist-facing number is **€199 up front**, plus 1.4% + €0.10 per tip.
That is a real barrier for a busker and a non-issue for a working band that plays
weekly. It should be presented as an *option*, never as a requirement, and never
as something that pays for itself in fees (it doesn't: at a 15-cent saving per €2
tip, a €199 reader breaks even at ~1,300 tips).

### Cost to the security model: two write scopes — stated honestly

| Resource | Permission | Why |
| --- | --- | --- |
| **PaymentIntents** | **Write** | Create the card-present PaymentIntent |
| **Terminal Readers** | **Write** | `process_payment_intent` on the artist's reader |
| *(plus Phase 0's)* | PaymentIntents Read, Charges Read | Observe the result |

This is a **real reduction in least privilege** and I am not going to soften it.
Today the key cannot initiate a payment. With PaymentIntents Write it can — a
stolen device could create charges in the artist's account (it still cannot move
money *out*: no payouts, no refunds, no balance, no transfers, and any charge it
creates lands in the artist's own balance, not ours). The current
[security FAQ](onboarding/create-restricted-key.md#security-faq) answer to "what's
the worst case if my device is stolen?" changes, and the doc must change with it.

*Mitigation:* these scopes are **only needed by artists who own a reader**. The
key stays read-mostly for everyone else. The onboarding deep link should therefore
gain a *variant* — "I have a Stripe reader" — rather than pushing two write scopes
onto every artist in the world. That is a small amount of work and it keeps the
default posture where it is.

### Tasks

1. **Experiment B-1** (below) — confirm restricted-key scopes are sufficient for
   both calls, end-to-end, on a simulated reader in a sandbox. Cheap, and it
   should be done before buying hardware.
2. `StripeRequests`: `createCardPresentPaymentIntent({amount, currency, metadata})`
   and `processPaymentIntentOnReader({readerId, paymentIntentId})`. Two methods,
   same shape as everything else in that file.
3. Reader pairing UX: `GET /v1/terminal/readers` (needs Terminal Readers Read),
   list them, remember the chosen one **per band** (it belongs with the key and
   the jar — see the Bands section of [architecture.md](architecture.md)).
4. "Take a tip" flow on the stage/home screen: amount → optional name/message →
   create PI → process on reader → poll for the outcome.
5. Failure handling in the same spirit as the poller: a reader that is offline,
   a declined card, a cancelled tap. `POST /v1/terminal/readers/{id}/cancel_action`
   for the abort path. **The tap must never be able to hang a live session.**
6. Ingestion stays the observer path from Phase 0 — the tip appears on the stage
   because the poller saw it, not because the "take a tip" flow reported success.
   One source of truth. (This also means a tap taken from the Stripe Dashboard app
   *while* the reader flow exists still works, for free.)
7. Docs: the write-scope variant of the restricted key, and the updated stolen-device
   answer.

### Risks

- **Reader connectivity is the artist's problem and will become our support
  burden.** Smart readers need wifi. Venue wifi is bad. Design the error copy for
  a loud room and a nervous performer.
- **Pinned `Stripe-Version: 2024-06-20`** (see [architecture.md](architecture.md)).
  Confirm the card-present PaymentIntent + `process_payment_intent` shapes are
  stable at that version — this is part of Experiment B-1, not an afterthought.
- **The 1.4% + €0.10 in-person rate is assumed to carry no Tap-to-Pay surcharge**
  (the surcharge is documented as specific to Tap to Pay). Verify on the artist's
  own pricing page before the €1.87 figure appears in any user-facing copy.

---

## 6. Parking lot

Not planned. Recorded because they are cheap to remember and expensive to
rediscover.

### Standalone mode — the zero-effort path Phase 0 already unlocks

The **Stripe Reader S700/S710** and **Verifone V660p** have a no-code POS **built
into the reader**: *"no custom app, SDK integration, or POS system required"* —
and it supports **on-reader tipping** ([stripe.com/terminal](https://stripe.com/terminal),
observed 11 July 2026).

Which means: an artist can buy an S700, enter an amount on the reader, take a tap,
and **live.tips sees the tip anyway** — through Phase 0's observer, with zero
live.tips code and zero live.tips integration. The stage screen fills, the goal
bar moves, the confetti fires.

This is not something to build. It is something to **tell artists about**, and it
is a decent argument for shipping Phase 0 well and documenting it: the observer
turns every card-present surface Stripe sells — Dashboard app, standalone reader,
someone else's POS in the same account — into a live.tips input, for free.

### Android tablet as both stage and reader

Android tablets support Tap to Pay; iPads do not have NFC at all. So an
NFC-equipped Android tablet on a stand is the **only single-device configuration**
in this document: it shows the stage *and* takes the tap. It is an appealing
picture. It is also gated on all of Option A (entitlement-free on Android, but
still Terminal SDK, still native-only, still `mek_stripe_terminal`), so it is not
a shortcut — it is a *reason to revisit Option A on Android only*, if Option B
ships and artists start asking for a no-hardware version.

---

## 7. Decision table

| | **Phase 0 — Observer** | **Option A — Tap to Pay** | **Option B — Server-driven reader** | **Standalone (parking lot)** |
| --- | --- | --- | --- | --- |
| Keeps the browser client? | ✅ yes | ❌ **no** — native only | ✅ **yes** | ✅ yes (nothing to build) |
| Needs a native app? | ❌ no | ✅ yes + App Store/Play payments review | ❌ **no** | ❌ no |
| Needs a live.tips server? | ❌ no | ⚠️ **unknown** — gated on experiment A-0 | ❌ **no** (Stripe REST only) | ❌ no |
| Needs a Terminal SDK? | ❌ no | ✅ yes (`mek_stripe_terminal`, 1 maintainer) | ❌ **no** | ❌ no |
| Needs an Apple entitlement? | ❌ no | ✅ yes — dev **and** distribution | ❌ **no** | ❌ no |
| Needs Stripe Connect? | ❌ no | ❌ no | ❌ no | ❌ no |
| Keeps fan name + message? | ❌ **no** (amount only) | ❌ no (mitigation unproven) | ⚠️ **plausibly yes** via `metadata` — unverified | ❌ no |
| Tips distinguishable from other payments? | ❌ only via a **dedicated Stripe account** | ❌ same | ✅ **yes** — `metadata` tag | ❌ dedicated account |
| Restricted-key scopes added | PaymentIntents Read, Charges Read | + Terminal Write | + **PaymentIntents Write**, **Terminal Readers Write** | same as Phase 0 |
| Artist hardware cost | **€0** | **€0** (their iPhone/Android) | **€199** (WisePOS E) / €259 (S700) | €259 (S700) |
| Fee on a **€2** tip | depends on surface | 1.4% + €0.20 → keeps **€1.77** | 1.4% + €0.10 → keeps **€1.87** | keeps **€1.87** |
| Effort | **shipping now** | large + ongoing (store review, SDK ownership) | **moderate** (2 API calls + UX) | zero |
| Verdict | ✅ ship | ❌ **not recommended** | ✅ **build this** | 📣 recommend to artists |

(Payment Link today, for reference: 1.5% + €0.25 → artist keeps **€1.72** on €2.
SumUp, for reference: keeps **€1.97**. No Stripe path beats it on a €2 tip.)

---

## 8. Open questions, and the exact experiment that resolves each

Nothing below is a guess I want to defend. Each one is cheap to settle, and the
plan changes depending on the answer.

**Q1 — Does an on-device restricted key mint a Terminal connection token?**
*Gates all of Option A.*
> Sandbox. Create `rk_test_…` with **Terminal: Write**. `POST /v1/terminal/connection_tokens`
> with it. **200 + `secret`** → Option A is serverless and viable. **403** →
> Option A needs a live.tips server, breaks promise 2, and is dropped.
> Cost: 30 minutes, €0.

**Q2 — Do PaymentIntents Write + Terminal Readers Write on a restricted key
suffice for the whole server-driven flow?** *Gates Option B.*
> Sandbox, [simulated reader](https://docs.stripe.com/terminal/references/testing).
> `rk_test_…` with those two scopes: `POST /v1/payment_intents` with
> `payment_method_types[]=card_present` + `metadata`, then
> `POST /v1/terminal/readers/{id}/process_payment_intent`, then confirm the
> `/v1/events` poller sees it **at the pinned `Stripe-Version: 2024-06-20`** with
> metadata intact. Cost: half a day, €0, no hardware. **Do this before buying a
> reader.**

**Q3 — Does `metadata` on a card-present PaymentIntent survive into the polled
event, and can we build a fan-facing name/message capture around it that a real
performer would actually use?**
> Part API (settled by Q2), part product. The API half is free. The product half
> needs a rehearsal with a real reader and a real audience, and the acceptable
> answer may be "make it optional and expect most taps to be anonymous".

**Q4 — Is the WisePOS E genuinely fully driveable from `api.stripe.com` with no
SDK anywhere, including pairing?** *This is the load-bearing claim of Option B.*
> Q2 answers it for a simulated reader. Answer it for a **real** one before
> promising it to artists — buy one WisePOS E (€199, one-time, on the maintainer)
> and drive it from the **web** build of the app, in a browser, over the wire. If
> that works, Option B is proven end-to-end and the browser promise holds.

**Q5 — Does the in-person 1.4% + €0.10 rate really carry no Tap-to-Pay surcharge
for physical readers?**
> Read the fee breakdown on an actual card-present charge in the artist's own
> Stripe balance transaction (`GET /v1/balance_transactions/{id}` → `fee_details`).
> One real €1 tap settles it. Do not put €1.87 in user-facing copy until it does.

**Q6 — Does an artist with a dedicated tips account actually keep it clean?**
> Not an API question. Phase 0's correctness depends on a human following advice.
> Watch what happens with the first few artists before leaning on it further.
