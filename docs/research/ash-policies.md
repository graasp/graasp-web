# Research: Ash policies and AshPostgres over existing tables

Answers graasp/graasp-web#313, part of the wayfinder map #312. It feeds the Ash spike (#318).

Versions checked (November 2026): **ash 3.37.4**, **ash_postgres 2.15.2**, **ash_sql 0.8.8**. Sources are the official hexdocs (`ash.hexdocs.pm`, `ash-postgres.hexdocs.pm`), the `ash-project` GitHub repos, core's code in `~/github/graasp/core` and admin's `lib/admin/items*`.

Each fact is marked with its source. **[Inference]** marks conclusions drawn from those facts, not stated by any source. **[Unverified]** marks things the spike has to confirm.

## TL;DR

1. **Policies can express the rule.** Graasp's permission model can be written as one Ash filter expression: ltree `@>` through `fragment`, `exists` over a resource with no relationship, and `parent/1`. Role checks like `matchOne` map onto Ash's builtin checks. The hard part is the **error contract**, not the rule. Core returns distinct errors (`MemberCannotAccess`, `MemberCannotReadItem`/`Write`/`Admin`) and per-item `ResultOf` errors. Ash filter policies on reads quietly drop rows, and forbidden actions raise a generic policy error. Reproducing core's responses means computing the reason separately, for example with a calculation.
2. **AshPostgres works on tables it doesn't migrate.** `migrate? false` per resource, explicit names for constraints and indexes, `view? true` for `item_view`, a native `ltree` type and Postgres enum types via `storage_type`. `AshPostgres.Repo` is a thin wrapper around `Ecto.Repo`. Ecto migrations can stay the only schema source (ADR 0002), with one catch: AshPostgres needs its own SQL functions (`ash_raise_error`, `ash_elixir_or`, ...) installed by a migration.
3. **Cost.** About eight new runtime packages (ash, ash_sql, ash_postgres, spark, reactor, splode, stream_data, crux, ets, plus a SAT solver). Ash needs `ecto ~> 3.14`, and admin locks `ecto 3.13.5`, so Ecto must be upgraded first. No primary source puts a number on compile time, so the spike has to measure it. An Ash resource *is* an Ecto schema, so an Ash resource and admin's existing `Admin.Items.Item` can map the same table side by side. Ash's rules then only apply to calls that go through Ash.

## 1. Can Ash policies express Graasp's item permissions?

### What core actually does

`AuthorizedItemService.getPropertiesForItem` (`core/src/services/authorizedItem.service.ts`):

- **Highest inherited membership.** `ItemMembershipRepository.getInherited` joins `item_membership` to `item` on `item_membership.item_path @> :itemPath` (ancestor or self, `core/src/drizzle/operations.ts` `isAncestorOrSelf`). It then reduces the rows to the *highest* permission. `getInheritedMany`, the batch version, keeps the *closest* membership per item instead, ordered by `nlevel(item_path)` descending.
- **Levels.** `permissionMapping`: `read → [read]`, `write → [read, write]`, `admin → [read, write, admin]`. The database stores them as the `permission_enum` Postgres type, declared in the order `('read','write','admin')` (`core/src/drizzle/schema.ts`).
- **Visibilities.** `ItemVisibilityRepository.getByItemPath` returns every `item_visibility` row whose `item_path @> path`, i.e. on any ancestor or the item itself. The two types are `public` and `hidden`.
- **Decision order:**
  1. **Hidden:** if `highest == read`, or the item is public and the account has no membership, and any ancestor is `hidden`, then `MemberCannotAccess`.
  2. If the highest permission covers the request, allow.
  3. If the request is `read` and any ancestor is `public`, allow, with `itemMembership = null`.
  4. If the account has no membership, `MemberCannotAccess`. Otherwise `MemberCannotRead/Write/AdminItem`.
- **Batch version.** `getPropertiesForItems` returns `ResultOf`, a `data` map plus a per-item `errors` list, and doesn't throw. `ItemService.getMany` and other callers rely on it.
- **Route-level roles.** `matchOne(...strategies)` (`core/src/services/auth/plugins/passport/preHandlers.ts`) passes if *any* strategy's `test(req)` passes. Otherwise it throws that strategy's error if only one was given, or `InsufficientPermission`. The strategies:
  - `memberAccountRole`: account type is `individual`;
  - `validatedMemberAccountRole`: individual and `isValidated`;
  - `guestAccountRole`: account type is `guest`.

