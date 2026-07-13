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

## The legal pages are Markdown, in every language

`/privacy/` and `/terms/` are rendered by
[`scripts/build_legal.py`](../scripts/build_legal.py) from one Markdown file per
language per document, into the same chrome as everything else:

    website/legal/privacy/en.md  →  /privacy/      (and /de/privacy/, /ru/privacy/, …)
    website/legal/terms/en.md    →  /terms/        (and /de/terms/,   /ru/terms/,   …)

Unlike a blog post, a legal document **may not be missing in a language** — the
footer links to it from every page, so a gap would be a 404. A missing
translation falls back to the English body with a build warning rather than
failing the deploy, and the hreflang cluster always names all twenty locales.

`en.md` is the source of truth, and each document says so: if a translation and
the English disagree, the English governs. **Edit `en.md` first, then re-translate
— never patch a translation alone**, or the two drift and the page is lying to
someone. The frontmatter (`title`, `description`, `updated`, `updated_label`) is
required in every file; the body must not contain an `<h1>` (the template owns
the only one).

The content is not decoration: it describes what the code actually does — the
one-hour undelivered-tip window, the 90-day profile expiry, the hashed-IP quota.
**If you change that behaviour in `worker/`, the policy is part of the change.**

## The rendered site contacts no third party

This is a promise `/privacy/` makes out loud, so the build keeps it true:

- The **Product Hunt badge** is served from `ph-badge-light.svg` /
  `ph-badge-dark.svg` in this directory, not from `api.producthunt.com`. Re-download
  those two files if the badge's ranking text goes stale.
- The **GitHub star count** is fetched **at build time** by `site_common.gh_stars_badge()`
  and baked into the header. There is no `fetch()` in the browser. A build with no
  network just omits the badge and warns.

Fonts, icons and images are all local. Do not add a script, an image, an iframe or
a `fetch()` pointing at another origin without updating `/privacy/` in all twenty
languages first.

### Editing copy
- **English wording** → edit the value in `i18n/strings/en.json`
  (and `i18n/template.html` if you're changing markup/structure).
- **A translation** → edit `i18n/strings/<code>.json`.
- **Add a language** → add an entry to `i18n/locales.json` and drop a matching
  `i18n/strings/<code>.json`. Nothing else to wire up. (A missing key falls
  back to English with a build warning.)

The `{{key}}` placeholders never collide with the page's CSS/JS braces; a few
values carry inline markup (`hero_h1`, `hero_sub`, `stage_caption`, `cta_h2`)
and are injected raw — everything else is HTML-escaped. A second directive,
`{{> partials/x.html}}`, splices a file in before any `{{key}}` is filled, which
is how the landing and the blog share one header, footer, banner, stylesheet and
chrome script (see [`i18n/partials/`](i18n/partials/)).

## The blog

Posts are Markdown, in [`blog/posts/<dir>/`](blog/posts/), rendered by
[`scripts/build_blog.py`](../scripts/build_blog.py) (which `build_site.py` calls,
so both share one locale registry and one `sitemap.xml`).

```
blog/posts/one-qr-code-every-payment-method/
  post.json     date, updated?, cover?, cover_alt?, tags?, draft?, order?
  en.md         REQUIRED — every untranslated locale links its readers here
  de.md         optional; a post exists in the languages it has files for
  assets/       images, copied once and addressed from every language
```

Each `<lang>.md` opens with a flat `---` frontmatter block: `title` and
`description` are required, `slug` and `updated` are optional per-language
overrides. It is not YAML — a real YAML parser would read `slug: no` as `false`.

**Write a post** → new directory, a `post.json` with a `date`, and an `en.md`.
**Translate one** → drop a `<lang>.md` beside it. Nothing else to wire up.

Images in `assets/` are shared by every language, so an image with *words in it*
needs one file per language. The comparison post's diagram does; it is generated
from a table of short strings by
[`scripts/gen_blog_diagram.py`](../scripts/gen_blog_diagram.py), which sizes each
box to its own label — a diagram is served through `<img>` and so cannot use the
page's webfont, and a layout tuned on English clips the first German compound
noun it meets. Regenerate with `python3 scripts/gen_blog_diagram.py`.

Three rules are worth knowing before you write:

- **Untranslated is a normal state.** A post is only ever published in the
  languages it was actually written in; an English body is never served from
  `/de/blog/…`. Every locale's index still lists every post — an untranslated one
  shows its English title, an "In English" badge, and links to the English URL.
- **Every page canonicalizes to itself.** A translation is not a duplicate of the
  English post. Pointing its canonical at `/blog/<en-slug>/` would drop it from
  Google's index *and* void the hreflang cluster that ties the languages together.
  Each post's cluster names only the locales it exists in, plus `x-default`.
- **Cross-link posts as `[text](post:<dir>)`**, never as a URL — slugs differ per
  language, so the build resolves `post:` to the reader's own locale (or English
  if that post has no translation there). Images are `assets/x.jpg`, rewritten to
  the one absolute copy.

Each post also gets a raw-Markdown twin at its URL + `.md` (for LLMs and agents),
a per-locale Atom feed at `/blog/feed.xml`, and `BlogPosting` + `BreadcrumbList`
JSON-LD. Blog chrome strings live in [`i18n/blog_strings/`](i18n/blog_strings/),
separate from the landing's `strings/` so the blog can ship English-first without
the landing warning about every untranslated key.

Mistakes fail the build with a message naming the file: a link into a draft, two
posts colliding on a slug in some language, a post with no `en.md`, frontmatter
missing a title. [`scripts/check_site.py`](../scripts/check_site.py) then gates
the rendered output — self-canonical everywhere, every hreflang and sitemap
target resolves, JSON-LD parses — and the deploy runs it after every build.

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
| `index.html`, `<code>/index.html`, `blog/**`, `<code>/blog/**`, `privacy/`, `terms/`, `<code>/privacy/`, `<code>/terms/`, `sitemap.xml` | `python3 scripts/build_site.py --out _site` (run by the deploy) |

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
