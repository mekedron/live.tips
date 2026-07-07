# One-time Cloudflare setup — exact steps

Everything below happens once, takes ~10 minutes, and requires only you
(the account owner). After step 4 the GitHub Action redeploys the worker
automatically on every push that touches `worker/`.

Account: **Nikita's Cloudflare account**. Where noted below, use your
**Account ID** — find it at dashboard → any zone → right sidebar → *Account ID*
(it's also the hex string in the dashboard URL). It stays out of git: it goes
only into a GitHub secret.

---

## Step 0 — Turnstile widget  ✅ (already done)

The real sitekey `0x4AAAAAADxbXSyz6hPQKTiZ` is already in
`worker/wrangler.jsonc` → `vars.TURNSTILE_SITE_KEY`.

Keep the widget's **secret key** from that same Turnstile page at hand —
you'll paste it in step 2. If you didn't note it down: dashboard →
**Turnstile** → your widget → **Settings** → *Secret key*.

Double-check the widget settings list BOTH hostnames: `live.tips` **and**
`api.live.tips`, mode **Managed**.

## Step 1 — Log wrangler in and deploy

```sh
cd worker
npx wrangler login       # opens the browser, click Allow
npx wrangler deploy
```

The first deploy creates: the `livetips-relay` script, both Durable Object
classes, the `live.tips/t/*` route, and the `api.live.tips` custom domain
(it will add the DNS record itself — `api.live.tips` is currently unused,
verified).

If it asks about a registered `workers.dev` subdomain — decline/skip;
`workers_dev` is disabled in the config.

## Step 2 — Set the two production secrets

```sh
cd worker
npx wrangler secret put TURNSTILE_SECRET
# → paste the Turnstile widget SECRET key (starts with 0x..., different from the sitekey)

openssl rand -base64 32 | tee /dev/tty | npx wrangler secret put ADMIN_TOKEN
# → prints the admin token AND stores it. Save the printed value in 1Password —
#   it's what you'll paste at https://api.live.tips/admin to see all jars.
```

## Step 3 — API token for GitHub Actions

Dashboard → **My Profile → API Tokens** (<https://dash.cloudflare.com/profile/api-tokens>)
→ **Create Token** → template **"Edit Cloudflare Workers"** → *Use template*.

Then on the token form:

1. **Permissions** — the template's defaults are fine (Workers Scripts Edit,
   Workers Routes Edit, etc.). Nothing to add.
2. **Account Resources** → *Include* → pick your account
   (`Nikita.rabykin@gmail.com's Account`).
3. **Zone Resources** → *Include* → *Specific zone* → **live.tips**.
4. (Optional but nice) *Client IP filtering*: leave empty — GitHub runners
   have no fixed IPs.
5. **Continue to summary** → **Create Token** → copy the token
   (shown exactly once). Suggested name if you edit it: `live.tips worker deploy (GitHub Actions)`.

## Step 4 — Give the token to GitHub

```sh
cd /Users/nikita/Projects/app.live.tips
gh secret set CLOUDFLARE_WORKERS_API_TOKEN   # paste the token from step 3
gh secret set CLOUDFLARE_ACCOUNT_ID          # paste your Account ID (dashboard sidebar)
```

(We don't touch `CLOUDFLARE_API_TOKEN` — this is a separate cache-purge-токен for pages.yml.)

## Step 5 — Verify

```sh
curl https://api.live.tips/healthz          # → ok
curl -s -X POST https://api.live.tips/v1/jars \
  -H 'content-type: application/json' \
  -d '{"artistName":"Setup Test","message":"","currency":"eur","methods":{"revolutUsername":"mekedron"}}'
# → 201 with {jarId, secret, donateUrl}. Open the donateUrl on your phone —
#   you should see the donor page with a working Turnstile widget.
# Clean up: open https://api.live.tips/admin, paste the ADMIN_TOKEN, delete the test jar.
```

Then re-run the last GitHub worker workflow (or push any `worker/**` change) —
the deploy step will stop being skipped:

```sh
gh workflow run worker.yml && gh run watch
```

---

That's all. Rotating the API token later: create a new one with the same
template and `gh secret set CLOUDFLARE_WORKERS_API_TOKEN` again.
