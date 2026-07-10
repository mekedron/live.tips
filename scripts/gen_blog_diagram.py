#!/usr/bin/env python3
"""Render the localized `money-path` diagram for the tip-jar comparison post.

    python3 scripts/gen_blog_diagram.py            # every locale that has strings
    python3 scripts/gen_blog_diagram.py de fi      # just these

Writes `assets/money-path-<lang>.svg` into the post directory, one per language.
Blog assets are shared across languages by design, so a *localized* image has to
be a distinct file per language — each `<lang>.md` references its own.

Why the widths are computed instead of hard-coded: the SVG is served through an
`<img>`, which isolates it from the page's @font-face rules, so it renders in
whatever generic sans the reader's browser picks. We cannot know the true glyph
advances, so every box is sized from a deliberately *generous* estimate. A box
that is slightly too wide looks fine; one that is too narrow clips its label,
which is what a German or Finnish compound noun does to a layout tuned on
English.

Strings live in STRINGS below (English) plus `<lang>.json` files passed in via
--strings-dir, so translators can hand back a small JSON instead of editing SVG.
"""
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POST = os.path.join(ROOT, "website", "blog", "posts",
                    "tip-jars-compared-for-live-performers", "assets")

# landing CSS palette (light theme), mirrored from scripts/gen_og_image.py
BG, INK, INK2 = "#FAF6F1", "#221D18", "#70685D"
SOFT, ON_SOFT, CORAL = "#FDE7DF", "#8A2E14", "#E8542F"
CARD, LINE, LINE_SOFT = "#FFFFFF", "#E4DAD0", "#C9BDB1"
CORAL_LINE = "#F0C9BB"

EN = {
    "kicker_platform": "A CREATOR PLATFORM",
    "fan": "Your fan",
    "platform": "Platform",
    "platform_sub": "takes its cut",
    "held": "Held balance",
    "held_sub": "payout queue",
    "you": "You",
    "days_later": "days later",
    "no_middle": "no balance, no queue, no cut",
    "on_stage_now": "on stage, now",
}
KEYS = tuple(EN)

# Geometry. Everything else is derived.
PAD, GAP, BOX_H, ROW1_Y, ROW2_Y = 36, 44, 60, 66, 236
CANVAS_H = 300
LABEL_PAD = 40          # horizontal breathing room inside a box
MIN_BOX = 120
MIN_ARROW = 190         # the long row-2 arrow needs room for its caption


def width(text, size, bold=False, tracking=0.0):
    """Generous estimate of rendered text width, in px.

    0.62em per character for semibold, 0.55em for regular — comfortably above
    the ~0.5em average of the sans-serifs a browser actually reaches for.
    """
    return len(text) * (size * (0.62 if bold else 0.55) + tracking)


def esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def box(x, y, w, h, fill, stroke):
    return ('  <rect x="%d" y="%d" width="%d" height="%d" rx="12" fill="%s" '
            'stroke="%s"/>' % (x, y, w, h, fill, stroke))


def text(x, y, s, size, color, bold=False, tracking=None, anchor="middle"):
    attrs = ['x="%d"' % x, 'y="%d"' % y, 'font-size="%s"' % size,
             'fill="%s"' % color, 'text-anchor="%s"' % anchor]
    if bold:
        attrs.append('font-weight="600"')
    if tracking:
        attrs.append('letter-spacing="%s"' % tracking)
    return "  <text %s>%s</text>" % (" ".join(attrs), esc(s))


