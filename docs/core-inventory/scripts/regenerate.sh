#!/usr/bin/env bash
# Regenerates routes.json, ROUTES.md and INDEX.md from a local checkout of core.
#
# Usage: docs/core-inventory/scripts/regenerate.sh [path-to-core]   (default: ../core next to admin)
#
# Core opens a Postgres connection while booting, so DB_CONNECTION must point at any
# reachable database. No data is read; the schema does not matter. Redis and Meilisearch
# connection errors in the output are expected and harmless.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(dirname "$HERE")"
CORE="$(cd "${1:-$HERE/../../../../core}" && pwd)"
: "${DB_CONNECTION:?set DB_CONNECTION to a reachable Postgres URL, e.g. postgres://$USER@localhost:5432/postgres}"

SHA="$(git -C "$CORE" rev-parse HEAD)"
if [ -n "$(git -C "$CORE" status --porcelain -- src)" ]; then
  echo "warning: core has uncommitted changes in src/, the inventory will not match $SHA" >&2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$CORE"

export TS_NODE_TRANSPILE_ONLY=1 TS_NODE_PROJECT=tsconfig.json

# 1. boot the app (no listen) and dump the route table.
#    NODE_ENV=staging: core loads .env.<env> with override, and there is no .env.staging,
#    so DB_CONNECTION from the caller wins over .env.development (preloaded below).
NODE_ENV=staging LOG_LEVEL=fatal DOTENV_CONFIG_PATH=.env.development \
  node -r reflect-metadata -r dotenv/config -r ts-node/register \
  "$HERE/dump-routes.ts" "$TMP/routes.json" 2> >(grep -E '^dumped|Error:' | grep -v ECONNREFUSED >&2)

# 2. trace side effects statically
node -r ts-node/register "$HERE/trace-effects.ts" "$TMP/routes.json" "$OUT/routes.json"

# 3. render markdown
python3 -I "$HERE/render.py" "$OUT" "$SHA"
