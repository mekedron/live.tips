---
title: Contactless tipping for street performers, honestly
description: Tap-to-pay on a phone, a card reader, an NFC sticker, a QR code — four different things that get called "contactless". What each one actually costs in 2026, what an NFC tag really does (it is not what you think), and when a tap beats a scan.
---

Search for contactless tipping for street performers and the internet hands you
2018. A student prototype from Brunel University called Tiptap — a stand you slot
a phone into — got a round of press that year, and that press is still sitting on
page one. It was a nice idea. It was also, in the words of the coverage itself,
*still in the development stage*, and it planned to charge buskers a one-off fee
plus **5% of every tip**. It never became something you can buy.

(The "tiptap" you will find if you go looking now is an unrelated Ontario company
selling contactless donation terminals to charities. Same word, different product,
not for you.)

So the honest state of the art has gone eight years without being written down.
Here it is.

This is the deep dive on tap. If the question you actually have is the broader one —
every way a busker can get paid now that nobody carries cash, and what each one
costs — start with [how buskers take card
payments](post:how-buskers-take-card-payments) and come back here.

## Four different things are all called "contactless"

This is where most of the confusion lives, so let us separate them before we
price anything.

1. **Tap to Pay on your own phone.** Your phone becomes the terminal. The fan taps
   their card or their watch against *your* handset. No extra hardware at all.
2. **A card reader** — a SumUp, a Zettle, a Square. A little plastic terminal you
   hold out. The fan taps it.
3. **An NFC tag** — the "tap here to tip" sticker or plaque. This one is almost
   universally misunderstood, and the next section is about why.
4. **A QR code.** Not contactless in the NFC sense — but read on, because from the
   fan's side it very often ends in exactly the same tap.

Only the first two are *payment terminals*. That distinction is the whole post.

## The NFC tag does not take a payment

Let us kill this one properly, because vendors are happy to let you believe
otherwise.

An NFC sticker — the cheap kind, the NTAG213 chip most of them use — has **144
bytes of memory**. Not 144 kilobytes. It cannot run code, it has no battery, it
has never heard of a card scheme, and it could not hold a payment protocol if it
wanted to. What it holds is a short string, formatted as an NDEF record, and
overwhelmingly that string is a **URL**.

Tap it, and your phone opens a web page. That is the entire feature.

Which means a "tap to tip" plaque is a QR code that you open by touching instead
of aiming. Same destination, same web page, same payment happening in the browser.
Even the specialists say so when you read them closely: tiptap's own site
describes its custom-amount device as one where *"when donors hold their phone up
to a custom donation device, they will be directed to your online fundraising
page."* Directed to a page. Because that is what a tag can do.

This is genuinely useful, and it is also cheap — blank NTAG213 stickers start
around **$0.24 each** in packs. If you already have a tip page, sticking a tag on
your case next to the printed code costs you pocket change and gives some fans a
faster way in.

But be clear about what you have bought: **a second front door to the same page.**
Not a card machine.

### And outdoors, it is a fussy front door

The failure modes are real, and nobody selling tags lists them:

- **The fan's phone must be unlocked and in use.** Apple's own documentation is
  explicit: background tag reading only happens while the iPhone is in use, and if
  the phone is locked the system makes them unlock it first.
- **It does not work while the camera is open.** Apple lists the camera being in
  use as one of the states where background tag reading is unavailable. Savour the
  irony: a fan reaching for the camera to scan your QR code has just disabled your
  NFC tag.
- **It needs an iPhone XS or later**, and on Android it needs NFC switched on —
  which some power-saving modes switch off.
- **Range is about 4 cm.** The fan has to actually touch the thing. In a crowd,
  bending down to a guitar case, that is a real ask.
- **Metal and magnets kill it.** A tag taped to an amp, or a fan with a
  magnetic wallet case, and nothing happens at all.

A tag is a nice second option. It is a bad only option.

## Tap to Pay on your phone: the actual 2026 news

Here is the thing that has changed since the Tiptap articles, and that none of the
stale coverage knows about.

**Tap to Pay on iPhone** turns the phone already in your pocket into a contactless
terminal. No dongle, no reader, no stand. Apple lists it as available in **70+
countries and regions**, and the providers you can use it through in Europe read
like the whole industry — in Germany alone: Adyen, Mollie, myPOS, Nexi, PAYONE,
Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. The UK, France, the
Netherlands, Sweden, Finland and Denmark all have similar lists. You need an
iPhone XS or later.

**Tap to Pay on Android** exists too but is narrower. Through Stripe, it is
generally available in AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ,
PL, SE, SG and US, with a further eighteen countries in public preview. Your phone
needs Android 13 or later, an NFC sensor, an unrooted bootloader, Google Mobile
Services, and Developer options switched off — that last one catches more people
than you would think.

The practical version: **SumUp lists Tap to Pay at £0 of hardware.** If you have a
recent iPhone and you are in a supported country, the entry cost of holding out a
contactless terminal is now zero. That fact alone makes every "buy this stand"
article from 2018 obsolete.

## Card readers, and what they really cost

If you want a separate bit of plastic — and there are good reasons to, below — the
market is three products.

| | Hardware | Fee per in-person tap |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay £0 · Solo Lite £25 · Solo £79 · Terminal £135 | **1.69%**, no fixed fee |
| **SumUp** (Germany) | — | **1.39%**, no fixed fee |
| **Zettle / PayPal POS** (UK) | Reader from £29 for a first-time user, £69 after | **1.75%**, no fixed fee |
| **Square** (UK) | Contactless + chip reader £19 | **1.75%**, no fixed fee |
| **Square** (US) | Contactless + chip reader $59 | **2.6% + $0.15** |

