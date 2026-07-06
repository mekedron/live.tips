# website — live.tips landing page

The marketing landing page, deployed to **GitHub Pages** at
<https://mekedron.github.io/live.tips/> by
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml).

## The tip-jar stage is reused, not copied

The landing page embeds the live 3D tip jar in an `<iframe src="stage/index.html">`
and drives it over the same JSON bridge the Flutter app uses
([`renderer/PROTOCOL.md`](../renderer/PROTOCOL.md)).

There is **no copy of the renderer here.** `stage/index.html` and `stage/stage.js`
are assembled at deploy time from the committed build in
[`app/assets/stage/`](../app/assets/stage/) — the single source of truth,
rebuilt from `renderer/src/` via `npm run build`. Do not add a `stage/` folder
to `website/`.

## Layout on the published site

| Path | Source |
| --- | --- |
| `/` | `website/index.html` |
| `/stage/` | copied from `app/assets/stage/` by the workflow |
| `/app/` | the Flutter web app (deployed in a later change) |

## Preview locally

The stage is same-origin, so serve the assembled tree over HTTP (not `file://`):

```sh
# from the repo root
mkdir -p /tmp/lt-site/stage
cp -R website/. /tmp/lt-site/ && rm -f /tmp/lt-site/README.md
cp app/assets/stage/index.html app/assets/stage/stage.js /tmp/lt-site/stage/
python3 -m http.server 8080 --directory /tmp/lt-site
# → http://127.0.0.1:8080/
```
