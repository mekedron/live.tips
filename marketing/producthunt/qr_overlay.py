#!/usr/bin/env python3
"""Overlay the verified live.tips QR onto the app stage screenshot's QR card."""
import sys
import numpy as np
from PIL import Image

def make_qr_tile(qr_png):
    im = Image.open(qr_png).convert("L")
    a = np.array(im)
    ys, xs = np.where(a < 128)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    qr = Image.open(qr_png).convert("RGB").crop((x0, y0, x1 + 1, y1 + 1))
    # add a 3-module white quiet zone
    module = qr.width / 25.0
    pad = int(round(module * 3))
    tile = Image.new("RGB", (qr.width + 2 * pad, qr.height + 2 * pad), (255, 255, 255))
    tile.paste(qr, (pad, pad))
    return tile

def detect_card(app_img):
    a = np.array(app_img.convert("RGB")).astype(np.int16)
    H, W, _ = a.shape
    mn = a.min(axis=2)
    white = mn > 225
    # search the upper-right region where the QR card lives
    mask = np.zeros_like(white)
    x_lo, x_hi = int(0.60 * W), W
    y_lo, y_hi = int(0.03 * H), int(0.65 * H)
    mask[y_lo:y_hi, x_lo:x_hi] = white[y_lo:y_hi, x_lo:x_hi]
    ys, xs = np.where(mask)
    return xs.min(), ys.min(), xs.max(), ys.max()

def qr_core(qr_png):
    """The QR cropped tight to its black modules (no quiet zone)."""
    g = np.array(Image.open(qr_png).convert("L"))
    ys, xs = np.where(g < 128)
    return Image.open(qr_png).convert("RGB").crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

def overlay(app_png, qr_png, out_png):
    app = Image.open(app_png).convert("RGB")
    a = np.array(app).astype(np.int16)
    x0, y0, x1, y1 = detect_card(app)
    # QR white region = bright rows near the top of the card (the "Scan to tip"
    # text below is thin, so it has low white-density and is excluded).
    sub = a[y0:y1 + 1, x0:x1 + 1]
    white = sub.min(axis=2) > 205
    h, w = white.shape
    rows = np.where(white.sum(axis=1) > 0.45 * w)[0]
    qtop, qbot = y0 + rows.min(), y0 + rows.max()
    tile = make_qr_tile(qr_png)
    cw = x1 - x0 + 1
    inset = max(2, int(cw * 0.015))
    side = cw - 2 * inset
    tile_r = tile.resize((side, side), Image.LANCZOS)
    px = x0 + inset
    py = qtop + inset
    app.paste(tile_r, (px, py))
    app.save(out_png)
    print(f"card=({x0},{y0},{x1},{y1}) qr-white-rows={qtop}..{qbot} -> {side}px at ({px},{py})")
    print(f"saved {out_png}")

if __name__ == "__main__":
    overlay(sys.argv[1], sys.argv[2], sys.argv[3])
