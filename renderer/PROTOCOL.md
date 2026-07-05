# Stage bridge protocol — v1

The stage library is chromeless and stateless-by-design: the HOST (the Flutter
app, or `dev.html`) owns all money truth and all persisted state; the stage is
pure spectacle. One JSON message channel each way; every message carries
`"v": 1`. Unknown `type`s and unknown fields are ignored on both sides
(forward compatibility). A `hello.protocol` the host doesn't support means:
fall back to another stage style.

## Transport

- **JS → host**: `window.LiveTips.postMessage(jsonString)` — a
  webview_flutter `JavaScriptChannel` named `LiveTips` (Android/iOS/macOS).
  On Flutter Web (no JavaScriptChannel — there's no embedding WebView), the
  stage runs in a same-origin `<iframe>` and falls back to
  `window.parent.postMessage({liveTipsStage: jsonString}, origin)`. When
  neither is available (plain browser / `dev.html`), messages go to
  `console.log('[stage→host]', …)`.
- **Host → JS**: `window.__stage.dispatch(jsonStringOrObject)` — the
  webview_flutter host calls it via `runJavaScript(…)`; the Flutter Web host
  calls it directly as `iframe.contentWindow.__stage.dispatch(…)` (same-origin
  property access — safe because the host never dispatches before it has
  already received `hello`, and `window.__stage` is always assigned,
  synchronously, before `hello` is ever emitted).

## Handshake

```
page load ──▶ JS: hello{protocol:1}
host      ──▶ init{renderer, config, state}
JS renders its first frame
JS        ──▶ ready{}            (host reveals the WebView)
…messages flow…
```

A WebView render-process death reloads the page → `hello` arrives again → the
host re-sends `init` built from its authoritative snapshot. Tips/syncs that
arrive between `init` and `ready` are queued and replayed in order.

## Units

`jarPct`/`jarPctAfter`/`deltaPct` are **fractions of the session goal in
[0, 2]**: `1.0` = goal reached, `2.0` = the rollover moment (2× goal). The
renderer maps fractions to item counts internally; euros never cross the
bridge.

## Host → JS

| type | payload | notes |
|---|---|---|
| `init` | `renderer:'3d'\|'2d'`, `config{…}`, `state{jarPct, bankedJars}` | once per page load; a second `init` is ignored |
| `tip` | `id, deltaPct, jarPctAfter, rollovers` | one per donation, in arrival order; `rollovers ≥ 1` commands that many retire-to-trophy cycles before landing on `jarPctAfter` |
| `syncState` | `state{jarPct, bankedJars}`, `instant?:bool` | absolute resync (goal edit, restore, reconciliation); animated unless `instant` |
| `setConfig` | any subset of `config` | live-applies; `vessel`/`scene`/`quality` are ignored by the 2D renderer |
| `setPaused` | `paused:bool` | stop/resume all rendering (app backgrounded); `visibilitychange` is honored as backup |
| `demoPulse` | — | preview screens: the stage invents a small tip itself |

`config`: `vessel` (`caviar tin mug jar05 jar1 jar2 stage jar3 jar5 bucket
bowl`), `scene` (`abstract pub concert street metro cafe`), `theme`
(`golden-hour nord-sky forest-signal rose-pulse cobalt-stage graphite-lime`),
`notes:bool` (banknotes in the mix), `sound:bool` (synth coin clinks +
milestone/goal chimes; muted default), `tipSound:bool` (a throttled "ta-da!"
fanfare on every `tip`/`demoPulse` so the artist HEARS money arrive; muted
default, independent of `sound`), `quality:'auto'|'high'|'low'` (bloom tier,
3D), `reducedMotion:bool`, `insets:{top,bottom}` (logical px the host's
native HUD/chrome occupies — the vessel frames itself into the free band).

## JS → host

| type | payload | notes |
|---|---|---|
| `hello` | `protocol:1` | on every page load |
| `ready` | — | first frame rendered |
| `event` | `kind:'milestone'\|'goalReached'\|'zoneFull'\|'rolloverDone'`, `jarPct` | cosmetic lifecycle beats (haptics, HUD pulses) — **never accounting input**; the host already banked before commanding the rollover |
| `perf` | `fps, quality` | every ~5 s, even while paused/idle — doubles as the host watchdog's liveness signal (`fps:0` while paused, `quality:'idle'` when the 2D loop sleeps) |
| `error` | `message, fatal` | `fatal:true` before `ready` → host should fall back |

## Rollover contract (the important part)

The host accounts eagerly: on every donation (and goal edit) it banks
`2 × goal` per earned jar **immediately** and persists. The renderer is then
COMMANDED via `tip.rollovers`: it pours to the visual 200%, celebrates, plays
the retire-to-trophy animation (per rollover; intermediate jars of a multi-roll
fast-fill instantly), and finally pours to `jarPctAfter`. `rolloverDone` fires
per performed retire. If config changes mid-theater, pending retires are
folded silently into the trophy shelf — the shelf count always converges to
the host's `bankedJars`.
