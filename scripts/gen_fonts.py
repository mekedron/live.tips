#!/usr/bin/env python3
"""Build the self-hosted webfonts for the landing page (website/fonts/).

The landing used to load Outfit + Noto Sans straight from Google Fonts. That
chain (render-blocking CSS on fonts.googleapis.com -> woff2 on fonts.gstatic.com)
was the main PageSpeed penalty, so the page now self-hosts two variable-font
subsets built by this script:

  website/fonts/outfit-var.woff2    Outfit   wght 400..800, latin subset
  website/fonts/notosans-var.woff2  NotoSans wght 400..800, wdth pinned to 100

Rerun after changing FEATURES/UNICODES or to pick up upstream font updates:
  python3 scripts/gen_fonts.py

Requirements: fonttools + brotli (pip install fonttools brotli). Source TTFs
are fetched from the google/fonts repo into a temp dir on every run.
"""
import os
import subprocess
import sys
import tempfile
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "website", "fonts")

GOOGLE_FONTS_RAW = "https://raw.githubusercontent.com/google/fonts/main/ofl"

# Everything the landing page can render. Latin + Latin-1 covers the copy;
# the extras are the typographic punctuation used in the demo fan wall.
UNICODES = "U+0020-007E,U+00A0-00FF,U+2013-2014,U+2018-201D,U+2026,U+2032-2033"

# Default subsetter features plus tnum: the HUD total uses tabular numerals
# (font-variant-numeric: tabular-nums) so digits don't jitter as tips land.
FEATURES = ["*"]

TARGETS = [
    # (repo path, output name, axis limits)
    ("outfit/Outfit%5Bwght%5D.ttf", "outfit-var.woff2",
     {"wght": (400, 800)}),
    ("notosans/NotoSans%5Bwdth,wght%5D.ttf", "notosans-var.woff2",
     {"wght": (400, 800), "wdth": 100}),
]


def fetch(url, dst):
    print(f"  fetch {url}")
    with urllib.request.urlopen(url) as r, open(dst, "wb") as fh:
        fh.write(r.read())


def build(repo_path, out_name, axes, tmp):
    src = os.path.join(tmp, os.path.basename(repo_path).replace("%5B", "[").replace("%5D", "]"))
    fetch(f"{GOOGLE_FONTS_RAW}/{repo_path}", src)

    font = TTFont(src)

    # Subset BEFORE instancing: partially-instanced fonts can leave gvar
    # entries the subsetter no longer finds (KeyError on Noto Sans).
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = FEATURES
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=subset.parse_unicodes(UNICODES))
    subsetter.subset(font)

    instantiateVariableFont(font, axes, inplace=True)

    dst = os.path.join(OUT_DIR, out_name)
    os.makedirs(OUT_DIR, exist_ok=True)
    font.save(dst)
    print(f"  wrote website/fonts/{out_name} ({os.path.getsize(dst) / 1024:.1f} KB)")


def main():
    with tempfile.TemporaryDirectory() as tmp:
        for repo_path, out_name, axes in TARGETS:
            build(repo_path, out_name, axes, tmp)


if __name__ == "__main__":
    main()
