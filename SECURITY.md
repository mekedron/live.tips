# Security policy

live.tips moves real money between a fan and an artist, and it holds Stripe keys.
A weakness here is not an abstraction — it is someone's night's earnings.

## Reporting a vulnerability

**Do not open a public issue for anything exploitable against production.**
This repository is public; an issue is a working exploit recipe, published before the fix.

Instead, [open a draft security advisory](https://github.com/mekedron/live.tips/security/advisories/new).
It is private between you and the maintainers until we publish it.

If you cannot use advisories, email **nikita.rabykin@aikamatkat.fi** with `[live.tips security]` in the subject.

Please include:

- what an attacker gains, and what it costs them to get it;
- the concrete path — inputs, state, the call sequence;
- the bound, if there is one (a short TTL, required pre-positioning, self-healing behaviour).

We will confirm receipt, tell you whether we can reproduce it, and keep you posted until it is closed.

## What is in scope

- The Cloud Functions behind `tip.live.tips` and `auth.live.tips` (`firebase/functions/`)
- Firestore security rules (`firebase/firestore.rules`)
- The Flutter app's handling of Stripe keys, device identity, and account data (`app/lib/data/`, `app/lib/state/`)
- The device-linking and venue sign-in ceremonies

## What is out of scope

- Denial of service through sheer volume against Google's infrastructure
- Findings that require an already-compromised device or an already-stolen session, with no escalation beyond it
- Missing hardening headers on the marketing site with no demonstrated impact
- Reports from automated scanners with no verified failure scenario

## Public security issues

Some security work carries no disclosure risk — hardening, defence-in-depth, a
weakness that needs access we already trust. That can be filed as a normal issue
using the "Security finding" template.

When in doubt, report privately. We would rather triage one over-cautious advisory
than read about a jar being drained on the internet.
