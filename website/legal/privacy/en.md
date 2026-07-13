---
title: Privacy Policy
description: live.tips has no cookies, no analytics and no tracking, and works with no account at all. If you choose to sign in, here is exactly what gets stored, where, by whom, and for how long.
updated: 2026-07-13
updated_label: Last updated 13 July 2026
---

live.tips is an open-source tip jar for performers. It is run by **Nikita Rabykin**, an
individual developer, not a company. If anything below matters to you, write to
**[contact@live.tips](mailto:contact@live.tips)** — that address reaches a person.

This policy is honest about the parts that are boring. We would rather say "we keep your
name for up to one hour" than claim we keep nothing and be wrong.

## The short version

- **An account is optional.** The app works with no account at all, and that is still the
  default. If you want your bands and your history on a second device, you can sign in —
  and then some of it is stored on a server. Which is which is set out below.
- **No cookies.** Not one, anywhere.
- **No analytics, no tracking, no ads, no third-party scripts** on this website.
- **We never touch your money.** Tips go straight from the fan to the artist's own
  Stripe, Revolut, MobilePay or Monzo account. We are not in that path.
- **In the default setup, the app talks only to Stripe** — not to any live.tips server.
- The only server we run at all is a small relay on Google's Firebase. It exists if an
  artist switches on Revolut, MobilePay or Monzo — or if they sign in.

## This website

The site is static and hosted on **GitHub Pages**. As the host, GitHub receives the IP
address and browser user-agent of everyone who loads a page — this is ordinary web
server logging, it happens before any of our code runs, and we cannot switch it off.
GitHub processes it under its own
[privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
We do not read those logs and GitHub does not show them to us.

Beyond that, the pages you are reading load **nothing from anyone else**: fonts, icons
and images are served from live.tips itself. There is no Google Analytics, no tag
manager, no pixel, no embedded widget.

The site stores **two values in your browser's `localStorage`**, both set by you, both
readable only by this site, and neither ever sent anywhere:

| Key | What it remembers |
| --- | --- |
| `lt-landing-theme` | whether you chose light, dark or automatic colours |
| `lt-langbar-dismissed` | that you closed the "also available in your language" banner |

Clearing your browser storage deletes them. They are not cookies, they are not shared,
and they identify nobody.

## The app has two modes, and the difference is the whole story

Everything below turns on one question: **have you signed in?**

### Mode one — no account. Still the default, still unchanged.

The app runs **on the artist's own device**, and everything it knows lives there:

- The **Stripe restricted key** is stored in the device keychain (iOS/macOS Keychain,
  Android Keystore) and is only ever sent to `api.stripe.com`.
- **Tip history, session history, the goal, and app settings** are stored in local
  device storage. This includes the names and messages that fans attach to their tips.
- Uninstalling the app deletes all of it. There is no cloud backup on our side, because
  in this mode there is no cloud on our side.

**We never receive any of this.** The app ships with no analytics SDK, no crash
reporter, no push notifications and no advertising code — none, not disabled ones.

Two clarifications, so the "talks to nobody" claim stays exactly true:

- The app fetches **currency exchange rates** once a day from public rate APIs
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). These are plain
  requests for a public list of rates. They carry no information about you, the artist
  or any tip — but, like any web request, they do reveal your IP address to those
  services.
- If you use the **browser version** of the app, your browser downloads it from our
  static host (see *This website* above).

### Mode two — you signed in. Then some data leaves the device, on purpose.

Signing in is a deliberate act. Nothing signs you in for you, and nothing about the app
stops working if you never do. You sign in because you want a second device: the phone in
your pocket and the tablet on stage showing the same night, the same bands, the same
history.

That only works if a server holds them. **So it does, and that is the honest cost of the
second device.**

The server is **Firebase**, which is Google. There are three ways to have an account:

- **Sign in with Apple** or **Sign in with Google** — Firebase Auth receives whatever the
  provider hands over: a user id (uid) and, usually, an email address and a name. (With
  Apple you may hide your email; Apple then gives us a relay address instead.)
- **A guest account** — an anonymous account with no email and no name. It syncs and it
  can be revoked, but there is nothing to recover it with if you lose the device. It is a
  uid and nothing more.

Once you are signed in, the account gets its own private corner of Google's **Cloud
Firestore** database, at `users/<your uid>/`. The security rules grant that corner to
that uid **and to nobody else** — no other account can read it, URL-guessing included.
Inside it:

