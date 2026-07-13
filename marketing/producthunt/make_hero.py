#!/usr/bin/env python3
"""Combine the transparent iPad + iPhone frames into one 'device family' hero
on the warm branded background."""
import numpy as np
from PIL import Image, ImageFilter
from make_frames import warm_bg

def soft_shadow(canvas_size, dev, pos, dy, blur, opacity, tint=(30, 18, 10)):
    cw, ch = canvas_size
    layer = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    a = dev.split()[3]
    black = Image.new("RGBA", dev.size, tint + (255,))
    sh = Image.composite(black, Image.new("RGBA", dev.size, (0, 0, 0, 0)), a)
    layer.paste(sh, (pos[0], pos[1] + dy), sh)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    arr = np.array(layer)
    arr[..., 3] = (arr[..., 3] * opacity).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")

def fit_w(img, w):
    h = int(img.height * w / img.width)
    return img.resize((w, h), Image.LANCZOS)

CW, CH = 2400, 1350
bg = warm_bg(CW, CH)

ipad = Image.open("marketing/producthunt/ipad-demo-transparent.png").convert("RGBA")
iphone = Image.open("marketing/producthunt/iphone-demo-transparent.png").convert("RGBA")

ipad = fit_w(ipad, 1560)
iphone = fit_w(iphone, 560)

ipad_pos = (150, (CH - ipad.height) // 2 - 20)
iphone_pos = (1520, CH - iphone.height - 40)

bg = Image.alpha_composite(bg, soft_shadow((CW, CH), ipad, ipad_pos, 34, 0.42, 46))
bg.alpha_composite(ipad, ipad_pos)
bg = Image.alpha_composite(bg, soft_shadow((CW, CH), iphone, iphone_pos, 26, 0.5, 34))
bg.alpha_composite(iphone, iphone_pos)

bg.convert("RGB").save("marketing/producthunt/ph-hero-devices.png", quality=95)
print("hero -> marketing/producthunt/ph-hero-devices.png", bg.size)
