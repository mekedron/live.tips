# website — live.tips landing page

The marketing landing page, deployed to **GitHub Pages** at
<https://live.tips/> by
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml).

## Localized from one source — no per-language clones

The page is authored once and rendered into every language at deploy time.
[`scripts/build_site.py`](../scripts/build_site.py) fills one template with
per-language strings and writes the root (English) plus one `/xx/` page per
locale:

| Path | Language |
| --- | --- |
| `/` | English (canonical) |
| `/en/` `/de/` `/fr/` `/es/` `/it/` `/pt/` `/nl/` `/pl/` `/uk/` `/cs/` `/hu/` `/ro/` `/el/` `/tr/` `/sv/` `/da/` `/no/` `/fi/` `/is/` `/ru/` | one page per locale (order set in `locales.json`) |

Everything lives in [`i18n/`](i18n/):

| File | What it is |
| --- | --- |
| `i18n/template.html` | the page, with `{{placeholder}}` slots — **edit structure & markup here** |
| `i18n/strings/en.json` | English source of truth for every string |
| `i18n/strings/<code>.json` | one translation per language (identical keys to `en.json`) |
| `i18n/locales.json` | locale registry: endonym, `og:locale`, font script |

Every page is generated with a header language `<select>`, a full hreflang
cluster (`en` and `x-default` → root), `og:locale` alternates, and a
"this site is also available in …" banner driven by the visitor's browser
language. `sitemap.xml` (with hreflang alternates) is generated alongside; the
app and stage are excluded there and disallowed in `robots.txt`.

### Editing copy
- **English wording** → edit the value in `i18n/strings/en.json`
  (and `i18n/template.html` if you're changing markup/structure).
- **A translation** → edit `i18n/strings/<code>.json`.
- **Add a language** → add an entry to `i18n/locales.json` and drop a matching
  `i18n/strings/<code>.json`. Nothing else to wire up. (A missing key falls
  back to English with a build warning.)

The `{{key}}` placeholders never collide with the page's CSS/JS braces; a few
values carry inline markup (`hero_h1`, `hero_sub`, `stage_caption`, `cta_h2`)
and are injected raw — everything else is HTML-escaped.

## The tip-jar stage is reused, not copied

The landing page embeds the live 3D tip jar in an
`<iframe id="stage-frame" data-src="/stage/index.html">` and drives it over the
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
| `fonts/*.woff2` (Outfit + Noto Sans subsets, split latin / latin-ext / Cyrillic / Greek) | `python3 scripts/gen_fonts.py` |
| `index.html`, `<code>/index.html`, `sitemap.xml` | `python3 scripts/build_site.py --out _site` (run by the deploy) |

Icons in the template are inline Material Symbols SVG paths (`svg.ms`) — there
is deliberately no icon font. `robots.txt` and `llms.txt` (an LLM-facing
description of the project, per <https://llmstxt.org/>, English-only) are
hand-edited static files served from the site root; `sitemap.xml` is generated,
so don't commit one by hand.

## Preview locally

The stage is same-origin, so serve the assembled tree over HTTP (not `file://`):

```sh
# from the repo root
python3 scripts/build_site.py --out /tmp/lt-site
mkdir -p /tmp/lt-site/stage
cp app/assets/stage/index.html app/assets/stage/stage.js /tmp/lt-site/stage/
python3 -m http.server 8080 --directory /tmp/lt-site
# → http://127.0.0.1:8080/      (English root)
# → http://127.0.0.1:8080/de/   (Deutsch), /ru/, /el/, …
```
