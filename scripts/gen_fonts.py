#!/usr/bin/env python3
"""Build the self-hosted webfonts for the landing page (website/fonts/).

The landing used to load Outfit + Noto Sans straight from Google Fonts. That
chain (render-blocking CSS on fonts.googleapis.com -> woff2 on fonts.gstatic.com)
was the main PageSpeed penalty, so the page now self-hosts variable-font
subsets built by this script.

Since the site is localized into Latin-, Cyrillic- and Greek-script languages,
Noto Sans (body text) is split by script and wired up with matching
`unicode-range` @font-face rules in the template, so a Latin page never
downloads Cyrillic/Greek glyphs. Outfit (headings/UI) ships Latin + Latin-ext
only upstream — no Cyrillic/Greek — so for those scripts headings fall through
to Noto Sans via the `Outfit, 'Noto Sans', …` stacks in the template.

Latin itself is split into latin-1 and latin-ext so the many Latin-1-only
languages (English, German, Spanish, Italian, Portuguese, Dutch, Swedish) never
download the Extended-A glyphs that only Polish/Czech/Turkish/Hungarian/Romanian
and French (œ) actually use.

  website/fonts/outfit-latin.woff2      Outfit    Basic Latin + Latin-1
  website/fonts/outfit-latinext.woff2   Outfit    Latin Extended-A/B
  website/fonts/notosans-latin.woff2    NotoSans  Basic Latin + Latin-1
  website/fonts/notosans-latinext.woff2 NotoSans  Latin Extended-A/B
  website/fonts/notosans-cyrillic.woff2 NotoSans  Cyrillic
  website/fonts/notosans-greek.woff2    NotoSans  Greek

Rerun after changing the ranges below or to pick up upstream font updates:
  python3 scripts/gen_fonts.py

Requirements: fonttools + brotli (pip install fonttools brotli). Source TTFs
are fetched from the google/fonts repo into a temp dir on every run.
"""
import os
import tempfile
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "website", "fonts")

GOOGLE_FONTS_RAW = "https://raw.githubusercontent.com/google/fonts/main/ofl"

# Basic Latin + Latin-1, the typographic punctuation used across the page, and
# the rightwards arrow used in the language switcher/banner. Covers English,
# German, Spanish, Italian, Portuguese, Dutch and Swedish outright.
LATIN1 = ("U+0020-007E,U+00A0-00FF,U+2013-2014,U+2018-201E,"
          "U+2026,U+2032-2033,U+2192")
# Latin Extended-A (Polish/Czech/Hungarian/Turkish/Romanian/French œ …) plus the
# Romanian comma-below s/t (Latin Extended-B). Loaded only where actually used.
LATINEXT = "U+0100-017F,U+0218-021B"
# Russian + Ukrainian (incl. ґ/Ґ) and the numero sign.
CYRILLIC = "U+0400-045F,U+0490-0491,U+2116"
# Modern (monotonic) Greek.
GREEK = "U+0370-03FF"

OUTFIT = "outfit/Outfit%5Bwght%5D.ttf"
NOTO = "notosans/NotoSans%5Bwdth,wght%5D.ttf"

TARGETS = [
    # (repo path, output name, axis limits, unicode subset)
    (OUTFIT, "outfit-latin.woff2",      {"wght": (400, 800)}, LATIN1),
    (OUTFIT, "outfit-latinext.woff2",   {"wght": (400, 800)}, LATINEXT),
    (NOTO,   "notosans-latin.woff2",     {"wght": (400, 800), "wdth": 100}, LATIN1),
    (NOTO,   "notosans-latinext.woff2",  {"wght": (400, 800), "wdth": 100}, LATINEXT),
    (NOTO,   "notosans-cyrillic.woff2",  {"wght": (400, 800), "wdth": 100}, CYRILLIC),
    (NOTO,   "notosans-greek.woff2",     {"wght": (400, 800), "wdth": 100}, GREEK),
]


def fetch(url, dst):
    if os.path.exists(dst):
        return
    print(f"  fetch {url}")
    with urllib.request.urlopen(url) as r, open(dst, "wb") as fh:
        fh.write(r.read())


def build(repo_path, out_name, axes, unicodes, tmp):
    src = os.path.join(tmp, os.path.basename(repo_path).replace("%5B", "[").replace("%5D", "]"))
    fetch(f"{GOOGLE_FONTS_RAW}/{repo_path}", src)

    font = TTFont(src)

    # Subset BEFORE instancing: partially-instanced fonts can leave gvar
    # entries the subsetter no longer finds (KeyError on Noto Sans).
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = ["*"]  # keep default features + tnum for the HUD's tabular digits
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=subset.parse_unicodes(unicodes))
    subsetter.subset(font)

    instantiateVariableFont(font, axes, inplace=True)

    dst = os.path.join(OUT_DIR, out_name)
    os.makedirs(OUT_DIR, exist_ok=True)
    font.save(dst)
    print(f"  wrote website/fonts/{out_name} ({os.path.getsize(dst) / 1024:.1f} KB)")


def main():
    with tempfile.TemporaryDirectory() as tmp:
        for repo_path, out_name, axes, unicodes in TARGETS:
            build(repo_path, out_name, axes, unicodes, tmp)


if __name__ == "__main__":
    main()
