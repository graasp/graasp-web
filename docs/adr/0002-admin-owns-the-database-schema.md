# Admin owns the database schema

The Phoenix admin app is the only place database migrations are written and run. The Node core stops running `drizzle-kit migrate`. It keeps `src/drizzle/schema.ts` as a hand-maintained description of a database that admin has already migrated.

Both apps share one Postgres database, and until now both migrated it: core with drizzle, admin with Ecto. That made it unclear which app owned a table. Admin's migrations held partial copies of core tables so its tests could run. New features that touch both apps, starting with per-member storage limits, would have had to pick a side each time. We picked admin because new schema work increasingly starts there, and admin's own migrations are already applied to production with Ecto.

## Considered options

- **Keep core's drizzle history frozen and add admin migrations on top**: rejected. It needs two migration tools forever, run in sequence on every fresh database.
- **Rewrite admin's history into one clean baseline and mark it applied by hand in production**: rejected because it means manual surgery on production `schema_migrations`.

## Consequences

- Admin gets a baseline migration: a schema-only snapshot taken after core migration `0021`. It skips itself on databases that already have the schema. Existing admin migrations that create core tables must run after it, or be guarded so they become no-ops.
- Core CI migrates its test database by running admin's migrations (admin Docker image, `Admin.Release.migrate`). `migration-check` is replaced by a drift check between `schema.ts` and the migrated database.
- Deploy order matters: admin migrates before a core version that relies on a new table or column is deployed. Core does not guard against missing schema.
- A schema change in core now takes two changes: an Ecto migration in admin, then the matching `schema.ts` update in core.

## Amendment: transition details

Written after checking both repositories against the plan above.

### Where things stand

- `schema_migrations` is created by core (drizzle `0011`), and core migrations `0011` to `0013` insert fake rows for admin migrations up to `20251014122320`. One of them, `20250904072624`, has no matching file in admin and shows as "file not found" in `Admin.Release.migration_status/0`. That is harmless.
- Admin migrations after `20251014122320` are applied by hand: someone opens a remote shell on the ECS task and runs `Admin.Release.migrate()`. Nothing runs them automatically on deploy.
- Admin's history holds partial copies of core tables (`account`, `item`, memberships, tags, actions, app tables, `maintenance`, `item_visibility`). They don't match core exactly, for example the `item_visibility` unique constraint is named `item-visibility` in admin and `UQ_item_visibility_item_type` in core.
- `schema.ts` already lags behind production: the `name` and `language` columns admin added to `admins` (`20251217123725`) and admin's indexes on `item` are missing from it.

### Baseline migration

- **Its version is older than every existing migration** (before `20250806110912`). Ecto runs every pending migration in version order, older ones included. With a later version, a fresh database would first build admin's partial copies, the baseline would find `item` already there, skip itself, and leave a broken schema.
- **It checks the database state three ways**, never just "does `item` exist":
  - drizzle recorded all 22 migrations (`drizzle.__drizzle_migrations`): do nothing;
  - the schema is empty: create the full schema;
  - anything else (core below `0021`, or a database built by admin alone): raise, and say how to fix it (upgrade core to the last drizzle release first, or drop and recreate the database).
- Its `down` raises: there is no going back from it.
- It is a schema-only dump of a database migrated by core to `0021`. It leaves out `schema_migrations` and the `drizzle` schema and keeps the `ltree`, `uuid-ossp` and `citext` extensions.
- Every existing migration that creates or reshapes a core table becomes a no-op: `20250806110912` (the `account` part only), `20250807113759`, `20250818111736`, `20250819070000`, `20250828053810`, `20250901102230`, `20250902085812`, `20250904060051`, `20251014122320` and `20260601090000`. This is safe because Ecto keeps no checksums, so databases that already ran them never run them again.

### Before switching

1. Bring `schema.ts` up to date with production. The drift check can't be turned on until it matches.
2. Check that production is at drizzle `0021` and that `Admin.Release.migration_status/0` shows nothing pending.
3. Tag the last core release that still ships the drizzle `migrate` image. It is the upgrade path for databases below `0021`.

### Deploy order

Admin migrations are still run by hand on the ECS task, so a release that needs a schema change has a checklist step: deploy admin, run `Admin.Release.migrate()`, check `Admin.Release.migration_status/0`, and only then deploy core. Skipping that step means core fails on missing tables or columns, since it doesn't guard against them.

### Core CI

- Both CI jobs that run `mise run migrate` (`test` and `test-node`) run the admin image's `bin/admin eval Admin.Release.migrate` instead.
- The admin image tag is pinned. A core change that needs a migration not yet in a published admin image needs a defined path: either the admin change merges and publishes first, or core CI builds admin from a given ref. Floating on `latest` would break unrelated core PRs.
- The drift check compares against a database that admin migrated (`drizzle-kit pull` and a diff, or a dry-run `push`). It is limited to the tables in `schema.ts` with a `tablesFilter`. Without the filter, drizzle-kit sees admin-only tables (`oban_*`, `notifications`, `folder_exports`, `users_tokens`, ...) as extra and offers to drop them. For the same reason, nobody runs `drizzle-kit push` against a shared database.

### Effect on each kind of database

- **Production and the dev environment:** the baseline is pending because of its old version. It runs, finds core at `0021`, does nothing and records its row. The no-op migrations are already recorded and never run. No hand edits to `schema_migrations` are needed. The dev environment can be recreated from scratch instead.
- **Self-hosted databases:** `core/docker/compose.yml` ships a drizzle-only `migrate` image. After the switch, migrating requires the admin image even for people who don't run admin, so the compose file gets an admin migrate service. A database below `0021` first runs the last drizzle release's `migrate` image. The baseline raises if that step was skipped.
- **Local core databases (dev container):** same as production. New ones need the admin image or an admin checkout, because `drizzle-kit migrate` no longer sets up a database.
- **Local admin-only databases** (built only from admin's migrations): they hold the partial copies, so the baseline raises. Run `mix ecto.reset` once.
- **Admin test databases:** `mix test` only runs `ecto.create` and `ecto.migrate`, so existing local `admin_test` databases keep their partial copies and the baseline raises. Run `MIX_ENV=test mix ecto.reset` once. CI starts from an empty Postgres and is not affected. Tests that relied on quirks of the partial copies (constraint names, missing `NOT NULL` columns in factories) need fixing once, after which admin tests run against the real core schema.
- **Core test databases:** test setup only connects, so existing ones keep working. New ones are migrated with the admin image, as in CI.
