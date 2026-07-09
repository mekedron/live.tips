#!/usr/bin/env python3
"""Shared plumbing for the two static-site builders.

`build_site.py` renders the localized landing pages and `build_blog.py` renders
the localized blog; both read the same locale registry, fill the same
`{{placeholder}}` templates, and splice in the same `website/i18n/partials/`
chrome. Everything they agree on lives here.
"""
import html
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "website")
I18N = os.path.join(WEB, "i18n")
STRINGS = os.path.join(I18N, "strings")
PARTIALS = os.path.join(I18N, "partials")
TEMPLATES = os.path.join(I18N, "templates")

PLACEHOLDER_RE = re.compile(r"\{\{\s*([\w.\-]+)\s*\}\}")

# `{{> partials/x.html}}` splices a file in verbatim, before any {{key}} is
# substituted — so a partial can carry its own placeholders. `>` is outside
# PLACEHOLDER_RE's character class, so the two passes never see each other's
# tokens. Partials are stored without a trailing newline; the include token's
# own line break supplies it.
INCLUDE_RE = re.compile(r"\{\{>\s*([\w./\-]+)\s*\}\}")


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


def resolve_includes(text, depth=0):
    if depth > 8:
        raise RuntimeError("include nesting too deep — cycle in {{> …}}?")

    def repl(m):
        with open(os.path.join(I18N, m.group(1)), encoding="utf-8") as fh:
            return resolve_includes(fh.read(), depth + 1)
    return INCLUDE_RE.sub(repl, text)


def render(template, subs):
    """Fill {{key}} slots. One non-rescanning pass: a value may contain markup,
    but a `{{key}}` inside a value is left alone — render it before you pass it."""
    def repl(m):
        key = m.group(1)
        if key not in subs:
            raise KeyError("template placeholder {{%s}} has no value" % key)
        return subs[key]
    return PLACEHOLDER_RE.sub(repl, template)


def load_template(name):
    """Read a template (relative to website/i18n/) with its includes expanded."""
    with open(os.path.join(I18N, name), encoding="utf-8") as fh:
        return resolve_includes(fh.read())


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def load_locales():
    """The locale registry: (default_code, locale_dicts, codes, names, flags)."""
    reg = load_json(os.path.join(I18N, "locales.json"))
    locales = reg["locales"]
    codes = [l["code"] for l in locales]
    return (reg["default"], locales, codes,
            {l["code"]: l["name"] for l in locales},
            {l["code"]: l.get("flag", "") for l in locales})


def load_strings(directory, codes, warn_on_missing_file=True):
    """Merge each locale's strings over the English source of truth.

    Returns (all_strings, warnings). A missing key always falls back to English;
    `warn_on_missing_file` controls whether an entirely absent file is worth
    complaining about — it is for the landing (every locale is translated), it
    is not for the blog (most locales start out English-only by design).
    """
    en = load_json(os.path.join(directory, "en.json"))
    label = os.path.basename(directory)
    all_strings, warnings = {}, []
    for code in codes:
        path = os.path.join(directory, "%s.json" % code)
        exists = os.path.exists(path)
        data = load_json(path) if exists else {}
        if not exists:
            if warn_on_missing_file:
                warnings.append("  %s/%s.json missing — English fallback for all keys"
                                % (label, code))
        else:
            missing = [k for k in en if k not in data]
            if missing:
                warnings.append("  %s/%s.json missing %d key(s): %s"
                                % (label, code, len(missing), ", ".join(missing[:8])
                                   + (" …" if len(missing) > 8 else "")))
        merged = dict(en)
        merged.update({k: v for k, v in data.items() if k in en})
        all_strings[code] = merged
    return all_strings, warnings


def font_preloads(loc):
    """Latin-1 always; plus the extra subset this locale's script needs, so its
    glyphs don't wait on lazy discovery. Every page can still render any glyph
    via the @font-face unicode-range rules — this just preloads the common case."""
    def preload(stem):
        return ('<link rel="preload" href="/fonts/%s.woff2" as="font" type="font/woff2" crossorigin>'
                % stem)
    out = [preload("outfit-latin"), preload("notosans-latin")]
    if loc["script"] == "latinext":
        out += [preload("outfit-latinext"), preload("notosans-latinext")]
    elif loc["script"] == "cyrillic":
        out.append(preload("notosans-cyrillic"))
    elif loc["script"] == "greek":
        out.append(preload("notosans-greek"))
    return "\n".join(out)


def sitemap_url(loc, alternates, lastmod=None):
    """One <url> entry carrying its OWN hreflang alternates.

    `alternates` is a list of (hreflang, href) pairs — the blog needs this to be
    per-URL, because a post is only announced in the languages it exists in.
    """
    out = ["  <url>", "    <loc>%s</loc>" % esc(loc)]
    if lastmod:
        out.append("    <lastmod>%s</lastmod>" % lastmod)
    for hreflang, href in alternates:
        out.append('    <xhtml:link rel="alternate" hreflang="%s" href="%s"/>'
                   % (hreflang, esc(href)))
    out.append("  </url>")
    return "\n".join(out)


def sitemap_document(entries):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
            '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
            + "\n".join(entries) + "\n</urlset>\n")
