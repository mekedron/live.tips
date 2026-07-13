# .well-known/ — universal links

`apple-app-site-association` and `assetlinks.json` associate **tip.live.tips**
with the live.tips app, so the QR add-device link
(`https://tip.live.tips/link#c=<code>`) opens the app instead of a web page.

- `apple-app-site-association` — appID `A4HHRH8Y9M.tips.live.liveTips`, path
  `/link*`. Served as `application/json` through the `hosting.headers` entry in
  firebase.json (the file has no extension, so Hosting must be told). Nothing
  may redirect or authenticate in front of it — Apple's CDN fetches it raw.
- `assetlinks.json` — package `tips.live.live_tips` plus the release signing
  fingerprint, matching the `autoVerify` intent-filter in the app's
  AndroidManifest.

Both are plain content: changing them is a `firebase deploy --only hosting`.
Apple's CDN caches the association for up to ~24h, so a change takes a day to
reach already-installed apps.
