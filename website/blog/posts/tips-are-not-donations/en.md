---
title: Tips are not donations — and Stripe treats them as two different businesses
description: A busker asking for a "donation button" is describing a business that Stripe prohibits in most of Europe. A tip pays for a service you already performed; a donation is charitable fundraising. The difference decides which category your account lands in — and one API parameter can pick the wrong one for you.
---

Every tool on the internet wants you to call it a donation. The buttons say
*Donate*. The blog posts say *donation button for musicians*. The plugin
directories say *accept donations*. If you are a musician looking for a way to be
paid by people who have no cash, the word follows you everywhere.

Then you open a Stripe account, and Stripe asks what your business does. And at
that moment the word stops being marketing copy and becomes a **business
category** — one that, in most of Europe, Stripe does not allow.

This is not pedantry, and it is not a lawyer's distinction. It is the single
question most likely to get a perfectly ordinary busker's payment account
reviewed, delayed, or refused. Almost nobody has written it down plainly for
performers, so here it is.

## Two words, two businesses

Stripe draws the line itself, in one sentence each. From
[Requirements for accepting tips or donations](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> a tip must be given for a good or service that has been provided (e.g., content)

> a donation must be tied to a specific charitable purpose that you're committing
> to accomplish

Read those twice, because everything else in this post falls out of them.

A **tip** looks backwards at something that already happened. The service was
delivered, the fan liked it, the fan paid extra. The money is unconditional and
you owe nothing further. This is the tip line on a restaurant bill, the coins in
the hat, the fiver pressed into a hand after the last song.

A **donation** looks forwards at something you have promised to do. There is a
cause. There is a purpose you have described to the person giving. And — Stripe
is explicit about this — the money must actually go to that purpose. You are
holding it in trust for a thing you said you would accomplish.

Those are not two shades of the same act. They are two different relationships,
with two different sets of obligations, and Stripe underwrites them as two
different businesses.

## A busker is squarely, unambiguously on the tip side

You stood in a square for two hours and played. Forty people stopped. One of them
scans your code and sends you five euros.

**That is a tip.** The performance is the service. It was provided — they watched
it happen. There is no cause, no beneficiary, no purpose you have committed to
accomplish, and nobody has entrusted you with money for a project. You are a
performing artist being paid for a performance, which is one of the oldest and
least controversial commercial arrangements there is.

The confusion comes from the fact that a busker's tip is *voluntary*, and we have
been trained to think voluntary money is charitable money. It is not. A tip is
voluntary too. Voluntariness is not what makes something a donation — a
**charitable purpose** is.

So when your sign says "donations welcome", you are not being modest or polite.
You are describing, in the payment processor's vocabulary, a business you are not
in.

## What the word actually costs you

Here is where the abstraction becomes money.

Stripe publishes a
[restricted businesses list](https://stripe.com/legal/restricted-businesses) —
the things you may not do with a Stripe account, or may only do in some countries.
Under the heading **Crowdfunding and fundraising** sits this line, verbatim:

> Organisations fundraising for a charitable purpose (Note: Supported in
> Australia, Canada, the United Kingdom and the United States. Prohibited in all
> other countries.)

Read the parenthesis slowly. Charitable fundraising is a **supported business in
four countries** — Australia, Canada, the UK, the US — and **prohibited
everywhere else.**

Everywhere else includes Germany, France, Spain, Italy, the Netherlands, Poland,
Finland, and every other country where a busker might reasonably be standing.
Most of the world's street performers live in "all other countries".

The same page also lists *"Fundraising conducted by non-profits, charities,
political organisations and businesses offering a reward in return for donation"*
as restricted, and Stripe's tips-and-donations page adds a set of
country-specific rules on top: in Japan individuals cannot receive donations at
all; in Singapore only government-registered charitable or religious
organisations may; in India, Hong Kong and Thailand donations are unsupported.

So a musician in Berlin who types "donations for my music" into the Stripe
onboarding form has just described a business Stripe prohibits in Germany. Not
because busking is banned — busking is completely fine — but because the words
they chose belong to a category that is.

## Now the calibration, because this is not a horror story

**Buskers are not a restricted business.** Tipping is not a restricted business.
Live performance is not on the list, will not put you on the list, and is about as
ordinary a thing as you can do with a payment account. If you describe yourself
accurately, none of this touches you and the setup is boring, which is exactly
how it should be.

The risk here is not Stripe. The risk is **self-misclassification** — walking into
the room and announcing yourself as a charitable fundraiser when you are a
guitarist. Stripe has no way to know you meant "please tip me". It only has the
form you filled in, the business description you wrote, and the words on the page
your QR code points at.

Nobody at Stripe is hunting for buskers. They are simply reading what you told
them.

## The trap is one parameter deep

Here is the part almost nobody writes down, and it is the most useful thing in
this post.

Stripe's Payment Links have a parameter called `submit_type`. The
[API reference](https://docs.stripe.com/api/payment-link/object) describes it as
something almost cosmetic:

> Indicates the type of transaction being performed which customizes relevant text
> on the page, such as the submit button.

*Customizes relevant text.* You would reasonably conclude that this changes a
button label, and that a tip jar should obviously say *Donate* rather than *Buy*,
because *Buy* is a strange word to print under a busker's hat.

Then you read what the individual values actually do:

> `donate` — Recommended when accepting donations. Submit button includes a
> 'Donate' label and URLs use the `donate.stripe.com` hostname

> `pay` — Submit button includes a 'Buy' label and URLs use the `buy.stripe.com`
> hostname

**It is not a label. It is a hostname.** Set `submit_type=donate` and the link
Stripe hands you — the one you turn into the QR code, print, and tape to your
guitar case — lives at `donate.stripe.com`. Every fan who scans it sees a donation
page. Every payment in your dashboard came through a donation flow. The QR code
on your case is telling Stripe, telling your audience, and eventually telling you
that you are collecting donations.

You never wrote the word "donation" anywhere. One API parameter wrote it for you,
and printed it on a plastic sign in a public square.

This is an easy trap to walk into, and it is not the reader's fault when they do:
the parameter is documented as a text change, *Donate* is plainly the nicer word
to print under a busker's hat, and the consequence — a business classification —
is two sentences further down the page than most people read.

live.tips sends `submit_type=pay`. Every artist's link is a `buy.stripe.com` link,
and the code carries a comment saying why, because it is the kind of thing a future
contributor would otherwise "improve".

## What a musician should actually do

None of this requires a lawyer. It requires five minutes and some plain words.

- **Describe the real business** in Stripe's onboarding. "Live music
  performance." "Street performer." "Musician — tips and gratuities from
  audiences at live performances." Say that you perform, and that the payments
  are tips for those performances.
- **Pick a category that matches.** Live entertainment, performing arts,
  musician. Not charity, not non-profit, not fundraising.
- **Use `submit_type=pay`** if you build the Payment Link yourself. If a tool
  built it for you, look at the URL it produced: `buy.stripe.com` is a tip jar,
  `donate.stripe.com` is a donation page. That is a two-second check, and it tells
  you what your tool believes you are.
- **Do not call it a donation** — not on the sign, not on your website, not in the
  Stripe business description. "Tips", "tip jar", "support the band", "buy us a
  drink" all describe what is happening. "Donate" describes something else.
- **Keep a real fundraiser separate.** If you play a benefit gig and the money
  goes to a cause, that genuinely *is* charitable fundraising, and the rules above
  are now about you — including the country list. Do it under the right account,
  in the right country, having read Stripe's terms, and never through the tip jar
  you use on normal nights.

That last one deserves emphasis, because it is the honest half of the argument.
We are not saying donations are bad or that musicians can never raise money for a
cause. We are saying it is a **different activity**, with different rules, and
that quietly running it through the same QR code is how both get you in trouble.

One more line from Stripe's tips-and-donations page is worth knowing, since it
rules out a third thing people confuse with both: Stripe does not do *"payment
processing for personal or peer-to-peer money transmission (e.g., sending money
between friends)"*. A tip is not a gift between friends either. If you want that
rail — a fan simply sending you money, person to person — that is what Revolut or
MobilePay are, and it is why those live
[entirely outside Stripe](post:one-qr-code-every-payment-method) in our app.

## What this post is not

It is not legal advice. It is not tax advice — how tips are taxed varies enormously
by country, sometimes by city, and it is completely out of scope here; ask someone
qualified where you live.

And it is not a promise about your account. **Whether Stripe approves you is
Stripe's decision alone.** live.tips has no relationship with Stripe, no ability to
influence a review, and no way to appeal one on your behalf. What our software can
do is avoid putting words in your mouth. What you write on the form is still yours
to write.

Policies also change. The lines quoted here were on Stripe's pages in July 2026,
and the links are right there; go and read them yourself rather than trusting a
blog post, including this one.

## The short version

You played the set. They watched it. They paid you for it.

That is a tip. Say so — on the sign, in the form, in the URL — and the boring
outcome you want is the one you get. We build the tip jar around exactly that
claim, all the way down to
[which Stripe hostname your QR code points at](post:build-a-tip-jar-on-your-own-stripe),
and if you want the wider picture of where the money actually goes, that is
[here](post:how-live-tips-handles-money).
