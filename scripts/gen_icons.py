#!/usr/bin/env python3
"""Regenerate the entire live.tips icon set from one brand definition.

The brand mark is the white Material Symbols ``volunteer_activism`` glyph
(filled, rounded) on coral ``#E8542F`` — identical to the landing-page header
logo-mark. This script is the single source of truth for every site/app icon.

To rebrand, edit the constants below and rerun ``python3 scripts/gen_icons.py``:
  * CORAL          — the background / brand colour
  * GLYPH_D        — the SVG path ``d`` of the mark (any single-path glyph;
                     e.g. export a Material Symbol at fill 1)
  * GLYPH_VIEWBOX  — its viewBox (Material Symbols use "0 -960 960 960")

Everything it writes (paths relative to the repo root):
  website/index.html ............................. inline SVG favicon (landing)
  website/favicon.png ............................ landing PNG favicon (search engines)
  website/apple-touch-icon.png ................... landing iOS bookmark icon
  app/web/favicon.png + app/web/icons/*.png ...... Flutter web favicon + PWA icons
  app/ios/.../AppIcon.appiconset/*.png ........... iOS app icon (opaque, all sizes)
  app/macos/.../AppIcon.appiconset/*.png ......... macOS app icon (padded squircle)
  app/android/.../res/mipmap-*/ic_launcher.png ... Android legacy launcher icon
  app/android/.../res/mipmap-*/ic_launcher_foreground.png . adaptive foreground
  app/android/.../res/mipmap-anydpi-v26/ic_launcher.xml ... adaptive icon
  app/android/.../res/values/colors.xml .......... adaptive background colour

Requirements (macOS host):
  * Pillow                            (pip install Pillow)
  * qlmanage  — built into macOS; used only to rasterize the glyph vector.
                Falls back to `rsvg-convert`, `cairosvg`, or the cairosvg
                Python module if present.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageOps

# --- brand definition ------------------------------------------------------
CORAL = "#E8542F"                       # accent colour (landing --accent)
GLYPH_VIEWBOX = "0 -960 960 960"        # Material Symbols coordinate system
# Material Symbols Rounded · volunteer_activism · fill 1
GLYPH_D = (
    "M549-53q8 2 17 2t17-2l297-91q0-54-30.5-80.5T762-251H587q-45 0-69.5-4.5T477-265"
    "l-61-21q-6-2-8.5-7.5T407-305q2-6 7.5-8.5t11.5-.5l59 19q24 8 44 11t46 3h73q8 0 "
    "13-5t5-13q0-23-16-45.5T604-378l-245-92q-5-2-10.5-3t-10.5-1h-83v337l294 84ZM40-140"
    "q0 25 17.5 42.5T100-80h34q25 0 42.5-17.5T194-140v-274q0-25-17.5-42.5T134-474h-34"
    "q-25 0-42.5 17.5T40-414v274Zm606-340q-11 0-22-4.5T604-497L482-616q-30-29-50-64.5"
    "T412-758q0-51 35.5-86.5T534-880q34 0 62 17.5t50 43.5q22-26 50-43.5t62-17.5q51 0 "
    "86.5 35.5T880-758q0 42-20 77.5T810-616L688-497q-9 8-20 12.5t-22 4.5Z"
)

# glyph size as a fraction of the tile (longest side), per icon role
GLYPH_STD = 0.60      # full-bleed square / rounded tiles
GLYPH_MASKABLE = 0.52  # web maskable — must survive a circular crop
GLYPH_ADAPTIVE = 0.46  # android adaptive foreground — inside the 66dp safe zone
# corner radius as a fraction of the tile
R_FAVICON = 0.28      # landing + web favicon (echoes the header logo-mark)
R_APP = 0.23          # android legacy launcher fallback
# macOS padded-squircle geometry (Apple icon grid ≈ 824/1024 body, r ≈ 0.225)
MAC_PAD = 0.098
MAC_RADIUS = 0.225

WORK = 2048           # supersample canvas; downscaled to each target with LANCZOS
CORAL_RGBA = tuple(int(CORAL[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IOS = "app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
MAC = "app/macos/Runner/Assets.xcassets/AppIcon.appiconset"
WEB = "app/web"
RES = "app/android/app/src/main/res"


# --- rasterize the glyph to a tight white sprite ---------------------------
def _bw_svg():
    """Black glyph on an opaque white tile (QuickLook flattens alpha to white,
    so we recover the shape from luminance rather than from transparency)."""
    x0, y0, w, h = GLYPH_VIEWBOX.split()
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{GLYPH_VIEWBOX}" '
        f'width="{w}" height="{h}">'
        f'<rect x="{x0}" y="{y0}" width="{w}" height="{h}" fill="#fff"/>'
        f'<path d="{GLYPH_D}" fill="#000"/></svg>'
    )


def _white_svg():
    """White glyph on transparent — for real SVG rasterizers (rsvg/cairosvg)."""
    _, _, w, h = GLYPH_VIEWBOX.split()
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{GLYPH_VIEWBOX}" '
        f'width="{w}" height="{h}"><path d="{GLYPH_D}" fill="#fff"/></svg>'
    )


def load_glyph(size=WORK):
    """Return a tight, pure-white RGBA sprite of the glyph at ~`size` px."""
    with tempfile.TemporaryDirectory() as tmp:
        if shutil.which("qlmanage"):
            svg = os.path.join(tmp, "g.svg")
            with open(svg, "w") as fh:
                fh.write(_bw_svg())
            subprocess.run(["qlmanage", "-t", "-s", str(size), "-o", tmp, svg],
                           check=True, capture_output=True)
            gray = Image.open(svg + ".png").convert("L")
            alpha = ImageOps.invert(gray)
        elif shutil.which("rsvg-convert"):
            svg = os.path.join(tmp, "g.svg")
            out = os.path.join(tmp, "g.png")
            with open(svg, "w") as fh:
                fh.write(_white_svg())
            subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size),
                            svg, "-o", out], check=True, capture_output=True)
            alpha = Image.open(out).convert("RGBA").split()[3]
        else:
            try:
                import cairosvg
            except ImportError:
                sys.exit("No SVG rasterizer found (need qlmanage, rsvg-convert, "
                         "or the cairosvg Python module).")
            out = os.path.join(tmp, "g.png")
            cairosvg.svg2png(bytestring=_white_svg().encode(), write_to=out,
                             output_width=size, output_height=size)
            alpha = Image.open(out).convert("RGBA").split()[3]

    bb = alpha.getbbox()                    # glyph bounds in render pixels
    vx0, vy0, vw, vh = (float(v) for v in GLYPH_VIEWBOX.split())
    native = (vx0 + bb[0] / size * vw, vy0 + bb[1] / size * vh,
              vx0 + bb[2] / size * vw, vy0 + bb[3] / size * vh)
    alpha = alpha.crop(bb)
    w = Image.new("L", alpha.size, 255)
    sprite = Image.merge("RGBA", (w, w, w, alpha))
    return sprite, native


GLYPH, GLYPH_NATIVE = load_glyph()          # tight sprite + native (viewBox) bbox
GW, GH = GLYPH.size


# --- compositing -----------------------------------------------------------
def _rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    if radius <= 0:
        d.rectangle([0, 0, size - 1, size - 1], fill=255)
    else:
        d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def _paste_glyph(canvas, frac, ref):
    scale = frac * ref / max(GW, GH)
    w, h = max(1, round(GW * scale)), max(1, round(GH * scale))
    g = GLYPH.resize((w, h), Image.LANCZOS)
    cx, cy = canvas.size[0] // 2, canvas.size[1] // 2
    canvas.alpha_composite(g, (cx - w // 2, cy - h // 2))


def make(size, kind):
    img = Image.new("RGBA", (WORK, WORK), (0, 0, 0, 0))

    if kind in ("fav_rounded", "app_rounded", "square", "ios", "maskable"):
        radius = {"fav_rounded": R_FAVICON, "app_rounded": R_APP,
                  "square": 0.0, "ios": 0.0, "maskable": 0.0}[kind] * WORK
        gfrac = GLYPH_MASKABLE if kind == "maskable" else GLYPH_STD
        body = Image.new("RGBA", (WORK, WORK), CORAL_RGBA)
        img = Image.composite(body, img, _rounded_mask(WORK, radius))
        _paste_glyph(img, gfrac, WORK)
    elif kind == "macos":
        pad = round(MAC_PAD * WORK)
        bsize = WORK - 2 * pad
        body = Image.composite(Image.new("RGBA", (bsize, bsize), CORAL_RGBA),
                               Image.new("RGBA", (bsize, bsize), (0, 0, 0, 0)),
                               _rounded_mask(bsize, round(MAC_RADIUS * bsize)))
        img.alpha_composite(body, (pad, pad))
        _paste_glyph(img, GLYPH_STD, bsize)
    elif kind == "adaptive_fg":
        _paste_glyph(img, GLYPH_ADAPTIVE, WORK)
    else:
        raise ValueError(kind)

    out = img.resize((size, size), Image.LANCZOS)
    if kind == "ios":
        out = out.convert("RGB")   # App Store icons must have no alpha channel
    return out


def write_png(rel, size, kind):
    dst = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    make(size, kind).save(dst, optimize=True)


# --- output manifest -------------------------------------------------------
def png_targets():
    t = []
    for fn, sz in [
        ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40), ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29), ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80), ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120), ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76), ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167), ("Icon-App-1024x1024@1x.png", 1024),
    ]:
        t.append((f"{IOS}/{fn}", sz, "ios"))
    for sz in (16, 32, 64, 128, 256, 512, 1024):
        t.append((f"{MAC}/app_icon_{sz}.png", sz, "macos"))
    t.append(("website/favicon.png", 96, "fav_rounded"))
    t.append(("website/apple-touch-icon.png", 180, "square"))
    t.append((f"{WEB}/favicon.png", 64, "fav_rounded"))
    t.append((f"{WEB}/icons/Icon-192.png", 192, "square"))
    t.append((f"{WEB}/icons/Icon-512.png", 512, "square"))
    t.append((f"{WEB}/icons/Icon-maskable-192.png", 192, "maskable"))
    t.append((f"{WEB}/icons/Icon-maskable-512.png", 512, "maskable"))
    for d, sz in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
        t.append((f"{RES}/mipmap-{d}/ic_launcher.png", sz, "app_rounded"))
    for d, sz in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)]:
        t.append((f"{RES}/mipmap-{d}/ic_launcher_foreground.png", sz, "adaptive_fg"))
    return t


# --- android adaptive config -----------------------------------------------
def write_android_config():
    colors = os.path.join(ROOT, RES, "values", "colors.xml")
    os.makedirs(os.path.dirname(colors), exist_ok=True)
    with open(colors, "w") as fh:
        fh.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                 f'    <color name="ic_launcher_background">{CORAL}</color>\n'
                 '</resources>\n')
    xmld = os.path.join(ROOT, RES, "mipmap-anydpi-v26")
    os.makedirs(xmld, exist_ok=True)
    with open(os.path.join(xmld, "ic_launcher.xml"), "w") as fh:
        fh.write('<?xml version="1.0" encoding="utf-8"?>\n'
                 '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                 '    <background android:drawable="@color/ic_launcher_background" />\n'
                 '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
                 '    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />\n'
                 '</adaptive-icon>\n')


# --- landing-page inline SVG favicon ---------------------------------------
def landing_favicon_datauri():
    """Vector favicon (rounded coral tile + white glyph), sized/centred from the
    measured glyph bounds so it stays correct if the glyph is swapped."""
    x0, y0, vw, vh = (float(v) for v in GLYPH_VIEWBOX.split())
    nl, nt, nr, nb = GLYPH_NATIVE           # glyph bbox in viewBox units
    s = round(GLYPH_STD * vw / max(nr - nl, nb - nt), 4)
    tx = round(x0 + vw / 2 - s * (nl + nr) / 2, 2)   # scaled glyph centre -> tile centre
    ty = round(y0 + vh / 2 - s * (nt + nb) / 2, 2)
    r = round(R_FAVICON * vw)
    svg = (
        f"<svg xmlns='http://www.w3.org/2000/svg' viewBox='{GLYPH_VIEWBOX}'>"
        f"<rect x='{x0:g}' y='{y0:g}' width='{vw:g}' height='{vh:g}' rx='{r}' "
        f"fill='{CORAL.replace('#', '%23')}'/>"
        f"<g transform='translate({tx},{ty}) scale({s})' fill='%23fff'>"
        f"<path d='{GLYPH_D}'/></g></svg>"
    )
    return "data:image/svg+xml," + svg


def write_landing_favicon():
    path = os.path.join(ROOT, "website", "index.html")
    html = open(path).read()
    line = f'<link rel="icon" type="image/svg+xml" href="{landing_favicon_datauri()}">'
    # href is double-quoted and the data-URI SVG uses single quotes inside, so
    # match to the closing quote — NOT the first '>' (the SVG contains many).
    new, n = re.subn(r'<link rel="icon" type="image/svg\+xml" href="[^"]*">',
                     line, html, count=1)
    if n == 0:
        print('  ! website/index.html: <link rel="icon"> not found — skipped')
    elif new != html:
        open(path, "w").write(new)
        print("patched website/index.html landing favicon")
    else:
        print("website/index.html landing favicon already current")


# --- run -------------------------------------------------------------------
def main():
    print(f"glyph sprite: {GW}x{GH}px  coral {CORAL}")
    targets = png_targets()
    for rel, sz, kind in targets:
        write_png(rel, sz, kind)
    print(f"wrote {len(targets)} PNGs")
    write_android_config()
    print("wrote android adaptive-icon config (colors.xml, mipmap-anydpi-v26)")
    write_landing_favicon()


if __name__ == "__main__":
    main()
