# live.tips stage library

The tip-jar stage visualization the app embeds in a WebView: a glass vessel
that fills with euro-like coins/banknotes toward the session goal, spills over
past 100%, and retires full jars to a trophy shelf at 200%. Two renderers, one
bridge:

- **`src/stage3d/`** — three.js (vendored r180): 11 real-dimension vessels,
  6 procedural backdrop scenes (abstract / pub / concert / street / metro /
  cafe), PMREM reflections, bloom quality tier, orbit camera, auto-degrade.
- **`src/stage2d/`** — pure Canvas 2D for the weakest tablets: pre-rendered
  sprites, settled money baked to offscreen layers, rAF stops when idle.

Both are driven exclusively through the JSON bridge documented in
**[PROTOCOL.md](PROTOCOL.md)** — no UI of their own, no URL params, no
localStorage. `init.renderer: '3d' | '2d'` picks the variant. Ported from the
tip-jar-5 prototype; the packing/pour simulation is deterministic (seeded) —
no physics engine (see the header comment in `src/stage3d/app.js`).

## Build

```sh
npm install        # once (esbuild only)
npm run build      # → ../app/assets/stage/stage.js (single-file IIFE)
npm run watch      # rebuild on save
```

**The artifact is committed** (`app/assets/stage/stage.js` +
`app/assets/stage/index.html`), so `flutter build` never needs node. Re-run
the build and commit both whenever `src/` changes.

## Dev harness

```sh
# from the repo root
python3 -m http.server 8917
# → http://127.0.0.1:8917/renderer/dev.html
```

`dev.html` fakes the host side of the bridge: boot either renderer, fire tips
(including rollover storms), sync absolute states, toggle scene/vessel/theme/
notes/sound, pause — and watch the JS→host message log live. Screenshots for
visual QA belong in `.validation/` (gitignored), never in the repo.
