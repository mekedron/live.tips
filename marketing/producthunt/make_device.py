#!/usr/bin/env python3
"""Wrap an app screenshot in a clean device bezel on the warm brand background."""
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from make_frames import warm_bg

def rounded_mask(size, r):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], r, fill=255)
    return m

def frame_device(shot, bezel_frac=0.020, screen_r_frac=0.030, bezel=(12, 12, 14)):
    shot = shot.convert("RGBA")
    sw, sh = shot.size
    b = int(round(min(sw, sh) * bezel_frac))
    sr = int(min(sw, sh) * screen_r_frac)
    shot.putalpha(rounded_mask((sw, sh), sr))
    ow, oh = sw + 2 * b, sh + 2 * b
    orr = sr + b
    device = Image.new("RGBA", (ow, oh), (0, 0, 0, 0))
    bez = Image.new("RGBA", (ow, oh), bezel + (255,))
    bez.putalpha(rounded_mask((ow, oh), orr))
    # faint outer rim highlight
    rim = Image.new("RGBA", (ow, oh), (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle([0, 0, ow - 1, oh - 1], orr, outline=(70, 70, 76, 255), width=max(2, b // 6))
    device = Image.alpha_composite(device, bez)
    device = Image.alpha_composite(device, rim)
    device.alpha_composite(shot, (b, b))
    return device

def compose(device, out, cw, ch, frac, cy=0.5):
    bg = warm_bg(cw, ch)
    dw, dh = device.size
    tw = int(cw * frac)
    s = tw / dw
    th = int(dh * s)
    dev = device.resize((tw, th), Image.LANCZOS)
    x = (cw - tw) // 2
    y = int(ch * cy - th / 2)
    shadow = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    blk = Image.new("RGBA", dev.size, (26, 15, 8, 255))
    sil = Image.composite(blk, Image.new("RGBA", dev.size, (0, 0, 0, 0)), dev.split()[3])
    shadow.paste(sil, (x, y + int(ch * 0.028)), sil)
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(cw * 0.016)))
    arr = np.array(shadow); arr[..., 3] = (arr[..., 3] * 0.42).astype(np.uint8)
    bg = Image.alpha_composite(bg, Image.fromarray(arr, "RGBA"))
    bg.alpha_composite(dev, (x, y))
    bg.convert("RGB").save(out, quality=95)
    print(f"saved {out} {bg.size}")

if __name__ == "__main__":
    shot_path, out_path, orient = sys.argv[1], sys.argv[2], sys.argv[3]
    dev = frame_device(Image.open(shot_path))
    if orient == "landscape":
        compose(dev, out_path, 2400, 1600, 0.80)
    else:
        compose(dev, out_path, 1280, 1640, 0.52)
