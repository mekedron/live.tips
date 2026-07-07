#!/usr/bin/env python3
"""Render the localized landing pages from one template + per-language strings.

The marketing site is authored ONCE as `website/i18n/template.html` with
`{{placeholder}}` slots. This script fills those slots from
`website/i18n/strings/<code>.json` (one file per language; `en.json` is the
English source of truth) and writes a static page per locale:

    _site/index.html         English  (root, canonical)
    _site/en/index.html      English  (alias, canonical -> root)
    _site/de/index.html      Deutsch
    _site/es/index.html      Español
    ... one dir per locale in website/i18n/locales.json ...

It also emits `sitemap.xml` (with hreflang alternates) and copies the static
assets from `website/` (fonts, icons, og-image, robots.txt). Every page gets a
full hreflang cluster, a per-locale <select> switcher, and the embedded data
the cross-language banner needs — all derived here, so adding a language is
just a new strings/<code>.json plus an entry in locales.json.

Usage (also run verbatim by .github/workflows/pages.yml):
    python3 scripts/build_site.py --out _site
    python3 scripts/build_site.py --out /tmp/lt-site --base https://live.tips
"""
import argparse
import html
import json
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "website")
I18N = os.path.join(WEB, "i18n")
STRINGS = os.path.join(I18N, "strings")

# Values that legitimately contain inline markup (<br>, <em>, <strong>) and so
# are injected verbatim; every other string is HTML-escaped.
HTML_KEYS = {"hero_h1", "hero_sub", "stage_caption", "cta_h2"}

# Runtime strings handed to the page's JS (see template's `var I18N = …`).
JS_KEYS = ("goal_tmpl", "tip_tmpl", "theme")

# The demo HUD's initial numbers, matching the renderer boot state in the
# template's script, so localized static text doesn't flash then change.
INIT = {"total": "$436.00", "done": "$436", "goal": "$1,000", "pct": "44",
        "name": "Anna S.", "amount": "$5.00"}

PLACEHOLDER_RE = re.compile(r"\{\{\s*([\w.\-]+)\s*\}\}")


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def esc(s):
    return html.escape(s, quote=True)


def js_literal(obj):
    """JSON for embedding in a <script>; neutralize any </script> break-out."""
    return json.dumps(obj, ensure_ascii=False).replace("<", "\\u003c")


def home_path(code, default):
    return "/" if code == default else "/%s/" % code


def loc_url(base, code, default):
    return base + "/" if code == default else "%s/%s/" % (base, code)


