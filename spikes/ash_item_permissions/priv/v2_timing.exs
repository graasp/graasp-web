# PROTOTYPE: v1 (inlined EXISTS) vs v2 (aggregates) on bulk data
alias Spike.Plain
alias Spike.Items.{Account, Item}
require Ash.Query
actor = Account |> Ash.Query.filter(name == "bulk8") |> Ash.read_one!(authorize?: false)
item = Item |> Ash.Query.filter(name == "r1c1g2") |> Ash.read_one!(authorize?: false)
batch = Item |> Ash.Query.filter(fragment("? <@ 'r1'::ltree", path)) |> Ash.Query.limit(50) |> Ash.read!(authorize?: false) |> Enum.map(& &1.id)
t = fn label, f -> f.(); {us, r} = :timer.tc(f); IO.puts("#{String.pad_trailing(label, 36)} #{Float.round(us / 1000, 2)} ms  #{inspect(r, limit: 3)}") end
load = fn calc, ids, a -> Item |> Ash.Query.filter(id in ^ids) |> Ash.Query.load([{calc, %{required: "write"}}]) |> Ash.read!(actor: a, authorize?: false) |> Enum.map(&Map.get(&1, calc)) |> Enum.frequencies() end
t.("v1 one item", fn -> load.(:access, [item.id], actor) end)
t.("v2 one item", fn -> load.(:access_v2, [item.id], actor) end)
t.("plain one item", fn -> Plain.access_for(actor.id, [item.id], "write") |> Map.values() end)
t.("v1 batch 50", fn -> load.(:access, batch, actor) end)
t.("v2 batch 50", fn -> load.(:access_v2, batch, actor) end)
t.("plain batch 50", fn -> Plain.access_for(actor.id, batch, "write") |> Map.values() |> Enum.frequencies() end)
t.("v2 accessible(write) 610k", fn -> Item |> Ash.Query.for_read(:accessible_v2, %{min_permission: "write"}, actor: actor) |> Ash.read!(authorize?: false) |> length() end)
q = Item |> Ash.Query.filter(id in ^batch) |> Ash.Query.load(access_v2: %{required: "write"}) |> Ash.Query.set_context(%{private: %{actor: actor}})
{:ok, eq} = Ash.Query.data_layer_query(Ash.Query.for_read(q, :read, %{}, actor: actor, authorize?: false))
{sql, _} = Spike.Repo.to_sql(:all, eq)
IO.puts("\nv2 SQL (#{byte_size(sql)}B):\n" <> sql)
