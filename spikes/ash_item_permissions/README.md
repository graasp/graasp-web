# PROTOTYPE: Ash spike for item permissions (graasp-web#318)

Throwaway. Never merged. Lives on the `research/ash-spike` branch only.

Question: does Ash's policy system express Graasp's permission model cleanly on core's
existing tables, compared with the same slice in plain Ecto?

## Run

```sh
# scratch DB with core's schema (core drizzle migrations 0000-0021, applied with psql)
createdb graasp_ash_spike_prototype
for f in ../../../core/src/drizzle/00*.sql; do sed 's/--> statement-breakpoint/;/' $f | psql -q -v ON_ERROR_STOP=1 -d graasp_ash_spike_prototype; done
psql -d graasp_ash_spike_prototype -f priv/seed.sql   # decision cases
mix deps.get
mix run priv/matrix.exs                                # core oracle vs Ash vs plain Ecto
psql -d graasp_ash_spike_prototype -f priv/bulk.sql   # ~610k items, for plans/timings
mix run priv/explain.exs && mix run priv/v2_timing.exs && mix run priv/accessible_timing.exs
```

## Layout

- `lib/spike/core_oracle.ex`: line-by-line port of core's `AuthorizedItemService` + `_filterOutItems` (reference).
- `lib/spike/items/*.ex`: Ash resources over `item`, `item_membership`, `item_visibility`, `account` (`migrate? false`).
  - `access` (v1): decision as a calculation built from `exists(...)` calculations.
  - `access_v2`: same decision on aggregates over `no_attributes?` relationships (the policy uses this one).
- `lib/spike/ash_api.ex`: what a ported controller would call.
- `lib/spike/plain.ex`: the same slice in plain Ecto (lateral joins + one SQL CASE).
- `priv/*_output.txt`: captured results.