| What | Why it is there |
| --- | --- |
| Your **bands** — names, tip-jar and payment-method settings, poster wording, goals | so a band exists on every device you sign in on |
| Your **Stripe restricted key** and the relay tip-page secret | in a secrets document only your uid can read, and cached in each of your devices' keychains |
| **App settings** | so a device you add is already set up |
| **Session records and tip history** — including **the names and the messages fans attach to their tips** | because that history is exactly what you asked to see on the other device |
| The **live session** running right now | so a second screen can join tonight's set |
| Your **devices** — the name each one gives itself ("Nikita's iPhone"), its platform and model, when it was first and last seen | so Settings → Security can list them, and you can revoke one |
| A small **profile document** — the account name you chose, and which provider you used | so the account switcher can label it |

Now the important part, plainly: **with no account, a fan's name and message never leave
the artist's device. With an account, they are stored on Google's servers under the
artist's uid, as part of that artist's own synced history.** No other account can read
them, we do not look at them, and nothing is derived from them — but they are there, and
you should know that before you sign in.

Signing out puts the device back into the local mode. It does not delete the account's
data — see *Deleting things*, below.

### Adding a device by QR code

To add a device you show a QR code from a device that is already signed in. The code is
random, **single-use, and expires in two minutes**, and the new device gets nothing until
you tap *confirm* on the old one. While that handshake is open we hold the code, the name
the new device gave itself, and its platform — and the record is deleted when it expires.
A photographed QR code is useless without your confirming tap.

## Where all this physically lives

