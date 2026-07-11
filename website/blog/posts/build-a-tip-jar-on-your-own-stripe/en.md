---
title: Build a tip jar on your own Stripe account
description: Three API calls give you a hosted, pay-what-you-want tip page with Apple Pay and Google Pay, and no server anywhere. Here is the whole build — the restricted key, the scopes, reading tips back without a webhook, and the fee maths nobody prints.
---

You want a tip jar. You do not want to hand a platform 5% of a busker's evening,
and you are perfectly capable of talking to an API. So the question is not *which
tip jar should I sign up for*, it is *how much do I actually have to build*.

Less than you think. On Stripe, the working answer is three API calls, no server,
no backend, and no webhook endpoint. The rest of this post is that build, plus the
two things everybody gets wrong about it.

## The trick is a pay-what-you-want Price

Stripe has a pricing mode where the fan types the amount. It is called
[pay-what-you-want](https://docs.stripe.com/payments/checkout/pay-what-you-want),
and it is the entire feature. You create a Product, attach a Price with
`custom_unit_amount[enabled]=true`, and hang a
[Payment Link](https://docs.stripe.com/payment-links/create) off it.

```sh
# 1. the thing you are "selling"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. the price the fan gets to choose
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. the page
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

That third call returns a `url`. That URL is your tip jar. It is a Stripe-hosted
page, so it is PCI-compliant without you thinking about it, it is localised, and
it shows Apple Pay or Google Pay to any fan whose phone has them set up —
[dynamic payment methods](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
decide that for you based on the device and the country. You wrote no frontend.

Encode the URL as a QR code with any library you like — it is just a string —
print it, tape it to the case. Nothing about the code expires, and nothing about
it points at a server of yours, because you do not have one.

Two flags worth knowing while you are in there:

- **`custom_unit_amount[preset]`** is the amount the page opens on. `500` means the
  fan sees €5.00 already filled in and can change it. This number does more for
  your average tip than anything else on the page.
- **`custom_unit_amount[minimum]`** is a floor. Set one. The reason is in the fee
  section below, and it is not a rounding error.

You can also collect a name and a message. Payment Links take up to three
`custom_fields`, which is how you get "who was that from" onto the page without
building a form:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Your name or nickname" \
  -d "custom_fields[0][optional]"=true
```

Stripe has [requirements for accepting tips and donations](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
read them once. Pay-what-you-want also can't be combined with other line items,
discounts, or recurring payments. For a tip jar, none of that bites.

That distinction is worth getting right. In Stripe's own words, a tip is given for a
good or service already provided, while a donation must be tied to a charitable purpose.
You played the set; the tip pays for it. That is also why the call above sends
`submit_type=pay` and not `donate` — `donate` would host your link on `donate.stripe.com`
and print *Donate* on the button. That is a different business, and one Stripe reviews
far more heavily.

## The key: assume it leaks, and make that boring

Do not put a secret key (`sk_live_…`) on a device that sits on a stage. Use a
[restricted key](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`),
where you pick a permission per resource and everything you did not pick is
**None**.

For the build above, the complete list is five rows:

| Resource | Permission | What it buys you |
| --- | --- | --- |
| Products | Write | create the Product |
| Prices | Write | create the pay-what-you-want Price |
| Payment Links | Write | create the link |
| Checkout Sessions | Read | see the tips that came in |
| Events | Read | the live feed (next section) |

Everything else — Balance, Payouts, Refunds, Customers, PaymentIntents, all of
Connect — stays on **None**.

Now do the exercise that makes this worth doing. Your tablet gets nicked from the
merch table at 1 a.m. What can the thief do with the key in its keychain? Read
your tip history, and create more tip links in your account. That is the
whole blast radius. They cannot see your balance, cannot trigger a payout, cannot
issue a refund to a card they control, cannot read a customer list. You revoke the
key from a phone in the taxi home and the device goes dark. Nothing about your
money moved.

That asymmetry — write access to the tip jar, zero access to the money — is the
only reason a serverless, bring-your-own-key design is defensible at all. It is
also why "Login with Stripe" is not the answer here: OAuth needs a server of the
app developer's to hold your token, and a server is exactly the thing we are not
building.

(A quirk you will hit: the *Prices* permission is internally called `plan_write`,
so Stripe's error message names a scope that does not appear in the dashboard UI
under that name. It is Prices.)

## Reading tips back without a webhook

Here is where most write-ups either stop or reach for a webhook, and where a stage
is genuinely different from a web app.

A webhook is an inbound HTTP request. A tablet behind a mic stand cannot receive
one. It is on a venue's guest Wi-Fi behind NAT, it has no public address, no TLS
certificate, and no business having any of those. If you take the webhook route
you must stand up a server to catch the events and a socket to push them to the
device — which is a backend, an ops burden, and a place your fans' names now live.
You just rebuilt the platform you were trying to avoid.

So pull instead of push. Stripe's
[List all events](https://docs.stripe.com/api/events/list) endpoint is public,
documented, and returns events newest-first:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_LAST_ONE_I_SAW \
  -d limit=100
```

`ending_before` is the whole design. Keep the id of the newest event you have
processed; each poll asks for everything strictly newer than it, and you advance
the cursor. No timestamps, no clock skew, no dedupe by amount. On the first poll
of a set, ask for `limit=1` with no cursor to anchor on whatever is already there,
so you do not replay this morning's tips at soundcheck.

Then filter what comes back. Both event types can fire for a single payment, so
dedupe on the Checkout Session id. Check `payment_status == "paid"` — a completed
session is not necessarily a paid one. And check `payment_link` matches *your*
link, because `/v1/events` is account-wide and will happily hand you traffic from
whatever else that Stripe account does.

Be straight about the trade-offs, because they are real:

- **Stripe recommends webhooks.** Polling is not the blessed path; it is a
  documented endpoint being used deliberately. Say so in your README and move on.
- **Events go back 30 days.** [Stripe's own words](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* This is a live feed, not your ledger.
  Your ledger is Checkout Sessions, and your real ledger is the Stripe dashboard.
- **Watch the read allocation.** Everyone checks the per-second
  [rate limit](https://docs.stripe.com/rate-limits) (100 req/s live) and nobody
  checks the other one: Stripe allocates roughly **500 read requests per
  transaction** over a rolling 30 days, with a floor of 10,000 reads a month. Poll
  every 4 seconds and a three-hour set is ~2,700 reads. Four long gigs in a month,
  and you are at the floor. Tips buy you more headroom as they arrive, but if you
  poll every second because it felt snappier, you will find the ceiling. Four
  seconds is not a lazy number; it is the number.

That is the honest shape of it: polling costs you a few thousand GETs and buys you
the deletion of an entire backend.

## The fee maths, done properly

A platform advertising 0% is not free, and neither is this. Stripe's own
processing fee applies to every tip, and Stripe charges it to you directly.
Today, on [Stripe's euro pricing](https://stripe.com/ie/pricing), a standard EEA
card is **1.5% + €0.25**. Premium EEA cards are 1.9% + €0.25, UK cards 2.5% +
€0.25, and everything else 3.25% + €0.25 with another 2% if a currency has to be
converted. (In the US it is 2.9% + $0.30, which is worse for exactly the reason
below.)

The percentage is not the problem. The twenty-five cents is.

| Tip | Stripe takes | Artist keeps | Effective cut |
| --- | --- | --- | --- |
| €2 | €0.28 | €1.72 | **14.0%** |
| €5 | €0.33 | €4.67 | 6.5% |
| €10 | €0.40 | €9.60 | 4.0% |
| €20 | €0.55 | €19.45 | 2.8% |
| €50 | €1.00 | €49.00 | 2.0% |

A flat fee is a percentage in disguise, and on small money the disguise slips. The
same €0.25 that is invisible on a €50 tip eats an eighth of a €2 one. Tips are
small by nature — that is what makes them tips — so this is not an edge case, it
is the median case.

Which is why you set `custom_unit_amount[minimum]`. Somewhere around €2 the
transaction stops being worth processing; a €0.50 card tip would arrive as €0.24
and cost Stripe more to move than it is worth. Pick your floor deliberately rather
than discovering it in your first payout.

And notice what this does to the comparison you started with. A platform charging
0% on top of Stripe is charging you 0% on top of *this*. Their 0% is real, and it
is 0% of what the processor left. Nobody's card rail is free — the honest claim is
"no cut beyond the processor's", and anyone claiming more than that is either
lying or is not using cards.

## What you have now, and what you don't

Three API calls and a QR code, and a real tip jar: hosted, PCI-compliant, Apple
Pay, Google Pay, tips landing in your own Stripe balance on your own payout
schedule, and no server in the path. For a lot of people that is genuinely the end
of the project, and you should feel free to stop here and ship it.

What you do not have is a stage. You have a payment page. Standing between that and
a working night are the boring things: the poll loop with its cursor and its
backoff, a screen the audience can see with the goal and the last message on it,
somewhere to keep the key that is not `localStorage`, a lock so a stranger cannot
poke the tablet between sets, and the thousand-small-decisions layer of what
happens when the venue Wi-Fi drops mid-set.

That is what [live.tips](https://github.com/mekedron/live.tips) is — this exact
architecture, finished, MIT-licensed. The restricted key with those five scopes, the
`/v1/events` cursor loop, the Product/Price/Payment Link creation, all of it running
on the performer's device against their own account. There is no live.tips server in
the Stripe path and no live.tips balance anywhere, which we wrote up separately in
[how live.tips handles money](post:how-live-tips-handles-money).

Read the source, lift the parts you want, or just use it. The point of this post is
that the architecture is not a secret and not hard: **Stripe will host your tip jar
for free, and a restricted key plus a polling loop is all that stands between a
performer and their own money.** We would rather you knew that than signed up for
anything.
