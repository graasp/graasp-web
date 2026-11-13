# Ash for the domain layer

Admin uses Ash (with AshPostgres) as its domain layer for everything ported from core, starting with items and their permissions. We don't use plain Ecto contexts. Permission rules are Ash policies over core's existing tables. We model them the way Ash expresses them, not as a 1-to-1 copy of core's code, and we accept the small, frontend-safe changes in behaviour listed below.

A spike (graasp-web#318, branch `research/ash-spike`) checked Ash against a line-by-line port of core's `AuthorizedItemService`. The Ash-native version gives the same allow/deny decision and the same Effective Permission in every tested case. On a copy of production data, single items, children and the home list cost the same as hand-written SQL. Copying core's error logic exactly is what made Ash awkward: one calculation per error kind, 12 subqueries per row. No frontend uses that detail.

## Considered options

- **Plain Ecto contexts**: no new dependencies and about a third of Ash's latency on point reads (1.4 ms against 3 ms end to end). Rejected: authorization becomes a convention every query must remember. With Ash, policies apply to every action, and one expression drives both filtering and the 403.
- **Ash, matching core's errors exactly**: possible, but it needs an error-kind calculation and returns `NotFound` where core returns 403. Rejected as complexity nobody consumes.
- **Memberships only on root items**: rejected. Production (2026-11-12 dump) has 13,900 sub-folder shares with no membership above them. The sharing screen also shows where each membership was granted.
- **Materialized effective permissions (one row per item and account)**: rejected. It holds 4.57M rows against 144k memberships (32×), must be kept in sync on every create, move, copy and delete, and only speeds up queries the frontend doesn't make.

## Consequences

- **Accepted changes in behaviour** (the frontend only branches on 403 vs 404 and uses the error message as a toast text):
  - A forbidden action answers with the message of the permission the action needs (`USER_CANNOT_WRITE_ITEM`, ...), even when the account has no membership at all; core says `MEMBER_CANNOT_ACCESS` there.
  - Batch reads leave inaccessible items out of `data`, and `errors` holds one generic error per missing id instead of a per-item reason.
  - The home list no longer shows items a reader can't open because they sit below a Hidden Item. Core lists them and then answers 403.
- **Errors**: reads use `authorize_with: :error`, so an existing but forbidden item gives 403 and a missing one 404, as in core. `matchOne`-style account checks (validated member, guest) stay plugs, since an Ash `Forbidden` doesn't say which check failed.
- **Ash generates the migrations, and they are still Ecto migrations.** ADR 0002 stands: admin owns the schema and runs it with `Admin.Release.migrate`. `mix ash_postgres.generate_migrations` writes ordinary Ecto migrations into `priv/repo/migrations` and keeps resource snapshots next to them. The generator diffs resources against those snapshots, not against the database, so a resource must describe its table exactly before Ash manages it.
- **Transition**, one table at a time:
  1. Prerequisites: drop the unused `poison` dependency and point ex_aws at Jason (it pins `decimal` 2, which blocks Ecto 3.14). Then upgrade to Ecto 3.14, add ash, ash_postgres and picosat_elixir, and make `Admin.Repo` an `AshPostgres.Repo` with `"ash-functions"` installed by a migration.
  2. Each core table first gets a resource with `migrate? false`, declaring existing constraint and index names (`references name:`, `identity_index_names`, `custom_indexes`) and `AshPostgres.TimestamptzUsec` for core's `timestamptz` columns. Ported route groups use it right away.
  3. Once a resource describes its table completely, switch it to `migrate? true` and run `generate_migrations --snapshots-only` to record a baseline without emitting a migration. From then on, schema changes are resource edits. `generate_migrations --check` runs in `mix precommit` and CI so resources and snapshots can't drift.
  4. Existing Ecto contexts (`Admin.Items`, `/library-beta`, ...) move onto Ash when they are next touched or ported. Until then, any read that authorizes goes through Ash, because Ecto queries on the same tables bypass policies. Oban's tables stay Ecto-managed.
- **Schema alignment** needed now: the `ash-functions` migration, and a `btree_gist` composite index on `item_membership (account_id, item_path)`. On production data it halves the permission lookup behind the home list (81 ms to 35 ms for the heaviest account). The membership model itself doesn't change.
- **Costs we accept**: about 13 extra packages including a C NIF, about 46 s more on a clean build and 1.5 s to recompile after editing a resource, larger generated SQL, and tracking Ash's security advisories. Changing the custom-expression list recompiles the `ash` dependency.
