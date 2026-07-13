#!/usr/bin/env python3
"""Render the localized blog from Markdown.

Called by `build_site.py` (never on its own) so both share one locale registry
and one sitemap. Sources live in `website/blog/posts/<dir>/`:

    post.json      shared metadata: date, updated?, cover?, cover_alt?, tags?, draft?
    en.md          REQUIRED — the fallback every untranslated locale links to
    de.md, ru.md   optional translations; a post exists in the languages it has
    assets/        images, copied once and referenced from every language

Output, mirroring the landing's URL scheme (English at the root, others under
/<code>/):

    _site/blog/index.html                  /blog/            English index
    _site/de/blog/index.html               /de/blog/         German index
    _site/blog/<slug>/index.html           /blog/<slug>/     English post
    _site/de/blog/<de-slug>/index.html                       German post
    _site/blog/<slug>.md                   raw Markdown sibling, for LLMs/agents
    _site/blog/feed.xml, _site/de/blog/feed.xml              Atom, per locale

Two rules carry the whole design:

  * **A post is only published in the languages it was actually written in.**
    An English body is never served under /de/blog/…, so there is no duplicate
    content and no lying `lang` attribute. A locale's index still *lists* every
    post — an untranslated one shows its English title, an "In English" badge,
    and links straight to the English URL.

  * **Every page canonicalizes to itself**, and its hreflang cluster names only
    the locales that post exists in (plus x-default → English). Translations are
    not duplicates of each other; pointing a translation's canonical at the
    English post would deindex it *and* void the whole hreflang cluster.
"""
import json
import math
import os
import re
import shutil

import markdown

from site_common import (I18N, WEB, esc, font_preloads, js_literal, legal_path,
                         load_strings, load_template, render, sitemap_url, write)

BLOG = os.path.join(WEB, "blog")
POSTS = os.path.join(BLOG, "posts")
BLOG_STRINGS = os.path.join(I18N, "blog_strings")

# `extra` bundles fenced_code, tables, footnotes, attr_list, def_list and
# md_in_html — everything prose needs. `toc` gives headings stable ids so they
# can be deep-linked. Deliberately absent: `codehilite` (drags in Pygments and
# emits inline-styled span soup) and `smarty` (its curly quotes are wrong for
# German „…" and French « … » — authors type the right marks themselves).
MD_EXTENSIONS = ["extra", "sane_lists", "toc"]

WORDS_PER_MINUTE = 200

# Inline Markdown link/image targets: `](target)` and `](target "title")`. Only
# the inline form — reference links (`[a][b]`) and autolinks (`<https://…>`) are
# left alone, so `assets/` and `post:` must be written inline. Nothing else in a
# post needs rewriting, and a real Markdown AST walk to catch the other two forms
# would cost a treeprocessor for no gain.
LINK_TARGET_RE = re.compile(r'(?<=\]\()([^)\s]+)((?:\s+"[^"]*")?\))')

FRONTMATTER_FENCE = "---"


class BuildError(Exception):
    """A content mistake the author must fix; fails the build rather than
    quietly publishing a broken page."""


# --------------------------------------------------------------------------
# parsing
# --------------------------------------------------------------------------

