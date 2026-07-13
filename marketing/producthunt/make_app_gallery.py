#!/usr/bin/env python3
"""Frame the real-app Concert 3L shots into iPad + iPhone, and a combined hero."""
import numpy as np
from PIL import Image, ImageFilter
from make_device import frame_device, compose
from make_frames import warm_bg

IPAD_SHOT = ".validation/app-concert-3l-tablet-qr.png"
IPHONE_SHOT = ".validation/app-concert-3l-phone.png"
OUT = "marketing/producthunt/"

ipad = frame_device(Image.open(IPAD_SHOT))
iphone = frame_device(Image.open(IPHONE_SHOT))

# individual gallery images
compose(ipad, OUT + "ph-ipad-concert.png", 2400, 1600, 0.80)
compose(iphone, OUT + "ph-iphone-concert.png", 1280, 1640, 0.52)

# combined device-family hero
def fit_w(img, w):
    return img.resize((w, int(img.height * w / img.width)), Image.LANCZOS)

def soft_shadow(cs, dev, pos, dy, blur, op):
    cw, ch = cs
    layer = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    blk = Image.new("RGBA", dev.size, (26, 15, 8, 255))
    sil = Image.composite(blk, Image.new("RGBA", dev.size, (0, 0, 0, 0)), dev.split()[3])
    layer.paste(sil, (pos[0], pos[1] + dy), sil)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    arr = np.array(layer); arr[..., 3] = (arr[..., 3] * op).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")

CW, CH = 2400, 1350
bg = warm_bg(CW, CH)
ip = fit_w(ipad, 1560)
ph = fit_w(iphone, 470)
ip_pos = (120, (CH - ip.height) // 2 - 10)
ph_pos = (1590, CH - ph.height - 30)
bg = Image.alpha_composite(bg, soft_shadow((CW, CH), ip, ip_pos, 34, 38, 0.42))
bg.alpha_composite(ip, ip_pos)
bg = Image.alpha_composite(bg, soft_shadow((CW, CH), ph, ph_pos, 26, 30, 0.34))
bg.alpha_composite(ph, ph_pos)
bg.convert("RGB").save(OUT + "ph-hero-concert.png", quality=95)
print("hero ->", OUT + "ph-hero-concert.png", bg.size)
