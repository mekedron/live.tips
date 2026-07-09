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

It then hands off to `build_blog.py`, which renders the localized Markdown blog
into the same tree, and merges both sets of URLs into one `sitemap.xml` (each
entry carrying its own hreflang alternates). Static assets from `website/`
(fonts, icons, og-image, robots.txt) are copied across. Every page gets a full
hreflang cluster, a per-locale <select> switcher, and the embedded data the
cross-language banner needs — all derived here, so adding a language is just a
new strings/<code>.json plus an entry in locales.json.

Shared plumbing (template engine, partial includes, locale loading, sitemap
emission) lives in `site_common.py`.

Usage (also run verbatim by .github/workflows/pages.yml):
    python3 scripts/build_site.py --out _site
    python3 scripts/build_site.py --out /tmp/lt-site --base https://live.tips
"""
import argparse
import os
import shutil
import sys

import build_blog
from site_common import (STRINGS, WEB, esc, font_preloads, home_path, js_literal,
                         load_locales, load_strings, load_template, loc_url,
                         render, sitemap_document, sitemap_url, write)

# Values that legitimately contain inline markup (<br>, <em>, <strong>) and so
# are injected verbatim; every other string is HTML-escaped.
HTML_KEYS = {"hero_h1", "hero_sub", "stage_caption", "cta_h2"}

# Runtime strings handed to the page's JS (see the chrome partial's `var I18N = …`).
JS_KEYS = ("goal_tmpl", "tip_tmpl", "theme")

# The demo HUD's initial numbers, matching the renderer boot state in the
# template's script, so localized static text doesn't flash then change.
INIT = {"total": "$436.00", "done": "$436", "goal": "$1,000", "pct": "44",
        "name": "Anna S.", "amount": "$5.00"}


def build(out_dir, base):
    base = base.rstrip("/")
    template = load_template("template.html")
    default, locales, codes, names, flags = load_locales()

    # Load every locale's strings up front (English-filled for any gaps) so the
    # banner table can carry each language's own invitation phrase.
    all_strings, warnings = load_strings(STRINGS, codes)

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
        # The header partial is shared with the blog, which anchors its logo at
        # the locale home and carries a different nav. `nav_links` is rendered
        # here rather than left as nested placeholders because the substitution
        # is a single non-rescanning pass.
        nav_links = ('<nav class="main">\n'
                     '      <a href="#jar">%s</a>\n'
                     '      <a href="#how">%s</a>\n'
                     '      <a href="#security">%s</a>\n'
                     '    </nav>' % (esc(s["nav_jar"]), esc(s["nav_how"]), esc(s["nav_security"])))

        subs.update({
            "logo_href": "#top",
            "nav_links": nav_links,
            "html_lang": code,
            # Carry the page's language into the app so it opens in the same
            # language the visitor is reading the landing page in.
            "app_href": "/app/?lang=%s" % code,
            "canonical_url": canon,
            "og_url": canon,
            "og_locale": loc["og_locale"],
            "og_locale_alternates": alts,
            "hreflang_links": hreflang_links,
            "font_preloads": font_preloads(loc),
            "lang_switcher_options": "".join(opts),
            "current_flag": esc(flags[code]),
            "i18n_js": js_literal({k: s[k] for k in JS_KEYS}),
            "locales_js": locales_js,
            # The landing's per-locale twin is always the locale home, which the
            # banner already derives; only the blog needs an override table.
            "alt_urls_js": "{}",
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

    # Static assets: everything under website/ except the i18n sources, the blog's
    # Markdown sources (build_blog.py renders those, and copying them here would
    # shadow the rendered tree), the internal README, and the files this build
    # (re)generates.
    skip = {"i18n", "blog", "README.md", "index.html", "sitemap.xml"}
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

    # The blog renders into the same tree and returns its own sitemap entries.
    # It reuses this build's locale registry and landing strings — the blog pages
    # wear the same header, footer and banner, whose copy lives in strings/.
    blog_urls, blog_warnings, blog_stats = build_blog.build(out_dir, base, {
        "default": default, "locales": locales, "codes": codes,
        "names": names, "flags": flags, "locales_js": locales_js,
        "site_strings": all_strings,
    })
    warnings += blog_warnings

    # Sitemap: root + each /code/ (the /en/ alias and disallowed /app/, /stage/
    # are deliberately absent), every landing entry carrying the full hreflang
    # set. Blog entries bring their own — a post is only announced in the
    # languages it has actually been translated into.
    landing_alts = [("x-default", base + "/")]
    landing_alts += [(c, loc_url(base, c, default)) for c in codes]
    urls = [sitemap_url(loc_url(base, c, default), landing_alts) for c in codes]
    write(os.path.join(out_dir, "sitemap.xml"), sitemap_document(urls + blog_urls))

    print("Built %d locales into %s" % (len(codes), out_dir))
    print("  pages: / (root) + " + ", ".join("/%s/" % c for c in codes))
    print("  blog:  %d post(s), %d translation(s), %d page(s), %d feed(s)"
          % (blog_stats["posts"], blog_stats["translations"],
             blog_stats["pages"], blog_stats["feeds"]))
    if warnings:
        print("Warnings:")
        print("\n".join(warnings))


def main():
    ap = argparse.ArgumentParser(description="Render the localized live.tips landing pages.")
    ap.add_argument("--out", required=True, help="output directory (e.g. _site)")
    ap.add_argument("--base", default="https://live.tips", help="canonical origin")
    args = ap.parse_args()
    try:
        build(args.out, args.base)
    except build_blog.BuildError as e:
        # A mistake in someone's Markdown, not a crash. Say what to fix, and
        # don't bury it under a traceback nobody needs.
        sys.exit("Blog content error — %s" % e)


if __name__ == "__main__":
    main()
