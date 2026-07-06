#!/usr/bin/env python3
"""Render the social-share banner (website/og-image.png, 1200x630).

This is the picture chat apps and social feeds show when someone shares a
live.tips link (Open Graph / Twitter Card). It mirrors the landing hero:
cream canvas, coral accent, the volunteer_activism brand glyph and Outfit
type — brand colour and glyph are imported from gen_icons.py so a rebrand
there carries over here.

Rerun after a rebrand or copy change:  python3 scripts/gen_og_image.py
Requirements: Pillow (+ an SVG rasterizer for gen_icons, see its docstring).
The Outfit TTF is fetched from the google/fonts repo on every run.
"""
import os
import tempfile
import urllib.request

from PIL import Image, ImageDraw, ImageFont

import gen_icons
from gen_icons import CORAL, GLYPH, R_FAVICON

# landing CSS palette (light theme)
BG = "#FAF6F1"
INK = "#221D18"
INK2 = "#70685D"
SOFT = "#FDE7DF"
ON_SOFT = "#8A2E14"

W, H = 1200, 630
SS = 2                       # supersample factor; drawn at 2x, downscaled once
OUT = os.path.join(gen_icons.ROOT, "website", "og-image.png")
OUTFIT_URL = ("https://raw.githubusercontent.com/google/fonts/main/"
              "ofl/outfit/Outfit%5Bwght%5D.ttf")


def outfit(path, size, weight):
    f = ImageFont.truetype(path, size * SS)
    f.set_variation_by_axes([weight])
    return f


def tinted_glyph(height, color):
    """Brand glyph sprite scaled to `height` px and tinted `color`."""
    g = GLYPH.resize((round(GLYPH.width * height / GLYPH.height), height),
                     Image.LANCZOS)
    tint = Image.new("RGBA", g.size, color)
    tint.putalpha(g.getchannel("A"))
    return tint


def main():
    with tempfile.TemporaryDirectory() as tmp:
        ttf = os.path.join(tmp, "Outfit.ttf")
        with urllib.request.urlopen(OUTFIT_URL) as r, open(ttf, "wb") as fh:
            fh.write(r.read())

        f_word = outfit(ttf, 42, 700)      # logo wordmark
        f_pill = outfit(ttf, 22, 600)      # top-right badge
        f_head = outfit(ttf, 96, 800)      # headline
        f_sub = outfit(ttf, 31, 500)       # subline

        img = Image.new("RGB", (W * SS, H * SS), BG)
        draw = ImageDraw.Draw(img)

        def text(xy, s, font, fill):
            draw.text((xy[0] * SS, xy[1] * SS), s, font=font, fill=fill)
            return font.getlength(s) / SS

        # soft watermark: big tilted glyph, mostly in frame so the giving-hand
        # mark stays recognizable, bleeding a little off the right edge
        wm = tinted_glyph(430 * SS, SOFT).rotate(-8, Image.BICUBIC, expand=True)
        img.paste(wm, (795 * SS, 165 * SS), wm)

        # logo: coral tile + white glyph + wordmark (same geometry as favicon)
        tile, margin = 68, 80
        t = Image.new("RGBA", (tile * SS, tile * SS), (0, 0, 0, 0))
        ImageDraw.Draw(t).rounded_rectangle(
            [0, 0, tile * SS - 1, tile * SS - 1],
            radius=R_FAVICON * tile * SS, fill=CORAL)
        g = tinted_glyph(round(tile * gen_icons.GLYPH_STD * SS), "#FFFFFF")
        t.paste(g, ((t.width - g.width) // 2, (t.height - g.height) // 2), g)
        img.paste(t, (margin * SS, 64 * SS), t)
        draw.text((margin * SS + tile * SS + 20 * SS, (64 + tile / 2) * SS),
                  "live.tips", font=f_word, fill=INK, anchor="lm")

        # top-right pill: "Open source · MIT"
        pill_txt = "Open source · MIT"
        pw = f_pill.getlength(pill_txt) / SS
        px1, py0, pad_x, ph = W - margin, 78, 22, 40
        px0 = px1 - pw - 2 * pad_x
        draw.rounded_rectangle(
            [px0 * SS, py0 * SS, px1 * SS, (py0 + ph) * SS],
            radius=ph * SS / 2, fill=SOFT)
        draw.text(((px0 + pad_x) * SS, (py0 + ph / 2) * SS), pill_txt,
                  font=f_pill, fill=ON_SOFT, anchor="lm")

        # headline — two lines, accent on the promise
        y1, y2 = 226, 336
        text((margin, y1), "Your live tip jar.", f_head, INK)
        w = text((margin, y2), "On stage ", f_head, INK)
        text((margin + w, y2), "in minutes.", f_head, CORAL)

        # subline — two lines
        text((margin, 492), "One QR code on stage — fans scan, tip, leave a message.", f_sub, INK2)
        text((margin, 538), "Straight into your own Stripe. No platform, no cut.", f_sub, INK2)

        img.resize((W, H), Image.LANCZOS).save(OUT, optimize=True)
        print(f"wrote website/og-image.png ({os.path.getsize(OUT) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
