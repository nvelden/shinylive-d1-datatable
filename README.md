# Shinylive D1 DataTable

> **Warning**
> This example API is intentionally simple. For a public production app, add
> authentication or Cloudflare Access before allowing writes.

This is a small tutorial example showing an editable Shiny DataTable running in
the browser with [Shinylive](https://posit-dev.github.io/r-shinylive/) and
persisting rows through a [Cloudflare Worker](https://developers.cloudflare.com/workers/)
backed by [Cloudflare D1](https://developers.cloudflare.com/d1/).

## Project Shape

```text
app.R                              # Shinylive/Shiny DataTable app
worker/src/index.js                # Worker API for row CRUD
worker/wrangler.toml               # Worker + D1 binding template
migrations/0001_create_responses.sql
scripts/export-shinylive.R         # Clean Shinylive export helper
scripts/setup-local.sh             # Local setup helper
```

## Prerequisites

- R with `shiny`, `DT`, `shinyjs`, and `shinylive`
- Node.js 22 or newer
- A Cloudflare account

Install the R packages if needed:

```r
install.packages(c("shiny", "DT", "shinyjs", "shinylive"))
```

Install the JavaScript dependency:

```bash
npm install
```

This installs [Wrangler](https://developers.cloudflare.com/workers/wrangler/),
Cloudflare's command line tool. The scripts in this project use Wrangler to run
the local Worker, create and migrate D1 databases, set Worker secrets, deploy
the Worker, and deploy the static Shinylive app to Cloudflare Pages.

Log in to Cloudflare with Wrangler:

```bash
npx wrangler login
```

## Run Locally

Run the local setup helper:

```bash
npm run local:setup
```

This creates `worker/.dev.vars` if it does not exist, creates and seeds the
local D1 database, and exports the Shinylive app to `docs/`.

Run the static app and Worker in separate terminals:

```bash
npm run site:dev
npm run worker:dev
```

Open `http://localhost:8000`.

## Deploy With Your Cloudflare Account

Create a D1 database:

```bash
npm run d1:create
```

Wrangler prints a `database_id`. Copy it into `worker/wrangler.toml`:

```toml
database_id = "your-d1-database-id"
```

Choose a shared secret:

```bash
openssl rand -hex 32
```

Copy the value printed by `openssl`. Put that same value in both places:

- In `app.R`, replace `REPLACE_WITH_SHARED_SECRET`.
- In Cloudflare, run this command and paste the same value when prompted:

```bash
npm run worker:secret
```

Deploy the Worker:

```bash
npm run worker:deploy
```

Wrangler prints a Worker URL. Copy it into `app.R` by replacing
`https://REPLACE_WITH_WORKER_SUBDOMAIN.workers.dev`.

If you change the Pages project name, update `ALLOWED_ORIGIN` in
`worker/wrangler.toml` to match your Pages URL.

Run the deploy helper:

```bash
npm run cloudflare:deploy
```

This runs the remote D1 migration, deploys the Worker, exports the Shinylive
app, and deploys the static site to Cloudflare Pages.

Open the Pages URL printed by Wrangler.

## Notes

- Do not commit `worker/.dev.vars`, Cloudflare API tokens, database ids from a
  private project, or generated `docs/` output.
- `SHARED_SECRET` is visible in the browser because this is a static Shinylive
  app. Treat it as a tutorial guard only, not real production authentication.
