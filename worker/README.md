# live.tips relay (`api.live.tips`)

A minimal Cloudflare Worker that lets artists accept **MobilePay Box** and
**Revolut** tips in addition to Stripe. It is a **profile store + live event
pipe** — it stores an artist's public tip-jar profile (name, message, payment
handles) and forwards tip notifications to the artist's device over a
WebSocket. **It keeps no tip history and never touches money.** A tip that
finds nobody connected waits up to an hour for the artist's screen and is then
deleted unseen; that queue is the only fan text ever written here.

Stripe tips do not go through here at all — the app talks to Stripe directly,
exactly as before. This relay exists only because MobilePay/Revolut have no
API to confirm a payment, so relayed tips are **unverified by design** and the
app labels them as such.

## Design

- **One Durable Object per jar** (`JarDO`, SQLite backend). Holds ~1 KB: the
  profile, a SHA-256 hash of the artist's secret, the artist's hibernated
  WebSockets, and — only while their screen is away — the tips it has not
  managed to hand over yet. Self-destructs via its own alarm 90 days after the
  artist was last seen — there is no global cleanup job.
- **An undelivered tip is queued, not dropped.** The fan is redirected to pay
  the instant they submit, so losing the event because the artist's phone
  happened to be locked would cost them real money for nothing. The queue is
  capped, swept after an hour by the same alarm, and emptied the moment a
  screen authenticates.
- **One `RegistryDO`** (single instance): a directory of jars for the
  maintainer admin view, plus the per-IP jar-creation quota. Metadata and
  counters only — never tip content or fan identities.
- **No free-form URLs are ever stored.** Artists register validated *atoms*
  (a `buy|donate.stripe.com` link code, a Revolut username, a MobilePay Box
  UUID); the worker composes every outgoing link itself onto hardcoded hosts.
  This is the open-redirect / phishing gate.

## Routes

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/v1/jars` | rate-limit | create a jar → `{jarId, secret, tipUrl}` |
| PUT | `/v1/jars/:id` | Bearer secret | update profile |
| DELETE | `/v1/jars/:id` | Bearer secret | delete jar |
| POST | `/v1/jars/:id/seen` | Bearer secret | daily keepalive ping |
| POST | `/v1/jars/:id/rotate-secret` | Bearer secret | rotate the secret |
| GET | `/v1/jars/:id/ws` | first-message auth | artist event socket |
| GET | `/t/:id` | — | tip page (served on `live.tips/t/*`) |
| POST | `/t/:id/tips` | Turnstile | relay a tip, return the deep link |
| GET | `/admin`, `/admin/jars`, DELETE `/admin/jars/:id` | `ADMIN_TOKEN` | maintainer view |
| GET | `/healthz` | — | liveness |

The WebSocket authenticates with a first message `{"type":"auth","secret":…}`;
the server replies `{"type":"ready"}`, immediately followed by any tips queued
while the device was away, or closes with a code. Keepalive uses the
hibernation auto-response (`ping`/`pong`) so idle sockets never wake the
object.

Close codes are a contract with the app. `4401` (bad or rotated secret) and
`4410` (jar gone) are **terminal** — the artist must re-link. Everything else
is transient and retried, including `4408`, which means only that the socket
missed the 30-second auth deadline on a slow link.

`POST /t/:id/tips` answers `{redirectUrl, delivered, queued}`: `delivered` when
a live screen took it, `queued` when it is waiting for one. The fan gets their
deep link either way.

`POST /v1/jars` answers `{jarId, secret, tipUrl}` — the one and only time the
secret is ever readable. `tipUrl` is the public page the artist's QR code points
at (`https://live.tips/t/<jarId>`).

## Local development

```sh
cd worker
npm install
cp .dev.vars.example .dev.vars   # Turnstile + admin test secrets
npm run dev                      # wrangler dev — real local SQLite DOs, alarms, WS
npm test                         # vitest (SELF fetch e2e, DO alarm, WS handshake)
npm run check                    # tsc --noEmit
```

`wrangler dev` uses the always-passing Turnstile **test** keys, so the tip
form works locally without a real widget.

## Production setup (one-time, needs the account owner)

These steps require credentials that only the Cloudflare account owner should
enter. Do them once; afterwards CI redeploys automatically.

1. **Turnstile widget** — dashboard → Turnstile → Add widget, mode *Managed*,
   hostnames `live.tips` **and** `api.live.tips`. Copy the **sitekey** into
   `wrangler.jsonc` → `vars.TURNSTILE_SITE_KEY`.
2. **Worker secrets**:
   ```sh
   wrangler secret put TURNSTILE_SECRET   # the widget's secret key
   wrangler secret put ADMIN_TOKEN        # a long random string, e.g. `openssl rand -base64 32`
   ```
3. **First deploy** (creates the script, DO migrations, the `live.tips/t/*`
   route, and the `api.live.tips` custom domain):
   ```sh
   wrangler login        # OAuth in the browser — grants all needed perms
   wrangler deploy
   ```
   Confirm `api.live.tips` had no pre-existing DNS record; the custom domain
   will create it.
4. **CI credentials** (GitHub Actions, for automatic redeploys on push):
   - Create a **Workers API token**: dashboard → My Profile → API Tokens →
     *Edit Cloudflare Workers* template. Add **Zone → live.tips → Workers
     Routes: Edit** and, for the custom domain, **Zone → live.tips → DNS: Edit**
     (only if you want CI to manage the custom domain; if it already exists,
     Workers Scripts + Routes Edit suffice). Account Resources = your account,
     Zone Resources = `live.tips`.
   - Add repo secrets:
     ```sh
     gh secret set CLOUDFLARE_WORKERS_API_TOKEN   # the token above (distinct from the cache-purge token)
     gh secret set CLOUDFLARE_ACCOUNT_ID          # dashboard → Workers overview → Account ID
     ```
5. **Smoke test**:
   ```sh
   curl https://api.live.tips/healthz
   # create a jar, open https://live.tips/t/<jarId> on a phone, send a test tip
   ```

## Do NOT enable Bot Fight Mode

Free-plan Bot Fight Mode challenges non-browser clients and **cannot** be
excepted with WAF skip rules. It would break the native app's REST and
WebSocket calls to `api.live.tips`. Abuse protection here is Turnstile (on the
tip form) plus per-IP and per-jar rate limits. Leave BFM off.