def parse_frontmatter(text, where):
    """Split a `---` fenced block of flat `key: value` lines off the top.

    Deliberately not YAML: the keys are a closed set of strings, and a real YAML
    parser would coerce `slug: no` to a boolean (the Norway problem) and drag in
    a dependency for the privilege.
    """
    lines = text.replace("\r\n", "\n").split("\n")
    if not lines or lines[0].strip() != FRONTMATTER_FENCE:
        raise BuildError("%s: must open with a '---' frontmatter fence" % where)
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == FRONTMATTER_FENCE)
    except StopIteration:
        raise BuildError("%s: frontmatter fence is never closed" % where)

    meta = {}
    for n, line in enumerate(lines[1:end], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, sep, value = line.partition(":")
        if not sep:
            raise BuildError("%s:%d: frontmatter line is not `key: value`: %r"
                             % (where, n, line))
        meta[key.strip()] = value.strip()
    return meta, "\n".join(lines[end + 1:]).lstrip("\n")


def reading_minutes(body):
    return max(1, math.ceil(len(re.findall(r"\w+", body, re.UNICODE)) / WORDS_PER_MINUTE))


# --------------------------------------------------------------------------
# model
# --------------------------------------------------------------------------

class Translation:
    def __init__(self, lang, meta, body, where):
        for key in ("title", "description"):
            if not meta.get(key):
                raise BuildError("%s: frontmatter is missing `%s`" % (where, key))
        self.lang = lang
        self.title = meta["title"]
        self.description = meta["description"]
        self.slug = meta.get("slug")           # None → inherit the directory name
        self.updated = meta.get("updated")     # None → fall back to post.json
        self.body = body
        self.minutes = reading_minutes(body)


class Post:
    def __init__(self, name, meta, translations):
        self.name = name
        self.meta = meta
        self.tr = translations                 # {lang: Translation}
        self.date = meta["date"]
        self.tags = meta.get("tags", [])
        self.cover = meta.get("cover")
        self.cover_alt = meta.get("cover_alt", "")

    def slug(self, lang):
        return self.tr[lang].slug or self.name

    def lastmod(self, lang):
        return (self.tr[lang].updated or self.meta.get("updated") or self.date)

    def has(self, lang):
        return lang in self.tr


def load_posts():
    """Returns (published_posts, draft_names).

    Drafts are named, not just skipped, so a `post:` link into one can say so
    instead of claiming the post does not exist.
    """
    if not os.path.isdir(POSTS):
        return [], set()
    posts, drafts = [], set()
    for name in sorted(os.listdir(POSTS)):
        d = os.path.join(POSTS, name)
        if not os.path.isdir(d) or name.startswith("."):
            continue
        meta_path = os.path.join(d, "post.json")
        if not os.path.exists(meta_path):
            raise BuildError("blog/posts/%s: no post.json" % name)
        with open(meta_path, encoding="utf-8") as fh:
            meta = json.load(fh)
        if meta.get("draft"):
            drafts.add(name)                   # no page, no index card, no feed, no sitemap URL
            continue
        if not meta.get("date"):
            raise BuildError("blog/posts/%s/post.json: `date` is required" % name)

        translations = {}
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".md"):
                continue
            lang = fn[:-3]
            where = "blog/posts/%s/%s" % (name, fn)
            with open(os.path.join(d, fn), encoding="utf-8") as fh:
                fm, body = parse_frontmatter(fh.read(), where)
            translations[lang] = Translation(lang, fm, body, where)

        if "en" not in translations:
            raise BuildError(
                "blog/posts/%s: en.md is required — every untranslated locale "
                "links its readers to the English post." % name)
        posts.append(Post(name, meta, translations))

    # Newest first; `order` breaks a same-day tie, then the directory name so the
    # build is deterministic.
    posts.sort(key=lambda p: (p.date, p.meta.get("order", 0), p.name), reverse=True)
    return posts, drafts


def check_slugs(posts, codes):
    """Two posts resolving to the same URL in some language would silently
    overwrite each other's directory. Catch it at build time."""
    for lang in codes:
        seen = {}
        for post in posts:
            if not post.has(lang):
                continue
            slug = post.slug(lang)
            if slug in seen:
                raise BuildError("blog: posts %r and %r both resolve to slug %r in %s"
                                 % (seen[slug], post.name, slug, lang))
            seen[slug] = post.name


# --------------------------------------------------------------------------
# URLs
# --------------------------------------------------------------------------

class Urls:
    """Every blog URL, in one place. `path` is root-relative (for the page's own
    markup); `abs` is fully qualified (for canonical, og:url, sitemap, feeds)."""

    def __init__(self, base, default):
        self.base = base.rstrip("/")
        self.default = default

    def index(self, lang):
        return "/blog/" if lang == self.default else "/%s/blog/" % lang

    def post(self, lang, slug):
        return ("/blog/%s/" % slug if lang == self.default
                else "/%s/blog/%s/" % (lang, slug))

    def post_md(self, lang, slug):
        return self.post(lang, slug).rstrip("/") + ".md"

    def feed(self, lang):
        return self.index(lang) + "feed.xml"

    def assets(self, en_slug):
        """One copy of the images, addressed from every language."""
        return "/blog/%s/assets/" % en_slug

    def abs(self, path):
        return self.base + path


# --------------------------------------------------------------------------
# Markdown → HTML / Markdown → Markdown
# --------------------------------------------------------------------------

def rewrite_targets(md_text, resolve):
    """Rewrite every inline link/image target through `resolve`."""
    return LINK_TARGET_RE.sub(lambda m: resolve(m.group(1)) + m.group(2), md_text)


