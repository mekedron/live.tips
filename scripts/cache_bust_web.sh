#!/usr/bin/env bash
# Cache-bust the Flutter web entry points so a fresh deploy can never be
# shadowed by a stale copy sitting in a browser's HTTP cache.
#
# Why this is needed
# ------------------
# The Flutter web loader chain is:
#     index.html  ->  flutter_bootstrap.js  ->  main.dart.js
# and every one of those files ships under a STABLE, unchanging URL. Our CDN
# (Cloudflare, in front of GitHub Pages) stamps a long browser Cache-Control TTL
# on static .js, so iOS Safari — especially an installed home-screen PWA — keeps
# serving the main.dart.js it downloaded long ago under that unchanging URL.
# Purging the Cloudflare edge cache does nothing about it: the stale copy already
# lives in Safari's *local* cache, and only "Clear History and Website Data"
# evicts it — exactly the annoyance we hit after every release.
#
# index.html itself carries a short (~10 min) TTL and does refresh, but on its
# own that changes nothing: it keeps pointing at the same flutter_bootstrap.js /
# main.dart.js URLs the browser already has cached. Appending a per-build
# ?v=<id> to those two references turns each deploy into brand-new URLs the
# browser has never seen, so it must fetch them — sidestepping the stale copies
# entirely. The next deploy gets a new id, so this keeps working release after
# release. (flutter_service_worker.js is already versioned by Flutter and the
# worker self-unregisters, so it needs no busting here.)
#
# The rewrite is idempotent: once a reference carries ?v=, it no longer matches.
#
# Usage: cache_bust_web.sh <web-dir> [version]
#   web-dir  the built Flutter web output (e.g. app/build/web)
#   version  optional; defaults to $GITHUB_SHA, else the current git commit
set -euo pipefail

web_dir="${1:?usage: cache_bust_web.sh <web-dir> [version]}"
version="${2:-${GITHUB_SHA:-$(git -C "$web_dir" rev-parse HEAD 2>/dev/null || true)}}"
version="${version:0:12}"
if [ -z "$version" ]; then
  echo "cache_bust_web: could not determine a version (pass one explicitly)" >&2
  exit 1
fi

index="$web_dir/index.html"
bootstrap="$web_dir/flutter_bootstrap.js"
for f in "$index" "$bootstrap"; do
  if [ ! -f "$f" ]; then
    echo "cache_bust_web: expected file not found: $f" >&2
    exit 1
  fi
done

# index.html: the <script src> that loads the bootstrap.
perl -0pi -e 's{src="flutter_bootstrap\.js"}{src="flutter_bootstrap.js?v='"$version"'"}g' "$index"

# flutter_bootstrap.js: the entrypoint declared in _flutter.buildConfig, which is
# the path the loader actually fetches (mainJsPath, not the fallback defaults).
perl -0pi -e 's{"mainJsPath":"main\.dart\.js"}{"mainJsPath":"main.dart.js?v='"$version"'"}g' "$bootstrap"

# Fail loudly if Flutter changed its output shape and nothing was stamped.
if ! grep -q 'flutter_bootstrap\.js?v=' "$index" \
   || ! grep -q 'main\.dart\.js?v=' "$bootstrap"; then
  echo "cache_bust_web: rewrite matched nothing — Flutter output shape changed?" >&2
  exit 1
fi

echo "cache_bust_web: stamped ?v=$version onto flutter_bootstrap.js and main.dart.js"
