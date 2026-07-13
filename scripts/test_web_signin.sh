#!/usr/bin/env bash
# Click through a REAL web sign-in from your Mac, in Safari.
#
# Builds the Flutter web app and serves it at http://localhost:8123/app/ —
# same /app/ sub-path as production. Sign-in leaves for the real bridge on
# https://auth.live.tips/signin (deployed Firebase Hosting; the bridge
# allowlists localhost return URLs exactly for this) and comes back with the
# session. If Settings shows your cloud account afterwards, the whole chain —
# bridge, Google/Apple, mintSessionToken, custom-token return — works.
#
# Safari is the browser that matters here: its storage partitioning is what
# broke the old in-app signInWithRedirect flow, silently. Chrome passing was
# never the question.
#
#   scripts/test_web_signin.sh            # build + serve + open Safari
#   scripts/test_web_signin.sh --no-build # reuse the last build
set -euo pipefail

cd "$(dirname "$0")/../app"

if [[ "${1:-}" != "--no-build" ]]; then
  flutter build web --base-href /app/
fi

# Serve the build under /app/ (a symlink in a scratch dir does the mapping).
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ln -s "$PWD/build/web" "$STAGE/app"

PORT=8123
echo
echo "Serving http://localhost:$PORT/app/  —  Ctrl-C to stop."
echo "Try: onboarding -> Sign in with Google, and Settings -> Cloud account."
open -a Safari "http://localhost:$PORT/app/" 2>/dev/null || true
exec python3 -m http.server "$PORT" --directory "$STAGE" --bind 127.0.0.1
