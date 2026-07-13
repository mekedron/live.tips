#!/usr/bin/env python3
"""Chroma-key a green-screen device screenshot to a transparent PNG,
then composite it onto a warm branded background for the Product Hunt gallery."""
import sys
import numpy as np
from PIL import Image, ImageFilter

def knockout(raw_path, out_transparent, right_trim=90):
    img = Image.open(raw_path).convert("RGBA")
    W, H = img.size
    img = img.crop((0, 0, W - right_trim, H))  # drop the browser scrollbar column
    a = np.array(img).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # distance to the sampled backdrop lime (#00ff00 after the P3->sRGB shift)
    KR, KG, KB = 134, 249, 71
    dist = np.sqrt((r - KR) ** 2 + (g - KG) ** 2 + (b - KB) ** 2)
    key = dist < 70
    alpha = np.where(key, 0, 255).astype(np.uint8)
    # green-spill suppression on the kept pixels (kills the 1px green rim on the bezel)
    mx = np.maximum(r, b)
    g2 = np.where(g > mx, mx, g)
    a[..., 1] = g2
    a[..., 3] = alpha
    out = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    bbox = out.split()[3].getbbox()
    out = out.crop(bbox)
    out.save(out_transparent)
    print(f"transparent -> {out_transparent} {out.size}")
    return out

def warm_bg(w, h):
    ys = np.linspace(0, 1, h)[:, None]
    # vertical cream -> peach
    top = np.array([253, 247, 240]);  bot = np.array([246, 231, 219])
    grad = (top * (1 - ys) + bot * ys)
    canvas = np.repeat(grad[:, None, :], w, axis=1)
    # soft coral radial glow, centred a bit above middle
    xx, yy = np.meshgrid(np.linspace(0, 1, w), np.linspace(0, 1, h))
    cx, cy = 0.5, 0.42
    d = np.sqrt(((xx - cx) * 1.1) ** 2 + (yy - cy) ** 2)
    glow = np.clip(1 - d / 0.6, 0, 1) ** 2
    coral = np.array([232, 120, 74])
    canvas = canvas * (1 - 0.16 * glow[..., None]) + coral * (0.16 * glow[..., None])
    return Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

def compose(device, out_path, canvas_w=2400, canvas_h=1600, dev_frac=0.66, cy=0.5):
    bg = warm_bg(canvas_w, canvas_h)
    # scale device so its width is dev_frac of canvas
    dw, dh = device.size
    target_w = int(canvas_w * dev_frac)
    scale = target_w / dw
    target_h = int(dh * scale)
    dev = device.resize((target_w, target_h), Image.LANCZOS)
    x = (canvas_w - target_w) // 2
    y = int(canvas_h * cy - target_h / 2)
    # soft drop shadow from the alpha silhouette
    sil = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", dev.size, (0, 0, 0, 0))
    a = dev.split()[3]
    black = Image.new("RGBA", dev.size, (30, 18, 10, 255))
    shadow_layer = Image.composite(black, shadow_layer, a)
    sil.paste(shadow_layer, (x, y + int(canvas_h * 0.028)), shadow_layer)
    sil = sil.filter(ImageFilter.GaussianBlur(38))
    # dial shadow opacity down
    sa = np.array(sil)
    sa[..., 3] = (sa[..., 3] * 0.45).astype(np.uint8)
    sil = Image.fromarray(sa, "RGBA")
    bg = Image.alpha_composite(bg, sil)
    bg.alpha_composite(dev, (x, y))
    bg.convert("RGB").save(out_path, quality=95)
    print(f"gallery -> {out_path} {bg.size}")

if __name__ == "__main__":
    raw, transp, gallery = sys.argv[1], sys.argv[2], sys.argv[3]
    cw = int(sys.argv[4]); ch = int(sys.argv[5]); frac = float(sys.argv[6])
    dev = knockout(raw, transp)
    compose(dev, gallery, cw, ch, frac)
