---
name: livetips-issues
description: File, triage and close issues in the live.tips tracker, and drive them to production through worktree subagents. Use whenever the user reports a bug from the device, asks to "create an issue", asks to fix open issues, or when an audit/review turns up findings. Covers the house style for an issue, the traps this codebase actually has, and the merge→deploy→verify loop.
---

# Issues in live.tips

The tracker is small, hand-maintained, and read by people who will act on it. An issue here is
not a ticket — it is an argument that something is broken, with enough evidence that the reader
can check it without you. Write it so a stranger could fix the bug from the issue alone.

## Before you file anything: verify in the code

**The reporter's framing is a hypothesis, not a finding.** It is often inverted, and filing it
verbatim is how a tracker fills with fiction. Every claim in an issue must be something you read
in the code, not something you were told.

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
   `cd firebase/functions && npm test` (~210), plus `flutter analyze` / `npm run check`. Two
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
   commit or upload them.
8. **Close with the truth.** `Fixes #N` in the commit body closes it on merge. When you cannot
   confirm a root cause, say so in the issue rather than implying a fix (#30: the symptom is closed
   by the one mechanism that produces it exactly, and the swallowed exception that hid it is gone —
   that is what was written, because that is what was known).

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