def render(t):
    """Build one SVG string from a dict of strings."""
    # Row 1 box widths, from the widest line each box has to hold.
    w_fan = max(MIN_BOX, width(t["fan"], 16, bold=True) + LABEL_PAD)
    w_plat = max(MIN_BOX, width(t["platform"], 16, bold=True) + LABEL_PAD,
                 width(t["platform_sub"], 12.5) + LABEL_PAD)
    w_held = max(MIN_BOX, width(t["held"], 16, bold=True) + LABEL_PAD,
                 width(t["held_sub"], 12.5) + LABEL_PAD,
                 width(t["days_later"], 12.5) + LABEL_PAD)
    w_you = max(MIN_BOX, width(t["you"], 16, bold=True) + LABEL_PAD)
    # Row 2's "You" box also carries the "on stage, now" caption.
    w_you2 = max(w_you, width(t["on_stage_now"], 12.5) + LABEL_PAD)

    row1 = PAD * 2 + w_fan + w_plat + w_held + w_you + GAP * 3
    # Row 2 must fit: fan box + an arrow long enough for its caption + you box.
    arrow_min = max(MIN_ARROW, width(t["no_middle"], 12.5) + 30)
    row2 = PAD * 2 + w_fan + arrow_min + w_you2
    W = int(round(max(row1, row2)))

    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
           'width="%d" height="%d" role="img" aria-labelledby="mp-title" '
           'font-family="Outfit, ui-sans-serif, system-ui, sans-serif">' % (W, CANVAS_H, W, CANVAS_H),
           "  <title id=\"mp-title\">%s</title>" % esc(t["alt"]),
           '  <rect width="%d" height="%d" rx="14" fill="%s"/>' % (W, CANVAS_H, BG)]

    # ── Row 1: fan → platform → held balance → you ──────────────────────
    xs, x = [], PAD
    for w in (w_fan, w_plat, w_held, w_you):
        xs.append((x, w))
        x += w + GAP
    # Right-align the last box with the canvas so both rows end flush.
    xs[-1] = (W - PAD - w_you, w_you)

    out.append(text(PAD, 46, t["kicker_platform"], 15, INK2, bold=True,
                    tracking=1.4, anchor="start"))
    for bx, bw in xs:
        out.append(box(bx, ROW1_Y, bw, BOX_H, CARD, LINE))

    cx = [bx + bw / 2 for bx, bw in xs]
    out.append(text(cx[0], 102, t["fan"], 16, INK, bold=True))
    out.append(text(cx[1], 94, t["platform"], 16, INK, bold=True))
    out.append(text(cx[1], 112, t["platform_sub"], 12.5, INK2))
    out.append(text(cx[2], 94, t["held"], 16, INK, bold=True))
    out.append(text(cx[2], 112, t["held_sub"], 12.5, INK2))
    out.append(text(cx[3], 102, t["you"], 16, INK, bold=True))
    out.append(text(cx[2], 146, t["days_later"], 12.5, ON_SOFT))

    out.append('  <g stroke="%s" stroke-width="1.6" fill="none" marker-end="url(#arrow)">' % LINE_SOFT)
    for i in range(3):
        a = xs[i][0] + xs[i][1] + 8
        b = xs[i + 1][0] - 8
        out.append('    <path d="M%d 96 H %d"/>' % (a, b))
    out.append("  </g>")

    # ── Row 2: fan ──────────────────────────────────► you ──────────────
    out.append(text(PAD, 216, "LIVE.TIPS", 15, ON_SOFT, bold=True,
                    tracking=1.4, anchor="start"))
    fx, yx = PAD, W - PAD - w_you2
    out.append(box(fx, ROW2_Y, w_fan, BOX_H, CARD, CORAL_LINE))
    out.append(box(yx, ROW2_Y, w_you2, BOX_H, SOFT, CORAL_LINE))
    out.append(text(fx + w_fan / 2, 272, t["fan"], 16, INK, bold=True))
    out.append(text(yx + w_you2 / 2, 264, t["you"], 16, INK, bold=True))
    out.append(text(yx + w_you2 / 2, 282, t["on_stage_now"], 12.5, ON_SOFT))

    a, b = fx + w_fan + 8, yx - 8
    out.append('  <path d="M%d 266 H %d" stroke="%s" stroke-width="2" fill="none" '
               'marker-end="url(#arrow-coral)"/>' % (a, b, CORAL))
    out.append(text((a + b) / 2, 256, t["no_middle"], 12.5, INK2))

    out.append('  <defs>')
    for mid, col in (("arrow", LINE_SOFT), ("arrow-coral", CORAL)):
        out.append('    <marker id="%s" markerWidth="9" markerHeight="9" refX="7" '
                   'refY="3.6" orient="auto"><path d="M0 0 L 7.2 3.6 L 0 7.2 z" '
                   'fill="%s"/></marker>' % (mid, col))
    out.append("  </defs>\n</svg>")
    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("langs", nargs="*", help="locale codes; default: en + every JSON found")
    ap.add_argument("--strings-dir", default=None)
    args = ap.parse_args()

    bundles = {"en": dict(EN, alt="Two ways a tip reaches a performer: through a "
                                 "platform, a held balance and a payout queue, or "
                                 "straight from the fan to the artist.")}
    if args.strings_dir and os.path.isdir(args.strings_dir):
        for fn in sorted(os.listdir(args.strings_dir)):
            if not fn.endswith(".json"):
                continue
            lang = fn[:-5]
            with open(os.path.join(args.strings_dir, fn), encoding="utf-8") as fh:
                data = json.load(fh)
            missing = [k for k in KEYS if not data.get(k)]
            if missing:
                sys.exit("%s: missing diagram strings: %s" % (fn, ", ".join(missing)))
            data.setdefault("alt", bundles["en"]["alt"])
            bundles[lang] = data

    wanted = args.langs or sorted(bundles)
    os.makedirs(POST, exist_ok=True)
    for lang in wanted:
        if lang not in bundles:
            sys.exit("no strings for %r" % lang)
        out = os.path.join(POST, "money-path-%s.svg" % lang)
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(render(bundles[lang]))
        print("wrote %s" % os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main()
