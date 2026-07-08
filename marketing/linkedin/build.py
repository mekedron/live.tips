#!/usr/bin/env python3
"""Inject brand fonts/logo/screenshot/QR into the card sources.

Writes sources/cardN.final.html next to each source; screenshot those at a
1200x1500 viewport (2x) to regenerate the PNGs.
"""
import base64
import pathlib

here = pathlib.Path(__file__).resolve().parent
web = here.parent.parent / "website"


def b64(path: pathlib.Path) -> str:
    return base64.b64encode(path.read_bytes()).decode()


replacements = {
    "@@OUTFIT@@": b64(web / "fonts/outfit-latin.woff2"),
    "@@NOTO@@": b64(web / "fonts/notosans-latin.woff2"),
    "@@LOGO@@": b64(web / "apple-touch-icon.png"),
    "@@STAGE@@": b64(here / "sources/stage-real.png"),
    "@@QR@@": (here / "qr-livetips.svg").read_text(),
}

for src in sorted((here / "sources").glob("card?.html")):
    text = src.read_text()
    for token, value in replacements.items():
        text = text.replace(token, value)
    out = src.with_suffix(".final.html")
    out.write_text(text)
    print(out.relative_to(here))