def render(template, subs):
    def repl(m):
        key = m.group(1)
        if key not in subs:
            raise KeyError("template placeholder {{%s}} has no value" % key)
        return subs[key]
    return PLACEHOLDER_RE.sub(repl, template)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def build(out_dir, base):
    base = base.rstrip("/")
    template = open(os.path.join(I18N, "template.html"), encoding="utf-8").read()
    reg = load_json(os.path.join(I18N, "locales.json"))
    default = reg["default"]
    locales = reg["locales"]
    codes = [l["code"] for l in locales]
    names = {l["code"]: l["name"] for l in locales}
    flags = {l["code"]: l.get("flag", "") for l in locales}

    en = load_json(os.path.join(STRINGS, "en.json"))

    # Load every locale's strings up front (English-filled for any gaps) so the
    # banner table can carry each language's own invitation phrase.
    all_strings, warnings = {}, []
    for code in codes:
        path = os.path.join(STRINGS, "%s.json" % code)
        data = load_json(path) if os.path.exists(path) else {}
        if not os.path.exists(path):
            warnings.append("  %s.json missing — English fallback for all keys" % code)
        merged = dict(en)
        merged.update({k: v for k, v in data.items() if k in en})
        missing = [k for k in en if k not in data]
        if data and missing:
            warnings.append("  %s.json missing %d key(s): %s"
                            % (code, len(missing), ", ".join(missing[:8])
                               + (" …" if len(missing) > 8 else "")))
        all_strings[code] = merged

    # Cross-language banner data (constant across pages): code, endonym, and the
    # "also available in …" phrase written IN that language.
    locales_js = js_literal([{"c": c, "n": names[c], "b": all_strings[c]["banner"], "f": flags[c]}
                             for c in codes])

    # hreflang cluster (constant): x-default + English -> site root, others -> /code/.
    hreflang = ['<link rel="alternate" hreflang="x-default" href="%s">' % (base + "/")]
    for c in codes:
        hreflang.append('<link rel="alternate" hreflang="%s" href="%s">'
                        % (c, loc_url(base, c, default)))
    hreflang_links = "\n".join(hreflang)

    def page(code):
        s = all_strings[code]
        loc = next(l for l in locales if l["code"] == code)
        canon = loc_url(base, code, default)

        subs = {}
        for k, v in s.items():
            subs[k] = v if k in HTML_KEYS else esc(v)

        # Language <select> options (flag + endonym), current one preselected.
        # The same options feed both the desktop pill select and the mobile
        # circular-flag switcher, so the native picker always lists names.
        opts = []
        for c in codes:
            sel = " selected" if c == code else ""
            full = ("%s %s" % (flags[c], names[c])).strip()
            opts.append('<option value="%s"%s>%s</option>'
                        % (home_path(c, default), sel, esc(full)))
        # og:locale:alternate for every other locale.
        alts = "\n".join('<meta property="og:locale:alternate" content="%s">' % l["og_locale"]
                         for l in locales if l["code"] != code)
        # Per-locale font preloads: Latin-1 always; add the extra subset the
        # locale's script needs so its glyphs don't wait on lazy discovery.
        def preload(stem):
            return ('<link rel="preload" href="/fonts/%s.woff2" as="font" type="font/woff2" crossorigin>'
                    % stem)
        preloads = [preload("outfit-latin"), preload("notosans-latin")]
        if loc["script"] == "latinext":
            preloads += [preload("outfit-latinext"), preload("notosans-latinext")]
        elif loc["script"] == "cyrillic":
            preloads.append(preload("notosans-cyrillic"))
        elif loc["script"] == "greek":
            preloads.append(preload("notosans-greek"))

        subs.update({
            "html_lang": code,
            "canonical_url": canon,
            "og_url": canon,
            "og_locale": loc["og_locale"],
            "og_locale_alternates": alts,
            "hreflang_links": hreflang_links,
            "font_preloads": "\n".join(preloads),
            "lang_switcher_options": "".join(opts),
            "current_flag": esc(flags[code]),
            "i18n_js": js_literal({k: s[k] for k in JS_KEYS}),
            "locales_js": locales_js,
            "code": code,
            "hud_total_static": esc(INIT["total"]),
            "hud_goal_static": esc(s["goal_tmpl"].replace("{done}", INIT["done"])
                                   .replace("{goal}", INIT["goal"]).replace("{pct}", INIT["pct"])),
            "toast_title_static": esc(s["tip_tmpl"].replace("{name}", INIT["name"])
                                      .replace("{amount}", INIT["amount"])),
        })
        return render(template, subs)

    # Emit root (English) + one directory per locale.
    write(os.path.join(out_dir, "index.html"), page(default))
    for code in codes:
        write(os.path.join(out_dir, code, "index.html"), page(code))

    # Static assets: everything under website/ except the i18n sources, the
    # internal README, and the files this build (re)generates.
    skip = {"i18n", "README.md", "index.html", "sitemap.xml"}
    for name in sorted(os.listdir(WEB)):
        if name in skip:
            continue
        src = os.path.join(WEB, name)
        dst = os.path.join(out_dir, name)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            os.makedirs(out_dir, exist_ok=True)
            shutil.copy2(src, dst)

    # Sitemap: root + each /code/ (the /en/ alias and disallowed /app/, /stage/
    # are deliberately absent), every entry carrying the full hreflang set.
    xhtml = ['<xhtml:link rel="alternate" hreflang="x-default" href="%s"/>' % (base + "/")]
    for c in codes:
        xhtml.append('<xhtml:link rel="alternate" hreflang="%s" href="%s"/>'
                     % (c, loc_url(base, c, default)))
    alt_block = "\n".join("    " + x for x in xhtml)
    urls = []
    for c in codes:
        urls.append("  <url>\n    <loc>%s</loc>\n%s\n  </url>" % (loc_url(base, c, default), alt_block))
    sitemap = ('<?xml version="1.0" encoding="UTF-8"?>\n'
               '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
               '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
               + "\n".join(urls) + "\n</urlset>\n")
    write(os.path.join(out_dir, "sitemap.xml"), sitemap)

    print("Built %d locales into %s" % (len(codes), out_dir))
    print("  pages: / (root) + " + ", ".join("/%s/" % c for c in codes))
    if warnings:
        print("Warnings:")
        print("\n".join(warnings))


def main():
    ap = argparse.ArgumentParser(description="Render the localized live.tips landing pages.")
    ap.add_argument("--out", required=True, help="output directory (e.g. _site)")
    ap.add_argument("--base", default="https://live.tips", help="canonical origin")
    args = ap.parse_args()
    build(args.out, args.base)


if __name__ == "__main__":
    main()