def make_resolver(post, lang, posts_by_name, urls, absolute, drafts=frozenset()):
    """Resolve the two target forms the build owns, pass everything else through.

    `assets/x.jpg`   → the post's single shared asset directory
    `post:<dir>`     → that post in THIS language if it exists, else in English.
                       Authors must use `post:` for cross-links because slugs
                       differ per language, so a hard-coded URL cannot be right
                       in every translation.
    """
    def full(path):
        return urls.abs(path) if absolute else path

    def resolve(target):
        if target.startswith("assets/"):
            return full(urls.assets(post.slug("en")) + target[len("assets/"):])
        if target.startswith("post:"):
            name = target[len("post:"):]
            other = posts_by_name.get(name)
            if other is None:
                # A published post linking to a draft would ship a 404. Fail the
                # build, and say which of the two problems it actually is.
                if name in drafts:
                    raise BuildError(
                        "blog/posts/%s/%s.md links to %r, which is still a draft — "
                        "publish it or drop the link." % (post.name, lang, name))
                raise BuildError("blog/posts/%s/%s.md: link to unknown post %r"
                                 % (post.name, lang, name))
            tongue = lang if other.has(lang) else "en"
            return full(urls.post(tongue, other.slug(tongue)))
        if absolute and target.startswith("/"):
            # A .md sibling is fetched on its own, with no page to be relative to.
            return urls.abs(target)
        return target
    return resolve


def render_body(post, lang, posts_by_name, urls, drafts):
    md = markdown.Markdown(extensions=MD_EXTENSIONS)
    source = rewrite_targets(post.tr[lang].body,
                             make_resolver(post, lang, posts_by_name, urls, False, drafts))
    return md.convert(source)


def render_markdown_sibling(post, lang, posts_by_name, urls, drafts):
    """The raw-Markdown twin an LLM or agent can read without parsing our HTML.

    Frontmatter is replaced by a human/machine-readable header, and every link
    is made fully qualified so the file stands alone once fetched.
    """
    tr = post.tr[lang]
    body = rewrite_targets(tr.body,
                           make_resolver(post, lang, posts_by_name, urls, True, drafts))
    head = ["# %s" % tr.title, "", "> %s" % tr.description, "",
            "Canonical: %s" % urls.abs(urls.post(lang, post.slug(lang))),
            "Published: %s" % post.date]
    if post.lastmod(lang) != post.date:
        head.append("Updated: %s" % post.lastmod(lang))
    head.append("Language: %s" % lang)
    if post.tags:
        head.append("Tags: %s" % ", ".join(post.tags))
    head += ["", "---", "", body]
    return "\n".join(head).rstrip() + "\n"


# --------------------------------------------------------------------------
# page fragments
# --------------------------------------------------------------------------

def rfc3339(day):
    """Atom demands a full timestamp; our dates are day-resolution."""
    return "%sT00:00:00Z" % day


def post_alternates(post, urls, codes):
    """Only the languages this post exists in, plus x-default → English. A locale
    that merely *lists* the post (linking to English) is not an alternate of it."""
    pairs = [("x-default", urls.abs(urls.post("en", post.slug("en"))))]
    pairs += [(c, urls.abs(urls.post(c, post.slug(c)))) for c in codes if post.has(c)]
    return pairs


def cover_url(post, urls, absolute=True):
    if not post.cover:
        return None
    rel = post.cover
    if rel.startswith("assets/"):
        rel = urls.assets(post.slug("en")) + rel[len("assets/"):]
    return urls.abs(rel) if absolute else rel


def post_card(post, lang, urls, bs):
    """One card on a locale's index.

    When the post has no translation for `lang`, the card shows the English
    title, is marked up `lang="en"` for screen readers and crawlers, and links
    to the English post — we never fabricate a localized URL for a body that
    does not exist.
    """
    localized = post.has(lang)
    tongue = lang if localized else "en"
    tr = post.tr[tongue]
    href = urls.post(tongue, post.slug(tongue))

    media = ""
    cover = cover_url(post, urls, absolute=False)
    if cover:
        media = ('    <div class="post-card-media">'
                 '<img src="%s" alt="%s" loading="lazy" decoding="async"></div>\n'
                 % (esc(cover), esc(post.cover_alt)))

    badge = ("" if localized else
             '<span class="post-badge">%s</span>' % esc(bs["english_badge"]))
    foreign = "" if localized else ' lang="en" hreflang="en"'

    return (
        '  <a class="post-card" href="%s"%s>\n'
        '%s'
        '    <div class="post-card-body">\n'
        '      <div class="post-meta"><time datetime="%s">%s</time>'
        '<span class="post-meta-dot">·</span><span>%s</span>%s</div>\n'
        '      <h2 class="post-card-title">%s</h2>\n'
        '      <p class="post-card-desc">%s</p>\n'
        '      <span class="post-card-more">%s</span>\n'
        '    </div>\n'
        '  </a>' % (
            esc(href), foreign, media,
            post.date, post.date,
            esc(bs["reading_time_tmpl"].replace("{min}", str(tr.minutes))), badge,
            esc(tr.title), esc(tr.description), esc(bs["read_more"])))


