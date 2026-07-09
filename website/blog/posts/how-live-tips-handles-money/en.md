---
title: How live.tips handles money (it doesn't)
description: There is no live.tips balance, no payout schedule, and no cut. Here is the architecture that makes those three claims boring instead of brave.
---

Any tip jar can put "0% fee" on its landing page. The interesting question is
what the software would have to do to *start* taking a cut, and how much of it
you would be able to see.

For live.tips the answer is: it would have to be rebuilt. That is not a promise
about our intentions, it is a description of where the money goes.

## Card tips never pass through us

When a fan taps a card amount, their browser talks to `api.stripe.com`. Not to a
live.tips server — there isn't one in that path. The payment is created against
**your** Stripe account, settles into **your** Stripe balance, and is paid out on
**your** Stripe schedule. The only fee is Stripe's own standard processing fee,
which Stripe charges you directly, exactly as it would if you had integrated
Stripe yourself.

There is no ledger on our side because there is nothing to record. We could not
skim a percentage without first building the thing that holds the money.

## Your keys stay yours

Setup asks for a *restricted* Stripe API key, not a live secret key — we refuse
those outright. It is stored in your device's own keychain and only ever sent to
Stripe over TLS.

Restricted means the key can do two things: create the pay-what-you-want tip link,
and watch tips arrive. It cannot read your balance, trigger payouts, issue refunds,
or touch customer data. If it leaked tomorrow, the blast radius is a tip link.

## The one place a server exists

Revolut and MobilePay cannot be driven from a browser the way Stripe can, so
enabling them turns on a minimal relay at `api.live.tips`. It is worth being
precise about what that relay does, because "we added a backend" is usually where
these stories go wrong.

It stores your public tip-page profile — the display name and the payment handles
you chose to publish. That is all. It keeps no donation history, sees no money,
holds no keys, and self-deletes after 90 days of inactivity. Money still moves
directly between your fan's Revolut or MobilePay app and yours.

If you only use Stripe, the relay is never contacted at all.

## Why you should not take our word for it

All of the above is checkable. The codebase is MIT-licensed and public, and the
site is a static build deployed by GitHub Actions to GitHub Pages — no hidden
infrastructure, nothing compiled behind a door. Open the network tab during a
demo tip and read the requests. There are fewer than you expect.

That is the actual product claim. Not that we are trustworthy, but that you do
not need us to be.
