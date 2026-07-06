# website — live.tips landing page

The marketing landing page, deployed to **GitHub Pages** at
<https://live.tips/> by
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml).

## The tip-jar stage is reused, not copied

The landing page embeds the live 3D tip jar in an
`<iframe id="stage-frame" data-src="stage/index.html">` and drives it over the
same JSON bridge the Flutter app uses
([`renderer/PROTOCOL.md`](../renderer/PROTOCOL.md)). The `src` is set lazily
(first user gesture, or when the card is mostly on screen) so the WebGL boot
never lands in the critical path — this is what keeps mobile PageSpeed at 100.

There is **no copy of the renderer here.** `stage/index.html` and `stage/stage.js`
are assembled at deploy time from the committed build in
[`app/assets/stage/`](../app/assets/stage/) — the single source of truth,
rebuilt from `renderer/src/` via `npm run build`. Do not add a `stage/` folder
to `website/`.

## Generated assets — don't edit by hand

| File | Regenerate with |
| --- | --- |
| `favicon.png`, `apple-touch-icon.png`, inline SVG favicon | `python3 scripts/gen_icons.py` |
| `og-image.png` (social share banner) | `python3 scripts/gen_og_image.py` |
| `fonts/*.woff2` (self-hosted Outfit + Noto Sans subsets) | `python3 scripts/gen_fonts.py` |

Icons in `index.html` are inline Material Symbols SVG paths (`svg.ms`) — there
is deliberately no icon font. `robots.txt` and `sitemap.xml` are hand-edited;
bump `<lastmod>` when the page meaningfully changes.

## Layout on the published site

| Path | Source |
| --- | --- |
| `/` | `website/index.html` (+ the static assets above) |
| `/stage/` | copied from `app/assets/stage/` by the workflow |
| `/app/` | the Flutter web app, built fresh by the workflow |

## Preview locally

The stage is same-origin, so serve the assembled tree over HTTP (not `file://`):

```sh
# from the repo root
mkdir -p /tmp/lt-site/stage
cp -R website/. /tmp/lt-site/ && rm -f /tmp/lt-site/README.md
cp app/assets/stage/index.html app/assets/stage/stage.js /tmp/lt-site/stage/
python3 -m http.server 8080 --directory /tmp/lt-site
# → http://127.0.0.1:8080/
```