def breadcrumbs(urls, lang, bs, trail):
    """trail: [(name, url), …] after Home."""
    items = [{"@type": "ListItem", "position": 1, "name": bs["breadcrumb_home"],
              "item": urls.abs("/" if lang == urls.default else "/%s/" % lang)}]
    for i, (name, url) in enumerate(trail, start=2):
        items.append({"@type": "ListItem", "position": i, "name": name, "item": url})
    return {"@context": "https://schema.org", "@type": "BreadcrumbList",
            "itemListElement": items}


PUBLISHER = {
    "@type": "Organization",
    "name": "live.tips",
    "url": "https://live.tips/",
    "logo": {"@type": "ImageObject", "url": "https://live.tips/apple-touch-icon.png"},
}


def blogposting_ld(post, lang, urls, og_image):
    tr = post.tr[lang]
    url = urls.abs(urls.post(lang, post.slug(lang)))
    return {
        "@type": "BlogPosting",
        "headline": tr.title,
        "description": tr.description,
        "url": url,
        "mainEntityOfPage": {"@type": "WebPage", "@id": url},
        "datePublished": post.date,
        "dateModified": post.lastmod(lang),
        "inLanguage": lang,
        "image": og_image,
        "keywords": ", ".join(post.tags) if post.tags else None,
        "author": PUBLISHER,
        "publisher": PUBLISHER,
    }


def prune(obj):
    """Drop null-valued keys so the JSON-LD has no empty properties."""
    if isinstance(obj, dict):
        return {k: prune(v) for k, v in obj.items() if v is not None}
    if isinstance(obj, list):
        return [prune(v) for v in obj]
    return obj


# --------------------------------------------------------------------------
# feeds
# --------------------------------------------------------------------------

def atom_feed(posts, lang, urls, bs):
    """One entry per post, mirroring the locale's index: an untranslated post
    appears with its English title and URL, tagged xml:lang="en", so a sparse
    locale still gets the whole catalogue instead of an empty feed."""
    self_url = urls.abs(urls.feed(lang))
    index_url = urls.abs(urls.index(lang))
    updated = max((p.lastmod(lang if p.has(lang) else "en") for p in posts),
                  default=None)

    out = ['<?xml version="1.0" encoding="utf-8"?>',
           '<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="%s">' % lang,
           '  <title>%s</title>' % esc(bs["feed_title"]),
           '  <subtitle>%s</subtitle>' % esc(bs["blog_index_description"]),
           '  <link rel="self" href="%s"/>' % esc(self_url),
           '  <link rel="alternate" type="text/html" href="%s"/>' % esc(index_url),
           '  <id>%s</id>' % esc(index_url)]
    if updated:
        out.append('  <updated>%s</updated>' % rfc3339(updated))
    out.append('  <author><name>live.tips</name></author>')

    for post in posts:
        tongue = lang if post.has(lang) else "en"
        tr = post.tr[tongue]
        url = urls.abs(urls.post(tongue, post.slug(tongue)))
        out += ['  <entry xml:lang="%s">' % tongue,
                '    <title>%s</title>' % esc(tr.title),
                '    <link rel="alternate" type="text/html" href="%s"/>' % esc(url),
                '    <id>%s</id>' % esc(url),
                '    <published>%s</published>' % rfc3339(post.date),
                '    <updated>%s</updated>' % rfc3339(post.lastmod(tongue)),
                '    <summary>%s</summary>' % esc(tr.description),
                '  </entry>']
    out.append('</feed>')
    return "\n".join(out) + "\n"


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------

