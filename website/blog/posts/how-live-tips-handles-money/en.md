---
title: How live.tips handles money (it doesn't)
description: There is no live.tips balance, no payout schedule, and no cut. Here is the architecture that makes those three claims boring instead of brave.
---

Any tip jar can put "0% fee" on its landing page. The interesting question is
what the software would have to do to *start* taking a cut, and how much of it
you would be able to see.

For live.tips the answer is: it would have to be rebuilt. That is not a promise
about our intentions, it is a description of where the money goes.

## Money never passes through us

When a fan taps a card amount, the payment is created against **your** Stripe
account, settles into **your** Stripe balance, and is paid out on **your** Stripe
schedule. The only fee is Stripe's own standard processing fee, which Stripe charges
you directly, exactly as it would if you had integrated Stripe yourself.

There is no ledger on our side because there is nothing to record. We could not
skim a percentage without first building the thing that holds the money — and there
is no such thing.

That is true whether or not you sign in. What signing in changes is the *data*
path, not the money path, and the next two sections are honest about exactly how.

## Your keys, and where they live

Setup asks for a *restricted* Stripe API key, not a live secret key — we refuse
those outright. Restricted means the key can do two things: create the
pay-what-you-want tip link, and watch tips arrive. It cannot read your balance,
trigger payouts, issue refunds, or touch customer data. If it leaked tomorrow, the
blast radius is a tip link.

**With no account, that key never leaves your device.** It sits in the device's own
keychain and is only ever sent to `api.stripe.com` over TLS. No live.tips server is
in the picture at all.

**When you sign in, the key moves to us** — because a key that only exists on one
phone cannot serve the tablet on stage too. We encrypt it (a per-secret AES-256 key,
itself wrapped by Google Cloud KMS) and store it where nothing can read it back:
not another account, not us glancing at a database, not even you. It is unsealed
only inside our functions, used to talk to Stripe on your behalf, and never handed
to a device again. Say that plainly: signing in puts a live.tips server in the path
between Stripe and your tip history. Never the money — the data.

## The servers, and what they cannot do

There are two, and both are minimal.

**The relay** exists because Revolut and MobilePay cannot be driven from a browser
the way Stripe can. Enabling them turns on a handful of Firebase functions serving
your tip page at `tip.live.tips`. It stores your public tip-page profile — the
display name and the payment handles you chose to publish — and, for a page with no
account behind it, keeps no tip history: a tip waits only until your stage device
shows it, and anything nobody came back for is swept within the hour. It sees no
money and self-deletes after 90 days of inactivity. If you only use Stripe and never
sign in, the relay is never contacted at all.

**The webhook** exists only once you sign in. Because your key now lives with us,
Stripe reports each tip to a small function of ours, which writes it into your own
history so your other devices can show it. It is a copy of an event, not a copy of
the money. It cannot move a cent, and it can only ever write into the one account it
belongs to.

Neither server can take a cut, because neither is anywhere near the money. The most
either can do is fail — and a Stripe-only, no-account setup depends on neither.

## The account you do not have to make

The app still boots into a device-local profile, which is what it always was: your
tip jar, your key and your tip history live on the device and nowhere else. There
is nothing to sign up for.

Signing in — with Apple, with Google, or as a guest — is now possible, and it
exists for one reason: a second device. If the tablet on stage and the phone in
your pocket are to show the same night, something has to sit between them, and that
something is Firestore, under a user id only you can read. Your bands, settings, tip
history — and, encrypted as above, your Stripe key — live there. That is a real
change to the privacy story and it deserves saying plainly rather than being
discovered: without an account, no server ever sees a tip; with one, your own corner
of ours does, and our webhook is what writes it there. It is the price of the second
device, and it is yours to pay or refuse. What it never touches is the money — an
account moves your data, not your balance, and there is still no cut.

## Why you should not take our word for it

All of the above is checkable. The codebase is MIT-licensed and public, and the
site is a static build deployed by GitHub Actions to GitHub Pages — no hidden
infrastructure, nothing compiled behind a door. Open the network tab during a
demo tip and read the requests. There are fewer than you expect.

That is the actual product claim. Not that we are trustworthy, but that you do
not need us to be.
