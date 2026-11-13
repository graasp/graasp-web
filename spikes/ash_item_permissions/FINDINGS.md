# Findings: Ash vs plain Ecto for item permissions (graasp-web#318)

Measured 2026-11-13 on ash 3.37.4, ash_postgres 2.15.2, ecto 3.14.3, Postgres 18, Apple Silicon.

## Correctness: both match core

Reference: a line-by-line port of core's `AuthorizedItemService` and `_filterOutItems` (`lib/spike/core_oracle.ex`).
Seed: 15 items, 7 accounts (member, guest, unvalidated member), hidden and public visibilities at several levels, a soft-deleted item, and a membership that breaks the no-downgrade invariant.

| check | cases | Ash v1 | Ash v2 | plain Ecto |
|---|---|---|---|---|
| decision incl. error kind (`ok` / `member_cannot_access` / `member_cannot_read|write|admin`) | 360 | 0 mismatches | 0 | 0 |
| children (assert parent, drop hidden unless write+) | 64 | 0 | 0 | 0 |
| filter by min permission | 24 | 0 | 0 | 0 |
| queries per batch decision | | 1 | 1 | 1 |

See `priv/matrix_output.txt`.

## Performance (610k items, 60k memberships, 15.7k visibilities)

| operation | core (2 queries) | Ash v1 (inlined `exists`) | Ash v2 (aggregates) | plain Ecto |
|---|---|---|---|---|
| one item, SQL execution | 0.10 + 0.03 ms | 0.07 ms, 15 subplans, 4.8 KB SQL | | 0.06 ms, 0 subplans, 0.9 KB SQL |
| one item, end to end in Elixir | | 5.6 ms | 3.2 ms | 1.35 ms |
| batch of 50, end to end | | 5.5 ms | 4.0 ms | 3.2 ms |
| children of a folder, SQL | | 0.2 + 0.4 ms | | 0.2 + 0.5 ms |
| min-permission filter, scanning all 610k items | | > 300 s (killed) | > 300 s (killed) | 17.6 s |
| min-permission filter, narrowed to the actor's membership subtrees first | | | 51 ms | 16 ms |

- Bounded reads (one item, batch, children) are fine on both sides.
- Unbounded filters have to start from the actor's memberships, as core's `getAccessibleItems` does, whichever side you pick.
- Planner traps on the Ash side:
  - `:utc_datetime_usec` attributes render as `col::timestamp` while core's columns are `timestamptz`. The cast breaks row estimates (3k estimated against 610k actual), and Postgres then picks a sequential scan of `item_visibility` per row. Use `AshPostgres.TimestamptzUsec`.
  - A calculation that references another calculation is inlined at every reference. v1 `access` expands to 12 membership `EXISTS` subqueries. Aggregates over `no_attributes?` relationships (v2) give one lateral join instead.
  - Every column reference is cast (`::ltree`, `::uuid`). That was harmless here, but it is SQL nobody wrote.

## Answers to the research ticket's open questions

1. **One calculation for decision and error kind, one query per batch**: yes. The same expression serves as the policy (`authorize_if expr(access_v2(required: "read") == "ok")`) and as the loaded calculation that controllers map to core's errors.
   - A filter policy turns a forbidden `get` into `NotFound`, so a controller loads the calculation with `authorize?: false` to answer with core's error.
   - `matchOne(validatedMember, guest)` works as a second policy (checks inside a policy are ORed, policies are ANDed). The `Forbidden` error lists every policy, not the one that failed, so core's `NotValidatedMember` vs `InsufficientPermission` can't be recovered from it; the check would stay a plug.
2. **`nil` actor**: `^actor(:id)` becomes `account_id = NULL::uuid`, which is never true, so the result is correct with no branch. Plain Ecto forbids `== ^nil`, so it needs an explicit signed-out branch. Plans are above; full plans are in `priv/explain_output.txt`.
3. **`belongs_to` / `has_many` over ltree foreign keys**: work (`attribute_type: AshPostgres.Ltree`).
   - Ltree arguments inside `fragment` need `type(^arg, AshPostgres.Ltree)`. Plain Ecto has the same papercut with `type(^p, EctoLtree.LabelTree)`.
   - `AshPostgres.Ltree` represents paths as segment lists while admin uses `%EctoLtree.LabelTree{}`, so the same column would have two Elixir representations in one app. Both decode from the same Postgrex text format, so they share one repo without conflict.
4. **Compile cost** (spike: 4 resources):
   - clean build, deps and app: 46 s wall, 114 s CPU;
   - app only, `--force`: 10.2 s;
   - editing one resource: 1.5 to 1.7 s (2 or 3 files recompile).
   - Extra packages: ash, ash_sql, ash_postgres, spark, reactor, splode, crux, ets, iterex, stream_data, yaml_elixir/yamerl/ymlr, and **picosat_elixir (a C NIF; policies need a SAT solver)**.
   - Ash also requires `config :ash, default_string_length_count: ...`.
5. **Ecto 3.14 in admin**: blocked only by `{:poison, "~> 6.0"}`, which pins `decimal ~> 2.1` while ecto_sql 3.14 needs `decimal ~> 3.0`.
   - Poison isn't referenced in admin's code; it's ex_aws's default JSON codec.
   - Dropping it and setting `config :ex_aws, json_codec: Jason` upgrades ecto 3.14.3, ecto_sql 3.14.0, decimal 3.2.0, postgrex 0.22.4 and db_connection 2.10.2.
   - With that, `mix compile --warnings-as-errors` passes and all **464 tests pass, 0 failures** (worktree, separate test DB). This is worth doing whatever the decision.

## Other observations

- Native enum columns (`permission_enum`, `item_visibility_type`, `account_type_enum`) compare fine with `:string` attributes on both sides, because parameters go untyped.
- `base_filter expr(is_nil(deleted_at))` reproduces core's soft-delete filter on every Ash read.
- Policies only guard calls that go through Ash. An `Ecto.Query` over the same table (an Ash resource *is* an Ecto schema) bypasses them silently.
- Plain Ecto keeps the decision in one place too: one `dynamic` CASE (`Spike.Plain.access/1`) reused in `select` (error kind) and `where` (filter). Ecto only allows dynamics at the top level of `select`, hence the map of dynamics.
