---
title: Privacy Policy
description: live.tips has no accounts, no cookies, no analytics and no tracking. Here is the short list of what does get processed, by whom, and for how long.
updated: 2026-07-13
updated_label: Last updated 13 July 2026
---

live.tips is an open-source tip jar for performers. It is run by **Nikita Rabykin**, an
individual developer, not a company. If anything below matters to you, write to
**[contact@live.tips](mailto:contact@live.tips)** — that address reaches a person.

This policy is honest about the parts that are boring. We would rather say "we keep your
name for up to one hour" than claim we keep nothing and be wrong.

## The short version

- **No accounts.** There is nothing to sign up for.
- **No cookies.** Not one, anywhere.
- **No analytics, no tracking, no ads, no third-party scripts** on this website.
- **We never touch your money.** Tips go straight from the fan to the artist's own
  Stripe, Revolut, MobilePay or Monzo account. We are not in that path.
- **In the default setup, the app talks only to Stripe** — not to any live.tips server.
- The only server we run at all is a small relay, and it only exists if an artist
  switches on Revolut, MobilePay or Monzo.

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

## The app

The live.tips app runs **on the artist's own device**. Everything it knows lives there:

- The **Stripe restricted key** is stored in the device keychain (iOS/macOS Keychain,
  Android Keystore) and is only ever sent to `api.stripe.com`.
- **Tip history, session history, the goal, and app settings** are stored in local
  device storage. This includes the names and messages that fans attach to their tips.
- Uninstalling the app deletes all of it. There is no cloud backup on our side, because
  there is no cloud on our side.

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

## Stripe

When a fan pays by card, they are on **Stripe's** checkout page, not ours. Stripe
collects and processes their payment data as an independent controller under the
[Stripe Privacy Policy](https://stripe.com/privacy). We never see card numbers, and we
have no access to the artist's Stripe account.

The artist's app reads their own tips from Stripe using the artist's own restricted key.
A fan's name and message, if they left one, travel from Stripe to the artist's device
and stop there.

## The relay — only if Revolut, MobilePay or Monzo are switched on

Stripe-only setups never touch this, and can stop reading here.

Revolut, MobilePay and Monzo offer no way for an app to confirm that a payment happened,
so those tips are routed through a small open-source relay we run on **Cloudflare** at
`api.live.tips`. It never touches money. Here is everything it handles.

### What the artist stores

Creating a tip page stores the artist's **display name, their public message, their
currency, and the payment handles they chose to publish** (their Stripe payment link,
Revolut username, MobilePay Box ID, Monzo username). All of it is information the artist
is deliberately publishing to fans anyway.

- **Retention: deleted automatically after 90 days of inactivity.**
- The artist can delete it **immediately** from the app, at any time.
- No email address, no password, no legal name, no bank details are ever collected.

### What a fan sends

The tip form asks for an **amount**, and optionally a **name** and a **message**. That is
the whole form. No email, no phone number, no account.

- If the artist's screen is **online**, the tip is passed straight through to it and
  **never written to disk**.
- If the artist's screen is **offline** — phone locked, no signal — the tip is **held in
  storage for up to one hour** so it is not simply lost, then handed over the moment the
  screen reconnects. If nobody reconnects, it is **deleted unseen**. This is the only
  fan-written text the relay ever stores, and one hour is its hard limit.
- Your name and message are also placed into the **payment note** that opens in Revolut,
  MobilePay or Monzo — that is how the artist knows who tipped. Those companies then
  process it under their own privacy policies.
- The relay keeps **no tip history**. It cannot show you, us, or anyone else a list of
  who tipped whom.

### IP addresses and anti-abuse

An open form that anyone can post to needs some protection from bots, so:

- Your IP address is used to **rate-limit** requests, and is sent to **Cloudflare
  Turnstile** (an anti-bot check that runs on the tip page) to verify you are not a bot.
  Turnstile is Cloudflare's product and is used instead of a CAPTCHA that profiles you.
- To stop someone creating thousands of tip pages, a **cryptographic hash of the IP** of
  whoever creates one is kept for about **two hours**, then discarded.
- **Cloudflare's operational logs** record the technical details of requests to the relay
  — URL, timing, status — for a few days. They do not contain fan names or messages.
  Cloudflare acts as our processor; see the
  [Cloudflare Privacy Policy](https://www.cloudflare.com/privacypolicy/).

### Counters

The relay counts **how many tips** a given tip page has relayed, so we can spot abuse and
know whether the thing is used at all. It is a number. It contains no fan data.

## Legal basis, if you need one (GDPR)

- Running the relay for an artist who switched it on, and delivering a fan's tip to the
  screen it was aimed at: **performance of a service you asked for**.
- Rate limiting, Turnstile and hashed-IP quotas: **legitimate interest** in keeping a
  free, open service from being destroyed by bots and fraud.
- Server logs: **legitimate interest** in operating and securing the service.

## Your rights

You can ask us to give you a copy of, correct, or delete anything we hold about you, and
you can complain to your national data protection authority. Write to
**[contact@live.tips](mailto:contact@live.tips)**.

In practice, most of it is already in your hands: artists can delete their tip page from
the app instantly, fan tips evaporate within the hour, and everything else lives on your
own device.

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
