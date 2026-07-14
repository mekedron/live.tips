---
name: livetips-issues
description: File, triage and close issues in the live.tips tracker, and drive them to production through worktree subagents. Use whenever the user reports a bug from the device, asks to "create an issue", asks to fix open issues, or when an audit/review turns up findings. Covers the house style for an issue, the traps this codebase actually has, and the merge→deploy→verify loop.
---

# Issues in live.tips

The tracker is small, hand-maintained, and read by people who will act on it. An issue here is
not a ticket — it is an argument that something is broken, with enough evidence that the reader
can check it without you. Write it so a stranger could fix the bug from the issue alone.

## Delegate the verification — the orchestrator only commands

The main session is the master: it triages, dispatches, merges, deploys and reports. It does **not**
read the codebase to check a bug report, and it does not grep its way to a root cause. That work
goes to a subagent (`isolation: "worktree"`), which comes back with a verdict and, when the bug is
real, the filed issue number. Every finding in this skill was worth an agent's context, not the
orchestrator's.

A triage agent's brief is always the same three questions:

1. **Is it real in today's `main`?** A report may describe a build that was superseded an hour ago.
2. **Is it already filed?** Open *and* closed issues — and if the report is an instance of a wider
   invariant, file the invariant (see below).
3. **What is actually true?** The reporter's framing is a hypothesis (see below) — the agent must
   answer with `path:line`, not with sympathy.

Then it files the issue in the house style and reports the number back. The orchestrator launches
the fix agent from there.

## The reporter's framing is a hypothesis, not a finding

It is often inverted, and filing it verbatim is how a tracker fills with fiction. Every claim in an
issue must be something someone read in the code, not something they were told.

Three real cases from this project:

- The user asked for an issue saying *"Remove this profile should delete the cloud account, not the
  device copy."* The code already deleted account-wide — the **copy** was the liar ("from this
  device"). The true bug was the opposite of the request, and more dangerous. Filed as #27.
- The user asked to file the Revolut field eating the first typed character. Driving the real app
  showed the value arrives intact; the missing character was an artifact of typing before Flutter
  Web focuses its hidden input. **Not filed** — a bogus issue costs more than a missing one.
- The user suspected the switcher kept a signed-out account because the venue 12-hour flow needed
  it. `venue_providers.dart` `_scrub` already calls `accountsDirectory.remove(uid)`. The row served
  a different case entirely (a *dead session*, not a sign-out). The fix got narrower and safer, and
  the finding went into the issue as a comment.

If the code contradicts the report, **say so plainly and file what is true.** If it confirms it,
you now have file:line evidence to put in "Where it lives".

## Never file a duplicate — file the invariant instead

Check `gh issue list --state open` and the closed ones too. If the report is an instance of an
existing issue, say which and stop.

