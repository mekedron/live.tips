#!/usr/bin/env python3
"""Render the localized legal pages (privacy policy, terms of use).

Same shape as the blog, deliberately: one Markdown file per language per
document, rendered into the same chrome as every other page.

    website/legal/privacy/en.md  ->  _site/privacy/index.html
    website/legal/privacy/de.md  ->  _site/de/privacy/index.html
    website/legal/terms/fi.md    ->  _site/fi/terms/index.html

Unlike a blog post, a legal document is NOT allowed to be missing in a language:
the footer links to it from every page, so a gap would be a 404. A missing
translation therefore falls back to the English body (with a loud build warning)
rather than failing the deploy — the page always exists, in every locale, and
its hreflang cluster always names all of them.

Each file carries frontmatter:

    ---
    title: Privacy Policy
    description: <the lede, and the meta description>
    updated: 2026-07-13            # ISO day, feeds <time datetime=…>
    updated_label: Last updated 13 July 2026   # the human string, per language
    ---

The body must not contain an `<h1>`: the template supplies the one and only h1
from `title`, and scripts/check_site.py enforces exactly one per page.

Called by build_site.py, which owns the locale registry and merges the sitemap.
"""
import os

import markdown

from build_blog import MD_EXTENSIONS, BuildError, parse_frontmatter
from site_common import (WEB, esc, font_preloads, js_literal, legal_path, load_template,
                         render, sitemap_url, write)

LEGAL = os.path.join(WEB, "legal")

# The documents, in footer order. `slug` is the URL segment; `other` names the
# sibling document the page's footer link points at, so the two are always one
# click apart.
DOCS = [
    {"name": "privacy", "slug": "privacy", "other": "terms"},
    {"name": "terms", "slug": "terms", "other": "privacy"},
]

REQUIRED_FM = ("title", "description", "updated", "updated_label")


def load_doc(name, codes, default):
    """Every language of one document. English is the source of truth and must exist."""
    langs, warnings = {}, []
    for code in codes:
        path = os.path.join(LEGAL, name, "%s.md" % code)
        if not os.path.exists(path):
            if code == default:
                raise BuildError("legal/%s: %s.md is required — it is the source of truth"
                                 % (name, default))
            warnings.append("  legal/%s/%s.md missing — serving the English text there"
                            % (name, code))
            continue
        with open(path, encoding="utf-8") as fh:
            fm, body = parse_frontmatter(fh.read(), "legal/%s/%s.md" % (name, code))
        for key in REQUIRED_FM:
            if key not in fm:
                raise BuildError("legal/%s/%s.md: frontmatter is missing `%s`"
                                 % (name, code, key))
        langs[code] = (fm, body)
    return langs, warnings


def build(out_dir, base, ctx):
    """Render every document in every locale. Returns (sitemap_urls, warnings, count)."""
    default, locales, codes = ctx["default"], ctx["locales"], ctx["codes"]
    names, flags = ctx["names"], ctx["flags"]
    template = load_template("templates/legal.html")

    docs = {}
    warnings = []
    for spec in DOCS:
        docs[spec["name"]], warn = load_doc(spec["name"], codes, default)
        warnings += warn

    def abs_url(slug, code):
        return base + legal_path(slug, code, default)

    urls_out, pages = [], 0
    for spec in DOCS:
        slug, langs = spec["slug"], docs[spec["name"]]
        other = next(d for d in DOCS if d["name"] == spec["other"])

        # Every locale has a page for every document, so the cluster is the full
        # set — unlike a blog post, which is only announced where it exists.
        hreflang = ['<link rel="alternate" hreflang="x-default" href="%s">' % abs_url(slug, default)]
        hreflang += ['<link rel="alternate" hreflang="%s" href="%s">' % (c, abs_url(slug, c))
                     for c in codes]
        hreflang_links = "\n".join(hreflang)
        alternates = ([("x-default", abs_url(slug, default))]
                      + [(c, abs_url(slug, c)) for c in codes])

        for code in codes:
            s = ctx["site_strings"][code]
            loc = next(l for l in locales if l["code"] == code)
            fm, body = langs.get(code, langs[default])

            # A fresh parser per page: markdown.Markdown is stateful across calls.
            html_body = markdown.Markdown(extensions=MD_EXTENSIONS).convert(body)

            # The language switcher keeps you on the SAME document, not the home
            # page — someone reading the privacy policy in English who switches to
            # Suomi wants the privacy policy in Suomi.
            alt_urls = {c: legal_path(slug, c, default) for c in codes}
            other_label = ctx["site_strings"][code][
                "foot_terms" if other["name"] == "terms" else "foot_privacy"]

            subs = {k: esc(v) for k, v in s.items()}
            subs.update({
                "logo_href": "/" if code == default else "/%s/" % code,
                "nav_links": "",
                "app_href": "/app/?lang=%s" % code,
                "blog_href": "/blog/" if code == default else "/%s/blog/" % code,
                "privacy_href": legal_path("privacy", code, default),
                "terms_href": legal_path("terms", code, default),
                "gh_stars_badge": ctx["gh_stars_badge"],
                "html_lang": code,
                "canonical_url": abs_url(slug, code),
                "og_url": abs_url(slug, code),
                "og_image": base + "/og-image.png",
                "og_locale": loc["og_locale"],
                "og_locale_alternates": "\n".join(
                    '<meta property="og:locale:alternate" content="%s">' % l["og_locale"]
                    for l in locales if l["code"] != code),
                "hreflang_links": hreflang_links,
                "font_preloads": font_preloads(loc),
                "lang_switcher_options": "".join(
                    '<option value="%s"%s>%s</option>'
                    % (esc(alt_urls[c]), " selected" if c == code else "",
                       esc(("%s %s" % (flags[c], names[c])).strip()))
                    for c in codes),
                "current_flag": esc(flags[code]),
                "i18n_js": js_literal({"theme": s["theme"]}),
                "locales_js": ctx["locales_js"],
                "alt_urls_js": js_literal(alt_urls),
                "code": code,
                "title_suffix": " — live.tips",
                "doc_title": esc(fm["title"]),
                "doc_lede": esc(fm["description"]),
                "meta_description": esc(fm["description"]),
                "updated_iso": esc(fm["updated"]),
                "updated_html": esc(fm["updated_label"]),
                "doc_body": html_body,
                "other_doc_href": legal_path(other["slug"], code, default),
                "other_doc_label": esc(other_label),
            })

            rel = legal_path(slug, code, default).strip("/")
            write(os.path.join(out_dir, rel, "index.html"), render(template, subs))
            urls_out.append(sitemap_url(abs_url(slug, code), alternates,
                                        lastmod=fm["updated"]))
            pages += 1

    return urls_out, warnings, pages
