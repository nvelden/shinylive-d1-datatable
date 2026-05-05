#!/usr/bin/env sh
set -eu

if [ ! -f worker/wrangler.toml ]; then
  cp worker/wrangler.toml.example worker/wrangler.toml
  echo "Created worker/wrangler.toml from worker/wrangler.toml.example"
  echo "Edit it to set your D1 database id and ALLOWED_ORIGIN before deploying."
else
  echo "worker/wrangler.toml already exists"
fi

if [ ! -f worker/.dev.vars ]; then
  cp worker/.dev.vars.example worker/.dev.vars
  echo "Created worker/.dev.vars from worker/.dev.vars.example"
else
  echo "worker/.dev.vars already exists"
fi

npm run d1:migrate:local
npm run export

echo "Local setup complete. Run npm run site:dev and npm run worker:dev in separate terminals."
