# LinkedIn launch assets

Final assets for the live.tips launch post:

- `card1.png … card5.png` — branded cards, 2400×3000 (4:5): fees / stage alerts /
  payment methods / architecture / getting started
- `livetips-linkedin-carousel.pdf` — the five cards as a LinkedIn document post,
  in reading order: fees → stage alerts → payments → architecture → get started
- `qr-livetips.svg` — real QR code encoding `https://live.tips` (decoder-verified)
- `shot-stage-tip.png` — the landing-page stage demo mid-tip, for multi-image posts

## Editing the cards

The editable sources live in `sources/` with `@@PLACEHOLDER@@` tokens for the
brand fonts, logo, stage screenshot and QR code. To rebuild after a text change:

```bash
python3 build.py   # writes sources/*.final.html
```

Then open each `*.final.html` in a browser at a 1200×1500 viewport and take a
full-page screenshot at 2× for the 2400×3000 PNGs.