Prices exclude VAT and are as published in July 2026. Go and check them; they move.

Now read that table again, because it says something that contradicts what you
have probably been told.

## The fee maths, and the thing everyone gets backwards

The received wisdom is that card fees destroy small tips because of the fixed
per-transaction charge — the twenty-five cents that eats an eighth of a €2 tip.
That is true, and we have [written the maths out ourselves](post:build-a-tip-jar-on-your-own-stripe).

But it is true of *online* card payments. **European contactless readers mostly do
not have a fixed fee at all.** SumUp, Zettle and Square in the UK and EU are
percentage-only. Which means:

| A €2 tip | Fee | Artist keeps | Effective cut |
| --- | --- | --- | --- |
| SumUp reader (DE, 1.39%) | €0.03 | €1.97 | **1.4%** |
| Zettle / Square (UK, 1.75%) | €0.04 | €1.96 | 1.8% |
| Stripe, online card (EEA, 1.5% + €0.25) | €0.28 | €1.72 | **14.0%** |
| Square reader (US, 2.6% + $0.15) | $0.20 | $1.80 | **10.1%** |

On the fee alone, a European tap terminal beats an online card payment on a small
tip, and it is not close. We are a QR-code product and we are telling you this: on
a €2 tip, a SumUp reader keeps you €0.25 that a Stripe-hosted page does not.

Two things put that back in proportion.

**The hardware is the fixed fee, moved.** A €0.25 saving per tip against a £79
Solo means roughly **three hundred taps before the reader has paid for itself**.
That is a real number for a working busker and a silly one for someone who plays
twice a summer. (And SumUp's £0 Tap to Pay makes it zero taps — which is exactly
why that option matters more than the readers do.)

**And the US flips it back.** Square's American in-person rate carries a $0.15
fixed fee, so a $2 tap loses a tenth of itself at the terminal too. The
no-fixed-fee gift is a European one.

There is also a floor you will meet: SumUp will not take a payment under **£1 /
€1**. Whatever rail you pick, the very small tip is not really a card transaction.

## So when does a tap beat a scan?

Strip away the technology and this is a question about the fan's hands.

**A tap needs the fan's phone unlocked and in their hand, and needs you to be
holding something out.** When both are true it is the fastest thing in payments.
No app, no aiming, no typing, done in a second.

**A scan needs the fan to open a camera** — one extra deliberate act — but it needs
nothing of you at all. The code sits on the case. It works on a fan standing at
the back. It works on forty people at once. It works while you are still playing.

Which gives an honest division:

- **Tap wins when you can walk up to people.** End of the set, hat round, one fan
  at a time, you free to hold a terminal. A tap is a lower-friction ask than "get
  your camera out", and in that moment you are physically present to close it.
- **Scan wins when you cannot.** Mid-song. A crowd three deep. A pitch where you
  cannot leave the amp. Anyone who wants to give as they walk past. A terminal can
  serve exactly one person; a printed code serves the whole square, simultaneously,
  and does not need you to stop playing to serve it.

That last point is the one the terminal vendors never make, and it is the biggest
one. **A card reader is a bottleneck with a queue.** A QR code has no queue.

And here is the part that dissolves half the argument: on a well-built tip page,
**the scan ends in a tap anyway**. The fan scans, the page opens, and their phone
offers Apple Pay or Google Pay. They double-click, they hold the phone to their
face, it is done. From the fan's side that is a contactless payment — same wallet,
same card, same two seconds — and you bought no hardware to make it happen.

## Where live.tips sits, and when to buy a SumUp instead

[live.tips](https://github.com/mekedron/live.tips) is a QR-based tip jar. One code,
which never changes, pointing straight at the artist's own Stripe payment link.
There is no live.tips balance, no cut, and no platform in the path — the fee is
Stripe's own and Stripe charges it to the artist directly. It is MIT-licensed, and
the tablet on stage shows each tip as it lands. We wrote up the money path in
[how live.tips handles money](post:how-live-tips-handles-money), and why it is
[one code rather than one per provider](post:one-qr-code-every-payment-method).

That page supports Apple Pay and Google Pay. So live.tips *is* contactless from
the fan's side — the tap that matters, the one at the end, with no terminal to buy,
charge, or drop in the rain. It is just not a terminal.

**If what you want is to physically hold something out and have a stranger tap it,
buy a card reader.** Get SumUp's Tap to Pay if your phone and country support it,
because it costs nothing; get a Solo if you would rather not hand your own phone to
a crowd. Either way, on a €2 tap in Europe it will beat our fee, and we would
rather say so than pretend otherwise.

You can also do both, and plenty of buskers should: the code taped to the case all
night, catching the passers-by while you play, and the terminal in your hand for
the ten seconds after the last chord when the front row is reaching for their
pockets. They are not competing. They are catching different people.

What none of them are is a 2018 stand that takes 5%.

Fees, hardware prices and country availability as published by Apple, Stripe, SumUp, Zettle/PayPal and Square in July 2026, excluding VAT. NFC sticker pricing from GoToTags. Tiptap's 2018 terms as reported by Brunel University and Finextra. Everything here changes; check it against the vendor before you spend money.
{: .footnote }