But look for the **generalisation**: the user described "removing the last profile mints a new one"
(already #23). Reading the code showed `_seedFirstBand` mints a profile from *three* call sites —
including one that resurrects a band deleted on another device, with no removal involved at all.
That invariant ("the app never creates a profile behind the artist's back") became #26 and was
worth more than the instance.

## The house style

Mirror `.github/ISSUE_TEMPLATE/bug_report.yml` — it asks for a failure scenario, not a stack trace.
An issue reads:

1. **Summary** — one paragraph. State the defect and, if it bites harder than it sounds, why.
2. **Failure scenario** — numbered, concrete: state → action → wrong outcome. Name the account
   kind (local / guest / Apple / Google), the device kind (own / venue), online or offline. Those
   four axes are where this app's bugs live.
3. **Where it lives** — `path:line` for every claim. Quote the 3-6 lines that are wrong when a
   quote settles it.
4. **Fix shape** — the shape, not the diff. If a decision is required, say *"Decision needed"* and
   lay out the honest options with a recommendation (#15: is a fan tip "artist activity"? #22: wire
   the dead surface or delete it?). Both got decided from the issue text alone.
5. **Why the tests didn't catch it** — mandatory, and usually the most valuable section. See below.
6. **Related / Dependencies** — issue numbers, and the order they must land in.

Sign off with the provenance line the audit issues use:
`<sub>Reported from the device (YYYY-MM-DD).</sub>` or `<sub>Found in the audit of <range>.</sub>`

Labels: exactly one `P0`–`P3`, one or more `type/*`, one or more `area/*`. `type/data-loss` and
`type/security` are not decoration — they change what gets fixed first. `cache-first` marks the
family below.

Write in the repo's voice: plain sentences, no hedging, no "it seems". Name the harm concretely —
"the artist is on stage looking at a feed that says it is live and is not" beats "incorrect state".

## When the bad behaviour is deliberate

Some of the worst findings are code doing exactly what a comment says it should. Quote the comment,
then argue against it. #31's sign-out kept the account row on purpose ("the directory keeps the
entry"); on a shared tablet that is the previous artist's email address sitting in the switcher.
#34's kill switch revokes the caller's own session on purpose, then relies on an interactive
re-login to restore it — the least reliable thing to require at the least reliable moment.

Say "this is deliberate, and that is the problem." Then show what the intent should cost.

## The trap this codebase keeps falling into

> **Real Firestore answers from the cache first. The test fakes answer with server truth.**

Six issues (#5, #6, #10, #12, #17, and the shape of #30) were this. `fake_cloud_firestore` never
raises a from-cache snapshot and accepts every write, so a cache-backed read treated as
authoritative is *invisible* to a green suite and wrong in production. The rule the fixes settled
on, worth restating in any new issue in this family:

**A cache proves what exists. It never proves what is absent.**

Related fake-shaped blind spots, all real: `FakeCallables` used to validate nothing (so a
client/server contract mismatch could not be seen — #20); the fakes always hand back a working
cipher (so a locked keychain at boot was untested — #4); tests call handlers directly, so
`trust proxy` and `X-Forwarded-For` behaviour only exist in the deployed runtime (#1).

When you write "why the tests didn't catch it", check whether it is one of these. If it is a *new*
blind spot, say so — the fix should widen the fake, not just patch the caller.

## Driving issues to production

The loop that worked, in order. It is deliberately serial at the merge point.

1. **One agent per issue, or per pair that shares a file.** Pair issues that would collide
   (#14+#15 edit overlapping lines of `tip.ts`; #23+#25 are one family) or that are truly blocked
   by each other (#3 by #2, #6 by #5). Give every agent `isolation: "worktree"`.
2. **Tell the agent what its base already contains.** Long sessions move `main` under running
   agents. When it does, message them to `git fetch && git rebase origin/main` and re-read the
   files — an agent that finishes against a stale tree builds on a screen that no longer exists.
3. **Merge one at a time, run the full suite after each.** `flutter test` (~600) and
   `cd firebase/functions && npm test` (~210), plus `flutter analyze` / `npm run check`. **If the
   diff touched `firebase/firestore.rules`, also run the perimeter suite:
   `cd firebase/rules-test && npm test`** — it loads the real rules into the Firestore emulator and
   proves the denials (the Flutter/functions fakes enforce no rules, so they cannot see a regression
   here). Needs Java for the emulator. Two
   independently correct fixes can contradict each other: #27's removal named a successor profile
   while #28's rule says an account with several profiles asks the artist. The merge produced a
   bug neither branch had. **When that happens, reconcile the rule — do not adjust the test.**
4. **Never `git add -A`.** It swept the user's untracked `marketing/producthunt/` into a commit.
   Stage explicit paths.
5. **Fake keys must be assembled, never written whole** — GitHub push protection blocks a literal
   in real Stripe key shape, even in a test. Follow `stripe-api.test.ts`: build it through
   interpolation, and keep the comment explaining why (a scanner taught to wave through fixtures
   stops protecting the real thing).
6. **Push to `main` — that is the deploy.** No PRs, no branches (the user's standing rule).
   `firebase.yml` fires on `firebase/**`, `pages.yml` on `app/**` + site paths. CI deploys with
   `--force`, so functions deleted from source really do disappear from prod (verify it — that was
   the whole point of #22).
7. **Verify on production, not in the suite.** `curl` for hosted pages and endpoints; the Firebase
   MCP for `functions_list_functions` and error logs; chrome-devtools MCP for the app
   (`~/.claude/scripts/start-chrome.sh` first; never claude-in-chrome; re-select your own page by
   URL before every interaction, because agents share one Chrome). Screenshots stay local — never
   commit or upload them. **If the diff touched the web sign-in bridge, Chrome does not finish the
   job — see "The web sign-in is verified in Safari" below.**
8. **Close with the truth.** `Fixes #N` in the commit body closes it on merge. When you cannot
   confirm a root cause, say so in the issue rather than implying a fix (#30: the symptom is closed
   by the one mechanism that produces it exactly, and the swallowed exception that hid it is gone —
   that is what was written, because that is what was known).

## The web sign-in is verified in Safari

**Rule: a diff that touches the web sign-in bridge, the redirect return leg, the pending-redirect
record or the custom-token handoff is not done until it has been driven in real Safari.** A green
suite and a green Chrome run do not close it. These are the paths that trigger the rule:

```
app/lib/data/firebase/auth_bridge.dart, auth_bridge_web.dart, auth_bridge_stub.dart
app/lib/data/firebase/auth_service.dart        (signInWithCustomToken)
app/lib/data/firebase/auth_domain.dart         (the authDomain — the 49c8c5c regression)
app/lib/data/firebase/account_sessions.dart    (the slot the token is redeemed on)
app/lib/state/auth_providers.dart              (startBridgeSignIn / consumePendingRedirect)
app/lib/features/account/redirect_sign_in_gate.dart
app/lib/domain/pending_redirect.dart
app/lib/data/local_store.dart                  (the pending_redirect_v1 keys)
app/lib/main.dart                              (the boot-URL fragment parse, main.dart:42-46)
firebase/hosting-public/signin.html            (the bridge page itself)
```

The surface is the `mcp__safari__*` MCP. It drives **real Safari** — verified, not assumed:
`safari_doctor` 6/6, `Version/26.5 Safari/605.1.15`, `navigator.vendor` "Apple Computer, Inc.",
Apple's own ITP. Chrome cannot answer the question this browser answers.

### Why Chrome is not enough — and the opposite mistake, which is the common one

The bridge exists *only* because of WebKit. `55ce609` and `auth_bridge.dart:1-23`: Safari hands a
cross-origin iframe partitioned, EMPTY storage — even for `auth.live.tips` under `live.tips` — so
Firebase's redirect result never arrives and the app hears nothing. `b9075e3` is the same engine
withholding a sessionStorage marker, so a completed sign-in was read as "nothing happened". Chrome
hands all of it back and goes green on the day production is broken. **A fake models what the server
answers; it cannot model what the engine withholds.** Only the engine can.

Now the counter-lesson, and it is the one you are more likely to need: **#54 looked like a Safari bug
and was not.** It was platform-independent Dart — a repository rebuilt cold under `ProfilePickScreen`
on the return leg — and it reproduces in Chrome. It survived because *nobody drives the web sign-in
end to end in any browser at all*. So: Safari is mandatory for the **storage** class, but the bigger
and cheaper win is driving the journey in **a** browser. Do not reach for "it's Safari" as an
explanation. Reach for it as an oracle.

### What this surface cannot do — read this before you trust a green run

- **It cannot click the Flutter app.** The app is a canvas: `safari_snapshot` returns only
  `flutter-view` (Flutter's semantics tree stays empty even after the placeholder is clicked), so
  there are no refs and no click-by-text. Synthetic PointerEvents dispatched at correct page
  coordinates — on `flutter-view` and on `flt-glass-pane` — are ignored by the engine; the native
  CGEvent fallback silently no-ops on macOS 26 (`safari_doctor` warns about this); AppleScript
  `System Events` "click at" errors `-25208`. **You cannot press "Continue with Google" from an
  agent.** Drive by URL instead — see the recipe. (Clicking is what Phase 2's `safaridriver` buys.)
- **The tab must be Safari's frontmost tab**, or the page is frame-suspended: `requestAnimationFrame`
  never fires, Flutter paints nothing, `flt-scene` stays empty and screenshots fail. An agent that
  skips this reads a blank window as "the app is broken" and files fiction. `safari_switch_tab`
  re-anchors the MCP's target but does **not** front the tab — front it explicitly:
  `osascript -e 'tell application "Safari" to set current tab of window 1 to tab N of window 1'`,
  then prove frames are flowing with a `requestAnimationFrame` counter before believing any pixel.
- **No boot console.** `safari_start_console` only captures after it is called and does not survive a
  navigation — so the console during boot, which is exactly when the redirect gate runs, is
  invisible. `safari_network` (Performance API) *does* survive boot, and shows the
  `auth.live.tips/__/auth/iframe` request — use it as the boot-time oracle.
- **It is the owner's real Safari, on his real profile.** `localStorage` holds his live accounts and
  `FlutterSecureStorage` keys. **Never clear storage, never sign out, never `safari_delete_local_storage`
  without a key.** Delete only the single key you wrote.
- **It is not an iPhone.** Desktop Safari shares the storage semantics that break us, but it is not
  the **installed PWA** context and not iOS ITP. `49c8c5c` was found in the PWA. A green desktop
  Safari run does not close a PWA-window or mobile-viewport question — that still needs the phone.
- No headless, no parallelism, one profile. `safari_evaluate` does not await promises: wrap the body
  in an IIFE and return a string. A cross-origin navigation can lose tab tracking ("refusing to
  target the user's current tab") — open a fresh `safari_new_tab` rather than fighting it.

### The recipe

The bridge's whole contract is a URL — outbound `#req=`, return `#signin=` (`auth_bridge.dart:14-17`).
That is what makes it drivable without a click and without an identity provider.

1. `safari_doctor` (expect 6/6) → `safari_new_tab` at the URL under test. **Never reuse a tab you did
   not open**, and front your tab (above).
2. Boot the **return leg** by URL — this is where every one of our bugs lives. Load
   `https://live.tips/app/#signin=<url-encoded {"v":1,"state":…,"token":…|"error":…}>`. For a real
   token, seed `flutter.pending_redirect_v1` with `safari_set_local_storage` (SharedPreferences values
   are double-encoded JSON strings under the `flutter.` prefix) and mint a custom token for a
   throwaway uid with the Admin SDK. A foreign nonce needs neither, and is safe to run against prod.
3. Assert the **record, not the pixels**: `safari_local_storage` on `flutter.pending_redirect_v1`,
   `flutter.accounts_directory_v1`, `flutter.accounts_v1`. The bug in `b9075e3` *is* a contradiction
   between two of those keys.
4. `safari_screenshot` for the spinner (it works once the tab is fronted; the image includes browser
   chrome and is scaled, so it is not a coordinate source). `safari_network` for the boot leg.
   Screenshots stay local — never committed, never uploaded.
5. `safari_close_tab`.

Verified against prod today: booting `#signin=` with a foreign nonce is parsed, the fragment is
stripped from the address bar (`main.dart:42-46`), nothing is adopted, no spinner — correct, and
proven in the engine rather than in a fake.

### The round trip: possible, and off-limits

The owner's Safari profile is signed into Google (`myaccount.google.com` opens straight into his
account, no password, no 2FA). Google's automation block is therefore not the wall here — **an agent
in this profile could complete a genuine OAuth round trip.** Do not. It mints a real Firebase session
for his real account and mutates production account state (slot commit, directory, device registry).
The real Google/Apple round trip is the owner's to run, or a throwaway test account's — never his,
uninvited.

## Verify the agent, not just the tests

Agents report confidently and are sometimes wrong. Two examples worth remembering:

- A #16 fix skipped bands with no local data on a resumed migration ("gone locally means already
  uploaded"). It does not: a band the artist named and never configured holds no local data either,
  and a crash *inside* the upload loop would have stranded it. Caught by reading a competing
  agent's objection and checking `_uploadBand` — it writes the band's `name`, so skipping loses the
  band. Fixed with a test that fails against the shipped code.
- An agent claimed it "assembled the key to dodge secret scanners" and then wrote the literal.

When a report contains a reasoned argument (especially against another agent's approach), check it
in the code before believing either of them. A regression you introduced is worse than the bug you
fixed.

## Maintaining the tracker

- An umbrella/tracking issue gets a real closing comment: what was decided (and why), what pattern
  the findings shared, what regressions were introduced and caught, and what remains open and
  honestly unproven. See the close of #24.
- Post findings as **comments on the issue** when they change the fix (the venue `_scrub` discovery
  on #31) — and message the agent working on it, so it does not learn this after finishing.
- Note ordering in the issue body when it matters. #29 (unify the two switchers) says plainly:
  land after #23/#25/#26/#28, because doing it first means writing the same rules twice again —
  which is the very thing that issue is about.
