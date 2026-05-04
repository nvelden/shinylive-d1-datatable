# Shinylive D1 DataTable

An editable Shiny DataTable that runs in the browser with
[Shinylive](https://posit-dev.github.io/r-shinylive/) and stores rows
persistently in [Cloudflare D1](https://developers.cloudflare.com/d1/).

This example is designed for readers following a tutorial on moving an editable
Shiny + SQLite table to a static Shinylive app with a small Cloudflare API.

## Architecture

```text
Browser
  Shinylive app.R
    -> fetch("/api/responses")
      -> Cloudflare Pages Function
        -> Cloudflare D1 database
```

The browser never receives database credentials. The D1 database is exposed to
the Cloudflare Function through the `SQL_TABLE_DB` binding.

## Files

```text
app.R                              # Shinylive/Shiny app
functions/api/responses.js         # Pages Function API
migrations/0001_create_responses.sql
wrangler.toml                      # Cloudflare Pages + D1 config
package.json                       # Wrangler helper scripts
```

## Prerequisites

- R with `shiny`, `DT`, `shinyjs`, and `shinylive`
- Node.js 22 or newer
- A Cloudflare account
- Wrangler authenticated with Cloudflare

Install the JavaScript dependency:

```bash
npm install
```

## 1. Create a D1 Database

```bash
npm run d1:create
```

Wrangler prints a `database_id`. Copy that id into `wrangler.toml`:

```toml
[[d1_databases]]
binding = "SQL_TABLE_DB"
database_name = "shinylive-d1-datatable"
database_id = "your-database-id"
```

Keep the binding name as `SQL_TABLE_DB`; the Function expects that exact name.

## 2. Create and Seed the Table

Run the migration against the remote D1 database:

```bash
npm run d1:migrate:remote
```

The migration creates a `responses` table and inserts sample rows.

## 3. Export the Shinylive App

```bash
npm run export
```

This writes the static app to `docs/`.

## 4. Run Locally with Cloudflare Pages

```bash
npm run pages:dev
```

Open the local URL printed by Wrangler. The app calls `/api/responses`, and the
Pages Function handles the database reads and writes.

## 5. Deploy

Create a Cloudflare Pages project named `shinylive-d1-datatable`, then deploy:

```bash
npm run pages:deploy
```

After deployment, the app is a static Shinylive site with persistent SQL-backed
rows.

## Security Notes

- Do not put Cloudflare API tokens, database credentials, or secret values in
  `app.R`.
- Do not commit `.env`, `.Renviron`, `rsconnect/`, local databases, generated
  `docs/`, or `node_modules/`.
- This example API is intentionally simple. For a public production app, add
  authentication or Cloudflare Access before allowing writes.