Admin currently has **no** item authorization. The `Admin.Items` context takes `%Scope{}` but ignores it (`lib/admin/items.ex`). It already uses ltree through `EctoLtree` and `fragment("? @> ?", ...)`.

### Ash policy mechanics (sources)

- **Combining policies.** All applicable policies must pass. Inside one policy, checks run top to bottom (`authorize_if`, `forbid_if`, `authorize_unless`, `forbid_unless`) and the first decisive one wins. A `bypass` that passes skips the policies after it. ([Policies guide](https://ash.hexdocs.pm/policies.html))
- **Check types.** *Simple* checks give yes or no. *Filter* checks turn into a filter on the query. *Manual* checks exist, but "you will almost always want to write simple or filter checks". ([Policies guide](https://ash.hexdocs.pm/policies.html), [Ash.Policy.FilterCheck](https://ash.hexdocs.pm/Ash.Policy.FilterCheck.html))
- **Access types.** `:filter` (the default) applies checks statically or as a filter. `:strict` requires static checks and returns forbidden instead of filtering. `:runtime` checks the data after reading it. ([Policies guide](https://ash.hexdocs.pm/policies.html))
- **How each action type is authorized:**
  - **Reads:** filter checks are "applied to all read actions". A non-authorized actor gets "an empty list of records, rather than a forbidden error", unless the policy uses `access_type :strict`.
  - **Update and destroy:** the filter "is evaluated against the original loaded record". A mismatch gives forbidden.
  - **Create:** filter checks are evaluated against the inserted record "inside the action's transaction" and roll back on mismatch. Actions with `before_transaction`/`around_transaction` hooks need `allow_post_action_authorization? true`.

  ([Policies guide](https://ash.hexdocs.pm/policies.html))
- **Builtin checks.** They include:
  - `actor_present`, `actor_absent`, `actor_attribute_equals(attr, value)`;
  - `relates_to_actor_via(path)`, `can_read(path)`;
  - `action`, `action_type`, `changing_attributes`, `matches(desc, fun)`.

  `expr(...)` with `^actor(:field)` works as a filter check. ([Ash.Policy.Check.Builtins](https://ash.hexdocs.pm/Ash.Policy.Check.Builtins.html))
- **Field policies.** They exist, and they accept only simple and filter checks. ([Policies guide](https://ash.hexdocs.pm/policies.html))

### Expression support for ltree

- **`fragment`.** For SQL data layers, it is "a string with question marks for interpolation", e.g. `fragment("(? + ?)", foo, bar)`. ([Expressions guide](https://ash.hexdocs.pm/expressions.html)) AshPostgres calls fragments "an escape hatch" for anything Ash has no official support for. ([AshPostgres expressions](https://ash-postgres.hexdocs.pm/expressions.html))
- **`exists/2` without a relationship.** It works on any resource module, not just relationships: "Can also be used with resource modules directly: `exists(SomeResource, name == "fred")`", for example `exists(Profile, name == parent(name))`. Unrelated inline aggregates also work, e.g. `count(Profile, filter: expr(...))`. ([Expressions guide](https://ash.hexdocs.pm/expressions.html))
- **`parent/1`.** It refers to the outer resource from inside `exists` or a relationship filter. ([Expressions guide](https://ash.hexdocs.pm/expressions.html))
- **Relationships with `no_attributes? true`.** They join on a filter instead of matching attributes ("useful when creating customized relationships that aren't joined with simple attribute matches"), using `parent/1` in the filter. ([Relationships guide](https://ash.hexdocs.pm/relationships.html)) This allows a `has_many :ancestor_memberships` that joins on `item_path @> parent(path)`, which aggregates and `exists` can then use.
- **`AshPostgres.Ltree` type.** It needs the `ltree` extension enabled and has `escape?`, `min_length` and `max_length` constraints. Its docs list no ancestor or descendant operators, only `shared_root/2`, so `@>` and `<@` have to go through `fragment`. ([AshPostgres.Ltree](https://ash-postgres.hexdocs.pm/AshPostgres.Ltree.html))
- **Custom expressions.** `Ash.CustomExpression` can wrap the fragment in a named function such as `ancestor_or_self(a, b)`. It is registered in `config :ash, :custom_expressions` and needs `mix deps.compile ash --force`. ([Expressions guide](https://ash.hexdocs.pm/expressions.html))
- **Native Postgres enums.** AshPostgres's own test suite does it with `use Ash.Type.Enum, values: [...]` plus `def storage_type, do: :status` ([`test/support/types/status_enum.ex`](https://github.com/ash-project/ash_postgres/blob/main/test/support/types/status_enum.ex)). `permission_enum` and `item_visibility_type` can be mapped the same way.

### Mapping Graasp's rules **[Inference]**

- **"Highest permission ≥ X" becomes "exists a membership with permission in the allowed set".** This holds as long as core's invariant holds: a membership lower in the tree is never weaker than an inherited one, which `ItemMembershipRepository.patch` enforces by refusing downgrades. A sketch of read access on `Item`:

  ```elixir
  policy action_type(:read) do
    authorize_if expr(
      # write or admin on self or an ancestor: always allowed, hidden or not
      exists(ItemMembership,
        account_id == ^actor(:id) and permission in [:write, :admin] and
          fragment("? @> ?", item_path, parent(path))) or
      # read membership, or public on self or an ancestor, and not hidden anywhere above
      ((exists(ItemMembership,
          account_id == ^actor(:id) and fragment("? @> ?", item_path, parent(path))) or
        exists(ItemVisibility, type == :public and fragment("? @> ?", item_path, parent(path)))) and
       not exists(ItemVisibility, type == :hidden and fragment("? @> ?", item_path, parent(path))))
    )
  end
  ```

  Write and admin are the same `exists` with `[:write, :admin]` or `[:admin]`, and no visibility branch.

  The actor is `nil` for signed-out users. `^actor(:id)` is then `nil` and the membership branch matches nothing, which is what core does ("do not fetch membership for signed out member"). **[Unverified]** How Ash renders `== nil` against a `nil` actor needs a spike test.
- **`matchOne(...)` becomes one policy with several `authorize_if`s**, which already behave as OR. Examples:
  - `authorize_if actor_attribute_equals(:type, :individual)`;
  - `authorize_if expr(^actor(:type) == :individual and ^actor(:is_validated))`;
  - `authorize_if actor_attribute_equals(:type, :guest)`.

  Separate policies would be ANDed together, so they have to stay in one policy.
- **Gap 1: error contract.** Core tells a 403 `MemberCannotAccess` apart from `MemberCannotReadItem` and from hidden, and frontends depend on those codes, since the contract is frozen (#312). Filter checks on reads return empty or not-found. `access_type :strict` returns a generic forbidden. The docs don't show how to attach a different error to each check. **[Unverified]** The likely fix is a calculation, say `:permission_for_actor` built from inline aggregates (`max`/`first` over `ancestor_memberships`, `exists` over visibilities). Controllers map its result to core's error classes, and policies stay a safety net.
- **Gap 2: batch `ResultOf`.** Core lists the denied items *with errors* instead of dropping them. Again, the calculation computed for every requested ID covers this, not a filter policy.
- **Gap 3: the closest vs highest mismatch** between `getInherited` and `getInheritedMany` only shows up when the invariant above is broken. Ash would make both paths behave the same, which differs slightly from core. Contract tests should show whether that matters.
- **Performance.** Every `exists` with a `fragment("? @> ?")` needs the GiST indexes on `item_membership.item_path` and `item_visibility.item_path`, and both exist (`IDX_gist_item_visibility_path`, `IDX_gist_item_membership_path` in `schema.ts`). Core's queries use the same operator, so the plans should be comparable. **[Unverified]** Compare `EXPLAIN` output in the spike.

### Security advisory note

Ash's GitHub advisories include several authorization bugs patched in 2026. One example is GHSA-xj24-8f5c-pp5p: "Ash.count, Ash.exists and Ash.aggregate skip related read policies in user filters", fixed in 3.34.6. Another is GHSA-j8fx-ff37-4j9c: a failed `parent(...)` filter turned into an `IS NULL` match, fixed in 3.32.2. ([ash security advisories](https://github.com/ash-project/ash/security/advisories)) Patches come quickly, but anyone adopting Ash should track these advisories, especially since this design relies on `exists` and `parent`.

## 2. AshPostgres on tables it doesn't migrate

- **`migrate?`.** "Whether or not to include this resource in the generated migrations with `mix ash.generate_migrations`". It is set per resource in the `postgres do ... end` block. ([AshPostgres DSL](https://ash-postgres.hexdocs.pm/dsl-ashpostgres-datalayer.html))
- **Existing constraint names**, so that database errors turn into proper changeset errors and generated names don't clash ([AshPostgres DSL](https://ash-postgres.hexdocs.pm/dsl-ashpostgres-datalayer.html)):
  - `references do reference :rel, name: "FK_item_visibility_item" end` (the default is `<table>_<attr>_fkey`);
  - `identity_index_names [identity: "UQ_item_visibility_item_type"]`;
  - `unique_index_names`, `foreign_key_names`, `exclusion_constraint_names`;
  - `check_constraints` (generated, or just a message).

  This matters because the names really differ: core has `UQ_item_visibility_item_type`, while admin's old partial copy has `item-visibility` (ADR 0002 amendment).
- **Views.** `view? true` "declares that the table is a PostgreSQL view or materialized view. View resources are excluded from generated migrations." Upserts on a view return no `:upsert_action` metadata, because views have no `xmax`. ([AshPostgres DSL](https://ash-postgres.hexdocs.pm/dsl-ashpostgres-datalayer.html)) `item_view` is `SELECT <all item columns except deleted_at> FROM item WHERE deleted_at IS NULL` (`core/src/drizzle/schema.ts`). **[Inference]** Two ways to model it:
  - a read-only `view? true` resource on `item_view`, next to an `Item` resource on `item` for writes;
  - a single resource on `item` with `base_filter is_nil(deleted_at)`. This needs `base_filter_sql` whenever unique indexes are involved.
- **Scaffolding from the existing database.** `mix ash_postgres.gen.resources MyApp.Domain --tables ...` ([Setting AshPostgres up with an existing database](https://ash-postgres.hexdocs.pm/set-up-with-existing-database.html)). Useful flags ([task docs](https://ash-postgres.hexdocs.pm/Mix.Tasks.AshPostgres.Gen.Resources.html)):
  - `--no-migrations`: "Do not generate snapshots & migrations";
  - `--snapshots-only`;
  - `--include-views`: generated resources "use `migrate? false` and default to `[:read]` actions only";
  - `--skip-unknown`: skips columns with unknown types, which may include `ltree`.

  The task generates Elixir code, so running it compiles. Under this repo's no-compile rule, it has to run in a throwaway checkout or a separate project.
- **Ecto migrations as the source of truth.** **[Inference]** Set `migrate? false` on every resource, never run `mix ash.codegen`, and keep writing plain Ecto migrations as ADR 0002 says. The AshPostgres docs don't describe this workflow; they assume `mix ash.codegen` generates the migrations and stores snapshots ([Migrations and tasks](https://ash-postgres.hexdocs.pm/migrations-and-tasks.html), [Get started](https://ash-postgres.hexdocs.pm/get-started-with-ash-postgres.html)).
- **Catch: `ash-functions`.** `installed_extensions` returns `["ash-functions"]` in the getting-started repo because "Ash installs some functions that it needs to run the first time you generate migrations" ([Get started](https://ash-postgres.hexdocs.pm/get-started-with-ash-postgres.html)). The SQL is in [`lib/migration_generator/ash_functions.ex`](https://github.com/ash-project/ash_postgres/blob/main/lib/migration_generator/ash_functions.ex), currently version 7:
  - `ash_elixir_or` and `ash_elixir_and`;
  - `ash_trim_whitespace`;
  - `ash_required`;
  - `ash_raise_error`;
  - `uuid_generate_v7`.

  With codegen off, these must be added through a hand-written (or copied) Ecto migration in admin. Core's `schema.ts` drift check would then see extra functions, which is harmless because it only looks at tables.
- **The repo.** `AshPostgres.Repo` "is a thin wrapper around an Ecto.Repo" and "has all of the same callbacks". It adds `installed_extensions/0`, `min_pg_version/0` and `prefer_transaction?/0`, and `define_ecto_repo?: false` keeps an existing repo module. ([AshPostgres.Repo](https://ash-postgres.hexdocs.pm/AshPostgres.Repo.html)) **[Inference]** Switching `Admin.Repo` to `use AshPostgres.Repo` leaves every existing `Repo.*` call and Ecto schema working.
- **Foreign keys on `path`.** Core's foreign keys point at `item.path`, not `item.id` (`item_membership.item_path → item.path`, `item_visibility.item_path → item.path`). **[Inference]** Ash's `belongs_to :item, Item, source_attribute: :item_path, destination_attribute: :path` should cover this. **[Unverified]** Whether it works with an `AshPostgres.Ltree` attribute needs a spike test.

## 3. Cost

### Dependencies

From each package's `mix.exs` on `main`:

- **ash 3.37.4** runtime deps: `spark ~> 2.7`, `ecto ~> 3.14`, `ets`, `decimal`, `jason`, `telemetry`, `reactor ~> 1.0`, `splode`, `stream_data`, `crux`. Optional: `plug`, `igniter`, and a SAT solver (`picosat_elixir` or `simple_sat`).
- **ash_postgres 2.15.2**: `ash ~> 3.37`, `spark`, `ash_sql ~> 0.8.8`, `ecto_sql ~> 3.13`, `ecto ~> 3.13`, `jason`, `postgrex`, optional `igniter`.
- **ash_sql 0.8.8**: `ash ~> 3.37 and >= 3.37.3`, `ecto_sql`, `ecto ~> 3.13`.

Compared with admin's `mix.lock`:

- `ecto` is at **3.13.5**, below what Ash needs (`~> 3.14`). An Ecto upgrade has to come first.
- `ecto_sql`, `postgrex`, `jason`, `telemetry`, `decimal` and `plug` are already present.
- New: ash, ash_sql, ash_postgres, spark, reactor, splode, stream_data, crux, ets and a SAT solver (`picosat_elixir` is a NIF, `simple_sat` is pure Elixir), plus whatever reactor pulls in. `igniter` is optional but needed by the installers and generators.

### Compile time

No primary source puts a number on it. **[Inference]** Ash resources are Spark DSL modules that are introspected at compile time, so changing a resource recompiles the modules that depend on it at compile time. Policies, calculations and changes referenced from a resource add to that graph. The spike has to measure:

- a clean compile with and without Ash;
- recompiles after editing one resource, with `mix xref graph --label compile-connected`.

This can't run in this checkout (no-compile rule), so it needs a separate clone or CI.

### Ash resources and Ecto schemas on the same table

- **An Ash resource is an Ecto schema.** `Ash.Schema.define_schema` does `use Ecto.Schema` and declares a field for each attribute, so Data Layers can rely on this schema for persistence ([`lib/ash/resource/schema.ex`](https://github.com/ash-project/ash/blob/main/lib/ash/resource/schema.ex)).
- **[Inference]** `Admin.Items.Item` (Ecto) and a new `Admin.Core.Item` (Ash) can both map `item`. Postgres doesn't care, and the two modules don't conflict. The risks are elsewhere:
  - **Duplicated logic.** Path generation and validation in `Item.changeset/2` would need an Ash equivalent.
  - **Policies are bypassed.** Calling `Repo.all(AshResource)` or querying through the Ecto schema skips Ash policies. Policies only protect calls made through `Ash.read`, `Ash.create` and the rest, so the boundary has to be enforced by convention or a Credo check.
  - **Different types.** The ltree column would be `EctoLtree.LabelTree` in the Ecto schema and `AshPostgres.Ltree` in the Ash resource, so values passed between the two need converting.

## Open questions for the spike (#318)

1. Can one `:permission_for_actor` calculation reproduce core's decision, including its error kind, for both single and batch calls, in one SQL query per batch?
2. How do `exists` and `fragment` behave with a `nil` actor, and what do the `EXPLAIN` plans look like next to core's queries?
3. Does `belongs_to` work over `ltree` path foreign keys?
4. How much do clean compiles and recompiles cost, measured outside this checkout?
5. Does the Ecto 3.14 upgrade break anything in admin?