Firebase Auth, Cloud Firestore and our Cloud Functions run in the **European Union** —
the database in Google's `eur3` multi-region, the functions in `europe-west1`. Google
acts as our processor under the
[Firebase privacy and security terms](https://firebase.google.com/support/privacy) and
its own [privacy policy](https://policies.google.com/privacy). Like any large provider,
Google may involve infrastructure outside the EU for support and security; that is
governed by those terms, not by us.

## Stripe

When a fan pays by card, they are on **Stripe's** checkout page, not ours. Stripe
collects and processes their payment data as an independent controller under the
[Stripe Privacy Policy](https://stripe.com/privacy). We never see card numbers, and we
have no access to the artist's Stripe account.

The artist's app reads their own tips from Stripe using the artist's own restricted key —
straight from the device to `api.stripe.com`. **There is no live.tips server in that
path, and there never was.** A fan's name and message, if they left one, travel from
Stripe to the artist's device and stop there — unless the artist signed in, in which case
the device also saves them into that artist's own Firestore history, as above.

## The relay — only if Revolut, MobilePay or Monzo are switched on

Stripe-only setups never touch this.

Revolut, MobilePay and Monzo offer no way for an app to confirm that a payment happened,
so those tips are routed through a small open-source relay we run on **Firebase** — Cloud
Functions and Firestore in `europe-west1`, with the fan's tip page served from
**`tip.live.tips/t/<id>`**. It never touches money. Here is everything it handles.

### What the artist stores

Creating a tip page stores the artist's **display name, their public message, their
currency, and the payment handles they chose to publish** (their Stripe payment link,
Revolut username, MobilePay Box ID, Monzo username). All of it is information the artist
is deliberately publishing to fans anyway.

- **Retention: a tip page with no account behind it is deleted automatically after 90
  days of inactivity.** A tip page that belongs to a signed-in account lives as long as
  the band it belongs to.
- The artist can delete it **immediately** from the app, at any time.
- No email address, no password, no legal name, no bank details are collected here.
- The page's secret is stored **only as a hash**. We could not tell you the secret if you
  asked; we can only check one.

### What a fan sends

The tip form asks for an **amount**, and optionally a **name** and a **message**. That is
the whole form. No email, no phone number, no account.

- The tip is written to a **delivery queue** — a single document that exists to be handed
  to the artist's screen. When the screen shows the tip, **the artist's device deletes
  that document.** Deletion *is* the acknowledgement; there is no "delivered" flag,
  because there is no record left to flag.
- If the artist's screen is offline — phone locked, no signal — the tip **waits in that
  queue for up to one hour**, so it is not simply lost, and goes over the moment the
  screen reconnects. If nobody reconnects, it is **deleted unseen**, swept on a schedule
  whether or not anyone ever came back for it.
- **That queue is the only place fan-written text is ever stored on our server, and one
  hour is its hard limit.** If the artist is signed in, their device then keeps the tip in
  *their* Firestore history — because that is their history, and it is what they signed in
  for.
- Your name and message are also placed into the **payment note** that opens in Revolut,
  MobilePay or Monzo — that is how the artist knows who tipped. Those companies then
  process it under their own privacy policies.
- The relay keeps **no tip ledger**. It cannot show you, us, or anyone else a list of who
  tipped whom.

### IP addresses and anti-abuse

An open form that anyone can post to needs some protection from bots, so:

- Your IP address is sent to **Cloudflare Turnstile** — an anti-bot check that runs on the
  tip page — to verify you are not a bot. Turnstile is Cloudflare's product, and it is
  used instead of a CAPTCHA that profiles you. Turnstile and our DNS are the only things
  Cloudflare still does for us; the relay itself now runs on Firebase. See the
  [Cloudflare Privacy Policy](https://www.cloudflare.com/privacypolicy/).
- Your IP is also used to **rate-limit** requests — posting a tip, creating a tip page,
  redeeming an add-a-device code. What we store for that is a **salted cryptographic hash
  of the IP**, never the IP itself, for about **two hours**, and then it is deleted. The
  salt is a server secret: without it the code refuses to store anything at all, rather
  than keep a hash that could be reversed.
- **Google's operational logs** record the technical details of requests to the relay —
  URL, timing, status — for a few days. Our code deliberately logs no names, no messages,
  no secrets and no headers. Google acts as our processor.

### Counters

The relay counts **how many tips** a given tip page has relayed, so we can spot abuse and
know whether the thing is used at all. It is a number. It contains no fan data.

## Who processes what

| Who | What they get | Why |
| --- | --- | --- |
| **Google (Firebase)** | Accounts, a signed-in artist's synced data, the relay, server logs | The optional account and the optional relay |
| **Stripe** | The fan's payment data, as an independent controller | Card tips |
| **Cloudflare** | The fan's IP, for the Turnstile check on the tip page. And our DNS. | Keeping bots off the tip form |
| **GitHub** | The IP and user-agent of anyone loading this website | Hosting the website |
| **Revolut / MobilePay / Monzo** | Whatever the fan does in their own app, the payment note included | Those payment methods |

We sell nothing to anyone, and there is nobody else on that list.

## Legal basis, if you need one (GDPR)

- Running an account you asked for, syncing your own data to your own devices, running
  the relay for an artist who switched it on, and delivering a fan's tip to the screen it
  was aimed at: **performance of a service you asked for**.
- Rate limiting, Turnstile, hashed-IP quotas and device revocation: **legitimate
  interest** in keeping a free, open service from being destroyed by bots and fraud, and
  in keeping artists' accounts secure.
- Server logs: **legitimate interest** in operating and securing the service.

## Deleting things

This matters more than any promise we could make about it, so here is exactly what exists
today — including what does not.

- **No account**: uninstall the app. That is all of it, gone.
- **A band**: removing a band in the app deletes that band's cloud data — its settings,
  its keys, its sessions, its tip history — along with the copy on the device.
- **A tip page**: delete or regenerate it in the app and it is wiped from the relay at
  once, any pending tips included.
- **A device**: Settings → Security lists your devices. You can revoke one, or sign out
  everywhere else — which ends every other device's session immediately, not eventually.
- **Your whole account, in one tap: the app does not have that button yet.** We would
  rather admit that than pretend otherwise. Until it exists, write to
  **[contact@live.tips](mailto:contact@live.tips)** and we will delete the account and
  everything under it, by hand. In the meantime you can already delete every band, which
  removes everything of substance and leaves an empty account behind.

## Your rights

You can ask us to give you a copy of, correct, or delete anything we hold about you, and
you can complain to your national data protection authority. Write to
**[contact@live.tips](mailto:contact@live.tips)**.

In practice, most of it is already in your hands: an artist can delete a tip page or a
band from the app instantly, undelivered fan tips evaporate within the hour, and if you
never sign in, none of it was ever anywhere but your own device.

## Children

live.tips is not directed at children and we do not knowingly process their data.

## Changes

We will update this page when the software changes. Because the whole project is open
source, **every past version of this policy is in the public git history** — you can
diff exactly what changed and when.

## Language

This policy is published in every language the site supports, as a convenience. If a
translation and the English version disagree, **the English version is the one that
counts**.