def build(out_dir, base, ctx):
    """Render every locale's blog into `out_dir`.

    Returns (sitemap_entries, warnings, stats). `.md` siblings are deliberately
    absent from the sitemap: they are an alternate representation of a page, not
    a page, and are advertised with <link rel="alternate" type="text/markdown">.
    """
    default, codes = ctx["default"], ctx["codes"]
    locales, names, flags = ctx["locales"], ctx["names"], ctx["flags"]
    urls = Urls(base, default)

    posts, drafts = load_posts()
    check_slugs(posts, codes)
    posts_by_name = {p.name: p for p in posts}

    # Most locales start with no blog translation at all — that is the design,
    # not a mistake, so an absent file is silent. A half-filled one is not.
    blog_strings, warnings = load_strings(BLOG_STRINGS, codes, warn_on_missing_file=False)

    index_tpl = load_template("templates/blog_index.html")
    post_tpl = load_template("templates/blog_post.html")

    sitemap_entries = []
    stats = {"posts": len(posts), "translations": 0, "pages": 0, "feeds": 0}

    # Images live once, under the English slug, and are addressed absolutely from
    # every translation — so /de/blog/<de-slug>/ and /blog/<en-slug>/ share bytes.
    for post in posts:
        src = os.path.join(POSTS, post.name, "assets")
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(out_dir, "blog", post.slug("en"), "assets"),
                            dirs_exist_ok=True)

    def chrome(lang, alt_urls):
        """The slots the shared header/footer/langbar/chrome.js partials need."""
        s = ctx["site_strings"][lang]
        subs = {k: esc(v) for k, v in s.items()}
        subs.update({
            "logo_href": "/" if lang == default else "/%s/" % lang,
            "app_href": "/app/?lang=%s" % lang,
            "blog_href": urls.index(lang),
            # The footer is shared with the landing and the legal pages, so every
            # builder has to fill its slots — a missing one is a hard KeyError.
            "privacy_href": legal_path("privacy", lang, default),
            "terms_href": legal_path("terms", lang, default),
            "gh_stars_badge": ctx["gh_stars_badge"],
            "html_lang": lang,
            "lang_switcher_options": "".join(
                '<option value="%s"%s>%s</option>'
                % (esc(alt_urls.get(c, urls.index(c))), " selected" if c == lang else "",
                   esc(("%s %s" % (flags[c], names[c])).strip()))
                for c in codes),
            "current_flag": esc(flags[lang]),
            "i18n_js": js_literal({"theme": s["theme"]}),
            "locales_js": ctx["locales_js"],
            # Send a language-switching reader to the same *content*, not the
            # locale home: the twin of this post, or that locale's blog index.
            "alt_urls_js": js_literal(alt_urls),
            "code": lang,
        })
        return subs

    def head(lang, bs):
        loc = next(l for l in locales if l["code"] == lang)
        return {
            "og_locale": loc["og_locale"],
            "og_locale_alternates": "\n".join(
                '<meta property="og:locale:alternate" content="%s">' % l["og_locale"]
                for l in locales if l["code"] != lang),
            "font_preloads": font_preloads(loc),
            "feed_url": urls.feed(lang),
            "nav_links": '<nav class="main">\n      <a href="%s">%s</a>\n    </nav>'
                         % (esc(urls.index(lang)), esc(bs["breadcrumb_blog"])),
        }

    # ---- per-locale index -------------------------------------------------
    index_alts = [("x-default", urls.abs(urls.index("en")))]
    index_alts += [(c, urls.abs(urls.index(c))) for c in codes]
    index_hreflang = "\n".join('<link rel="alternate" hreflang="%s" href="%s">' % (h, u)
                               for h, u in index_alts)

    for lang in codes:
        bs = blog_strings[lang]
        alt_urls = {c: urls.index(c) for c in codes}
        subs = chrome(lang, alt_urls)
        subs.update({k: esc(v) for k, v in bs.items()})
        subs.update(head(lang, bs))

        cards = "\n".join(post_card(p, lang, urls, bs) for p in posts)
        canonical = urls.abs(urls.index(lang))
        ld = [prune({"@context": "https://schema.org", "@type": "Blog",
                     "name": bs["blog_index_title"],
                     "description": bs["blog_index_description"],
                     "url": canonical, "inLanguage": lang, "publisher": PUBLISHER,
                     "blogPost": [prune(blogposting_ld(
                         p, lang if p.has(lang) else "en", urls,
                         cover_url(p, urls) or urls.abs("/og-image.png"))) for p in posts]}),
              prune(breadcrumbs(urls, lang, bs, [(bs["breadcrumb_blog"], canonical)]))]

        subs.update({
            "canonical_url": canonical,
            "og_url": canonical,
            "hreflang_links": index_hreflang,
            "og_image": urls.abs("/og-image.png"),
            "post_cards": cards or ('  <p class="blog-empty">%s</p>' % esc(bs["empty_state"])),
            "jsonld": js_literal(ld),
        })
        rel = "blog/index.html" if lang == default else "%s/blog/index.html" % lang
        write(os.path.join(out_dir, rel), render(index_tpl, subs))
        stats["pages"] += 1

        write(os.path.join(out_dir, urls.feed(lang).lstrip("/")),
              atom_feed(posts, lang, urls, bs))
        stats["feeds"] += 1

        sitemap_entries.append(sitemap_url(canonical, index_alts))

    # ---- per-post pages ---------------------------------------------------
    for post in posts:
        og_image = cover_url(post, urls) or urls.abs("/og-image.png")
        for lang in codes:
            if not post.has(lang):
                continue                        # never serve an English body under /xx/
            stats["translations"] += 1
            tr = post.tr[lang]
            bs = blog_strings[lang]
            slug = post.slug(lang)
            canonical = urls.abs(urls.post(lang, slug))

            # A reader switching language goes to this post's twin when it
            # exists, otherwise to that locale's blog index — never to a 404.
            alt_urls = {c: (urls.post(c, post.slug(c)) if post.has(c) else urls.index(c))
                        for c in codes}
            subs = chrome(lang, alt_urls)
            subs.update({k: esc(v) for k, v in bs.items()})
            subs.update(head(lang, bs))

            ld = [prune(dict(blogposting_ld(post, lang, urls, og_image),
                             **{"@context": "https://schema.org"})),
                  prune(breadcrumbs(urls, lang, bs, [
                      (bs["breadcrumb_blog"], urls.abs(urls.index(lang))),
                      (tr.title, canonical)]))]

            cover_html = ""
            cover = cover_url(post, urls, absolute=False)
            if cover:
                cover_html = ('<figure class="post-cover"><img src="%s" alt="%s" '
                              'fetchpriority="high" decoding="async"></figure>'
                              % (esc(cover), esc(post.cover_alt)))

            tags_html = ""
            if post.tags:
                tags_html = ('<div class="post-tags" aria-label="%s">%s</div>'
                             % (esc(bs["tags_label"]),
                                "".join('<span class="post-tag">%s</span>' % esc(t)
                                        for t in post.tags)))

            updated_html = ""
            if post.lastmod(lang) != post.date:
                updated_html = ('<span class="post-meta-dot">·</span><span>%s</span>'
                                % esc(bs["updated_on"].replace("{date}", post.lastmod(lang))))

            subs.update({
                "title": esc(tr.title),
                "meta_description": esc(tr.description),
                "canonical_url": canonical,
                "og_url": canonical,
                "og_image": og_image,
                "og_image_alt": esc(post.cover_alt or tr.title),
                "hreflang_links": "\n".join(
                    '<link rel="alternate" hreflang="%s" href="%s">' % (h, u)
                    for h, u in post_alternates(post, urls, codes)),
                "markdown_url": urls.post_md(lang, slug),
                "published_iso": post.date,
                "modified_iso": post.lastmod(lang),
                "published_html": esc(bs["published_on"].replace("{date}", post.date)),
                "updated_html": updated_html,
                "reading_time": esc(bs["reading_time_tmpl"].replace("{min}", str(tr.minutes))),
                "post_title": esc(tr.title),
                "post_description": esc(tr.description),
                "post_cover": cover_html,
                "post_tags": tags_html,
                "post_body": render_body(post, lang, posts_by_name, urls, drafts),
                "blog_url": urls.index(lang),
                "jsonld": js_literal(ld),
            })

            write(os.path.join(out_dir, urls.post(lang, slug).strip("/"), "index.html"),
                  render(post_tpl, subs))
            write(os.path.join(out_dir, urls.post_md(lang, slug).lstrip("/")),
                  render_markdown_sibling(post, lang, posts_by_name, urls, drafts))
            stats["pages"] += 1

        sitemap_entries.append(sitemap_url(
            urls.abs(urls.post("en", post.slug("en"))),
            post_alternates(post, urls, codes),
            lastmod=post.lastmod("en")))
        for lang in codes:
            if lang == "en" or not post.has(lang):
                continue
            sitemap_entries.append(sitemap_url(
                urls.abs(urls.post(lang, post.slug(lang))),
                post_alternates(post, urls, codes),
                lastmod=post.lastmod(lang)))

    return sitemap_entries, warnings, stats
