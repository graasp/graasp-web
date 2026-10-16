# Admin owns the database schema

The Phoenix admin app is the only place database migrations are written and run. The Node core stops running `drizzle-kit migrate`. It keeps `src/drizzle/schema.ts` as a hand-maintained description of a database that admin has already migrated.

Both apps share one Postgres database, and until now both migrated it: core with drizzle, admin with Ecto. That made it unclear which app owned a table. Admin's migrations held partial copies of core tables so its tests could run. New features that touch both apps, starting with per-member storage limits, would have had to pick a side each time. We picked admin because new schema work increasingly starts there, and Ecto migrations already run on deploy.

## Considered options

- **Keep core's drizzle history frozen and add admin migrations on top**: rejected. It needs two migration tools forever, run in sequence on every fresh database.
- **Rewrite admin's history into one clean baseline and mark it applied by hand in production**: rejected because it means manual surgery on production `schema_migrations`.

## Consequences

- Admin gets a baseline migration: a schema-only snapshot taken after core migration `0021`. It skips itself on databases that already have the schema. Existing admin migrations that create core tables must run after it, or be guarded so they become no-ops.
- Core CI migrates its test database by running admin's migrations (admin Docker image, `Admin.Release.migrate`). `migration-check` is replaced by a drift check between `schema.ts` and the migrated database.
- Deploy order matters: admin migrates before a core version that relies on a new table or column is deployed. Core does not guard against missing schema.
- A schema change in core now takes two changes: an Ecto migration in admin, then the matching `schema.ts` update in core.
