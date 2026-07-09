#!/usr/bin/env python3
"""Post-build gate over the rendered site.

The failures this catches are the ones you cannot see by looking at the page: a
canonical that points somewhere else, an hreflang naming a URL that was never
written, a sitemap advertising a 404. They cost weeks of traffic and surface
only in Search Console, long after the deploy that caused them.

Nothing here is a style opinion; every check is an invariant the build promises.

    python3 scripts/check_site.py _site
    python3 scripts/check_site.py _site --base https://live.tips
"""
import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

CANONICAL_RE = re.compile(r'<link rel="canonical" href="([^"]+)"')
HREFLANG_RE = re.compile(r'<link rel="alternate" hreflang="([^"]+)" href="([^"]+)"')
MARKDOWN_RE = re.compile(r'<link rel="alternate" type="text/markdown" href="([^"]+)"')
JSONLD_RE = re.compile(r'<script type="application/ld\+json">\n(.*?)\n</script>', re.S)
H1_RE = re.compile(r"<h1[ >]")
LANG_RE = re.compile(r'<html lang="([^"]+)"')

SITEMAP_NS = "{http://www.sitemaps.org/schemas/sitemap/0.9}"
XHTML_NS = "{http://www.w3.org/1999/xhtml}"
ATOM_NS = "{http://www.w3.org/2005/Atom}"


class Checker:
    def __init__(self, out_dir, base):
        self.out = out_dir
        self.base = base.rstrip("/")
        self.errors = []
        self.checked = 0

    def fail(self, where, msg):
        self.errors.append("%s: %s" % (where, msg))

    def url_to_path(self, url):
        """Map a site URL back to the file that must serve it."""
        if not url.startswith(self.base):
            return None
        rel = url[len(self.base):].lstrip("/")
        if rel == "" or rel.endswith("/"):
            rel += "index.html"
        return os.path.join(self.out, rel)

    def exists(self, url):
        path = self.url_to_path(url)
        return path is not None and os.path.exists(path)

    def page_url(self, path):
        rel = os.path.relpath(path, self.out).replace(os.sep, "/")
        rel = rel[: -len("index.html")] if rel.endswith("index.html") else rel
        return "%s/%s" % (self.base, rel)

    # -- per-page ---------------------------------------------------------
    def check_page(self, path):
        rel = os.path.relpath(path, self.out).replace(os.sep, "/")
        html = open(path, encoding="utf-8").read()
        self.checked += 1
        url = self.page_url(path)

        canon = CANONICAL_RE.search(html)
        if not canon:
            return self.fail(rel, "no <link rel=canonical>")
        canon = canon.group(1)

        # /en/ is a deliberate alias of the site root and canonicalizes there.
        # Every other page — landing or blog, English or translated — points at
        # itself. A translation is not a duplicate; canonicalizing it away would
        # deindex it and void its hreflang cluster.
        expected = self.base + "/" if rel == "en/index.html" else url
        if canon != expected:
            self.fail(rel, "canonical is %s, expected %s" % (canon, expected))

        for hreflang, href in HREFLANG_RE.findall(html):
            if not self.exists(href):
                self.fail(rel, "hreflang=%s points at %s which was never written"
                          % (hreflang, href))

        md = MARKDOWN_RE.search(html)
        if md and not os.path.exists(os.path.join(self.out, md.group(1).lstrip("/"))):
            self.fail(rel, "rel=alternate text/markdown points at missing %s" % md.group(1))

        if len(H1_RE.findall(html)) != 1:
            self.fail(rel, "expected exactly one <h1>, found %d" % len(H1_RE.findall(html)))

        for block in JSONLD_RE.findall(html):
            try:
                json.loads(block)
            except json.JSONDecodeError as e:
                self.fail(rel, "JSON-LD does not parse: %s" % e)

        # A blog post under /xx/ must declare that language: the build never
        # serves an English body from a localized URL.
        lang = LANG_RE.search(html)
        parts = rel.split("/")
        if lang and len(parts) > 1 and parts[0] != "blog" and parts[1:2] == ["blog"]:
            if lang.group(1) != parts[0]:
                self.fail(rel, 'lives under /%s/ but declares lang="%s"'
                          % (parts[0], lang.group(1)))

    # -- whole-site -------------------------------------------------------
    def check_sitemap(self):
        path = os.path.join(self.out, "sitemap.xml")
        if not os.path.exists(path):
            return self.fail("sitemap.xml", "missing")
        root = ET.parse(path).getroot()
        locs = 0
        for url in root.findall(SITEMAP_NS + "url"):
            loc = url.find(SITEMAP_NS + "loc").text
            locs += 1
            if not self.exists(loc):
                self.fail("sitemap.xml", "<loc>%s</loc> has no file behind it" % loc)
            for alt in url.findall(XHTML_NS + "link"):
                href = alt.get("href")
                if not self.exists(href):
                    self.fail("sitemap.xml", "%s alternate %s has no file behind it"
                              % (loc, href))
            if loc.endswith(".md"):
                self.fail("sitemap.xml", "%s is an alternate representation, not a page" % loc)
        print("  sitemap.xml: %d URLs, all resolvable" % locs)

    def check_feeds(self):
        feeds = 0
        for dirpath, _, files in os.walk(self.out):
            if "feed.xml" not in files:
                continue
            path = os.path.join(dirpath, "feed.xml")
            rel = os.path.relpath(path, self.out)
            try:
                root = ET.parse(path).getroot()
            except ET.ParseError as e:
                self.fail(rel, "not well-formed XML: %s" % e)
                continue
            if root.tag != ATOM_NS + "feed":
                self.fail(rel, "root element is %s, expected an Atom <feed>" % root.tag)
            for entry in root.findall(ATOM_NS + "entry"):
                link = entry.find(ATOM_NS + "link")
                if link is None or not self.exists(link.get("href")):
                    self.fail(rel, "entry links to a page that does not exist")
            feeds += 1
        print("  feeds: %d Atom feeds, every entry resolvable" % feeds)

    def run(self):
        for dirpath, _, files in os.walk(self.out):
            # The Flutter app and the 3D stage are application surfaces, not
            # content — robots.txt disallows both and they own no canonical.
            rel = os.path.relpath(dirpath, self.out)
            if rel.split(os.sep)[0] in ("app", "stage"):
                continue
            for name in files:
                if name.endswith(".html"):
                    self.check_page(os.path.join(dirpath, name))
        print("  pages: %d checked (canonical, hreflang, JSON-LD, h1, lang)" % self.checked)
        self.check_sitemap()
        self.check_feeds()
        return self.errors


def main():
    ap = argparse.ArgumentParser(description="Verify the rendered site's SEO invariants.")
    ap.add_argument("out_dir")
    ap.add_argument("--base", default="https://live.tips")
    args = ap.parse_args()

    print("Checking %s" % args.out_dir)
    errors = Checker(args.out_dir, args.base).run()
    if errors:
        print("\n%d problem(s):" % len(errors))
        for e in errors:
            print("  " + e)
        sys.exit(1)
    print("All good.")


if __name__ == "__main__":
    main()
