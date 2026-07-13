---
title: Terms of Use
description: live.tips is free, open-source software. We are not a payment provider, we never hold your money, and we make no promises about tips we cannot see. The details, in plain words.
updated: 2026-07-13
updated_label: Last updated 13 July 2026
---

These terms cover the live.tips app, this website, the optional live.tips **account**, and
the optional relay behind the tip pages at `tip.live.tips`. live.tips is run by **Nikita
Rabykin**, an individual developer — not a company, not a team — and is released as free
and open-source software under the
[MIT licence](https://github.com/mekedron/live.tips/blob/main/LICENSE).

By using live.tips you accept what follows. It is short, because live.tips does very
little on your behalf — and that is the point.

## What live.tips is

live.tips is **software you run yourself**. It turns your own Stripe (or Revolut,
MobilePay, Monzo) account into a live tip jar with a QR code and a screen that fills up
as fans tip.

## What live.tips is not

**We are not a payment service, a bank, an escrow, or a party to your transactions.** We
never hold, route, or touch anyone's money. A tip travels directly from the fan to the
artist's own payment account. There is no live.tips balance in the middle, because there
is no live.tips balance at all.

This means, concretely:

- We take **no commission** and charge **no fee**. There is nothing to pay us.
- We **cannot refund a tip**, because we never had it. Refunds belong to the artist and
  their payment provider.
- We **cannot see, freeze, reverse, or recover** any payment.
- Your relationship for the money itself is with **Stripe, Revolut, MobilePay or Monzo**,
  under their terms — not with us.

## Tips are payments for a performance

Tips collected through live.tips are **voluntary payments to an artist for their live
performance**. They are **not charitable donations**, and live.tips is not a fundraising
platform. Artists must describe their business to their payment provider accordingly —
Stripe, in particular, treats performance and fundraising as different things, and only
one of them is you.

## Accounts

An account is **optional**, and there is still nothing you have to sign up for. The app
works with no account at all — that is the default, everything stays on your device, and
no live.tips server is involved.

If you want your bands, settings and history on more than one device, you can sign in
with **Apple**, with **Google**, or as an anonymous **guest**. An account is a place to
keep *your own* data, on **Firebase** (Google), readable by your account and by no other.
What it holds — and what signing in changes about your privacy — is set out in the
Privacy Policy, which is worth reading before you sign in.

If you have an account:

- **It is yours to look after.** Anyone who can sign in as you can see everything in it.
  Keep your sign-in method secure, and use **Settings → Security** to review your devices,
  revoke one, or sign out everywhere else.
- **A guest account cannot be recovered.** It has no email and no password. Lose every
  device signed into it and its data is gone — that is the trade for signing in without
  giving us anything. Use Apple or Google if that matters to you.
- **You are responsible for what is in it** — your band names, your public messages, and
  anything else you put there.
- **Adding a device needs your confirmation** on a device that is already signed in. Do
  not confirm a device you did not ask for, and do not let someone photograph the QR code
  and then tap confirm anyway.
- **We may suspend or delete an account** — see *Ending it*, below.

## If you are an artist

You are responsible for:

- **Your own payment account** — keeping it in good standing and following Stripe's or
  Revolut's, MobilePay's or Monzo's rules.
- **Your taxes.** Tips are income. We do not report anything to anyone, issue any tax
  document, or know what you earned.
- **Refunds, disputes and chargebacks**, which you handle in your own payment dashboard.
- **The law where you perform** — busking permits, venue rules, and anything else local.
- **What you publish.** Your artist name and message appear on a public tip page; keep
  them lawful and your own.
- **Your Stripe key.** It is a restricted key you created yourself, and it lives on your
  device — and, if you sign in, in your account's private storage too, so your other
  devices can use it. Either way it is yours: treat the device as you would treat cash,
  and revoke the key in your Stripe dashboard if one goes missing.
- **Your bands, and the fan messages you put on screen.** A name and a message are shown
  to a room full of people. What appears on that screen is yours to moderate.

## If you are a fan

- Tipping is **voluntary** and, once sent, a tip is generally **final** — a live tip is
  not a purchase with a right of return.
- If something went wrong with a payment, take it up with **the artist** or with the
  payment provider that processed it. We have no record of it and no power over it.
- Please keep the name and message you attach lawful and civil. They are shown on a
  screen, on stage, in front of a room full of people.

## Unverified tips — read this one

Revolut, MobilePay and Monzo give an app **no way to confirm that a payment actually
happened**. A tip sent through those methods appears on the artist's screen **the moment
the fan submits the form** — whether or not they then go through with the payment.

live.tips labels these tips **unverified**, and they mean exactly that: *someone said
they paid.* They are a stage effect, not a receipt.

**Never treat an unverified tip as proof of payment.** Artists must reconcile against
their own Revolut, MobilePay or Monzo app. Stripe tips are the only ones live.tips can
actually confirm, which is why Stripe is the recommended method.

## The relay and the tip pages

Tip pages live at `tip.live.tips`, served by a small relay we run on Firebase. It is
offered **free of charge, as a courtesy, with no guarantee of any kind**. It is
best-effort: it may be rate-limited, it may be unavailable, tips may be delayed or lost,
and it deliberately keeps nothing that would let anyone recover them afterwards — a
delivered tip is deleted the instant the artist's screen shows it, and an undelivered one
is deleted after an hour.

- A tip page with **no account behind it is deleted after 90 days of inactivity**.
- We may **rate-limit, block, or delete any tip page**, at any time, without notice — in
  particular where we see fraud, impersonation, abuse, illegal content, or an attempt to
  overload the service.
- We may **change or shut the relay down entirely**. If we ever do, Stripe-only setups
  will keep working, because they never depended on us.

You must not use the relay, a tip page or an account to impersonate someone, to commit
fraud, to publish illegal or abusive content, to solicit charitable donations under false
pretences, to get around the rate limits or the anti-bot check, or to attack the service.

## Ending it

- **You** can stop at any time: sign out, remove a band, delete a tip page, or uninstall
  the app. The Privacy Policy says exactly what each of those deletes — and says honestly
  that deleting a whole account is, for now, an email to
  **[contact@live.tips](mailto:contact@live.tips)** rather than a button in the app.
- **We** may suspend, revoke or delete an account, a tip page, or access to the service
  where it is used for any of the things listed above, or where letting it run would put
  the service or other people at risk. There is no appeals panel here. There is an email
  address, and a person who reads it.
- If the hosted service is ever shut down, we will say so on this site. Nothing of value
  is locked inside it: the money is already in your own payment account, the app is open
  source, and a Stripe-only setup never needed us at all.

## No warranty

live.tips is provided **"as is", without warranty of any kind**, express or implied,
including any warranty of merchantability, fitness for a particular purpose, or
non-infringement. This is the standard MIT position, and it is meant literally.

We do not promise that the software is free of bugs, that the app will show every tip,
that your account will sync, that the relay will be reachable during your set, or that
any third-party service will behave.

## Liability

**To the maximum extent permitted by law, we are not liable** for any loss or damage
arising from your use of live.tips. That includes — without limitation — missed,
delayed, duplicated or undelivered tips; tips shown as unverified that were never paid;
data that failed to sync, or that went with an account you could not recover; lost income;
a device that failed on stage; the acts, outages or decisions of Stripe, Revolut,
MobilePay, Monzo, Google, Apple, Cloudflare or GitHub; and anything you lost because you
trusted a number on a screen.

live.tips is free software given away by one person. There is no revenue here to fund a
liability, and none is accepted.

Two honest limits on that paragraph, because a term that overreaches is worth nothing:

- We do **not** exclude liability for **death or personal injury caused by negligence,
  for fraud, or for anything else that cannot lawfully be excluded**.
- If you are a **consumer**, you keep every **mandatory right your local law gives you**.
  Nothing here takes those away.

## The software is yours

live.tips is MIT-licensed. You may **read, fork, modify, self-host, and run it yourself**
— including the relay. If you do not like how we operate the service, the honest answer
open source gives you is: run your own. The source is at
[github.com/mekedron/live.tips](https://github.com/mekedron/live.tips).

Nothing in these terms restricts the rights the MIT licence grants you over the code
itself; these terms govern the **hosted service** — this website, the accounts, and the
relay we run.

## Changes

We may update these terms as the software changes. Every past version is in the public
git history, so you can see precisely what changed and when. Continuing to use the
service after a change means you accept it.

## Contact

**[contact@live.tips](mailto:contact@live.tips)** — a real person reads it.

## Language

These terms are published in every language the site supports, as a convenience. If a
translation and the English version disagree, **the English version is the one that
counts**.
