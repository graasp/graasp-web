#!/usr/bin/env bash
# Regenerates priv/repo/baseline/core_schema.sql from a production dump.
#
# The baseline is the production schema as it stood before admin took over the
# schema (ADR 0002): core's tables, minus the objects that admin migrations
# after 20251014122320 create themselves. Production started life as a TypeORM
# database, so replaying core's drizzle history does NOT reproduce it (constraint
# names and unique column orders differ); the baseline has to be cut from a
# production dump.
#
# The baseline is frozen once merged. This script is kept to document how it was
# made, not to be rerun on every release.
#
# Usage: scripts/generate_core_baseline.sh <prod.dump>
# Connection: standard libpq variables (PGHOST, PGPORT, PGUSER, PGPASSWORD).
# Needs a role allowed to create databases. A throwaway database is created and
# dropped.
set -euo pipefail

dump="${1:?usage: $0 <prod.dump>}"
out="$(cd "$(dirname "$0")/.." && pwd)/priv/repo/baseline/core_schema.sql"
db="core_baseline_tmp_$$"

dropdb --if-exists "$db"
createdb "$db"
trap 'dropdb --if-exists "$db"' EXIT

pg_restore --schema-only --no-owner --no-privileges --exit-on-error -d "$db" "$dump"

# Objects created by admin migrations after the baseline. They keep being created
# by those migrations, so they must not be in the baseline.
psql -X -q -v ON_ERROR_STOP=1 -d "$db" <<'SQL'
-- 20251103104204_add_oban
DROP TABLE public.oban_jobs, public.oban_peers;
DROP FUNCTION public.oban_count_estimate(text, text);
DROP TYPE public.oban_job_state;
-- 20251103143048_create_notifications, 20260110080411_localized_emails,
-- 20260119072559_add_pixel_in_mailing
DROP TABLE public.notification_logs, public.notification_pixels, public.localized_emails,
  public.notifications;
-- 20251217123725_add_user_name_language
ALTER TABLE public.admins DROP COLUMN name, DROP COLUMN language;
-- 20260319092823, 20260430121745, 20260508071207 (item indexes)
DROP INDEX public.idx_item_type_h5p_contentid, public.idx_item_creator_not_deleted_path,
  public.idx_item_path_not_deleted, public.idx_item_type_created_at;
-- 20260601090100_create_folder_exports
DROP TABLE public.folder_exports;
SQL

{
  echo "-- Core schema baseline, cut from a production dump by scripts/generate_core_baseline.sh."
  echo "-- Executed by the CoreBaseline migration on empty databases only. Do not edit."
  echo
  # Drop pg_dump's session settings: the migration runs them on Ecto's connection,
  # and `set_config('search_path', '', false)` would outlive the migration.
  # Extension comments are dropped too: CREATE EXTENSION sets the same ones, and
  # COMMENT ON EXTENSION needs ownership of an extension that may already exist.
  pg_dump --schema-only --no-owner --no-privileges \
    --exclude-schema=drizzle --exclude-table=public.schema_migrations "$db" |
    grep -v -E '^(--|\\restrict|\\unrestrict|SET |SELECT pg_catalog\.set_config|COMMENT ON EXTENSION )' |
    cat -s
} >"$out"

echo "wrote $out"
