# PROTOTYPE: Spike.Native timings on bulk data (heavy account bulk9, 2050 memberships)
alias Spike.Native.Item
require Ash.Query
actor = Spike.Items.Account |> Ash.Query.filter(name == "bulk9") |> Ash.read_one!(authorize?: false)
id = fn n -> (Item |> Ash.Query.filter(name == ^n) |> Ash.read_one!(authorize?: false)).id end
item = id.("r101c3g2")
parent = Item |> Ash.Query.filter(name == "r101c3") |> Ash.read_one!(authorize?: false)
batch = Item |> Ash.Query.filter(fragment("? <@ 'r101'::ltree", path)) |> Ash.Query.limit(50) |> Ash.read!(authorize?: false) |> Enum.map(& &1.id)
t = fn label, f ->
  f.()
  {us, r} = Enum.reduce(1..5, {0, nil}, fn _, {acc, _} -> {u, r} = :timer.tc(f); {acc + u, r} end)
  IO.puts("#{String.pad_trailing(label, 50)} #{Float.round(us / 5000, 2)} ms  #{r}")
end
t.("get one + permission, authorize_with: :error", fn ->
  {:ok, i} = Ash.get(Item, item, actor: actor, authorize_with: :error, load: [:permission])
  "permission=#{i.permission}"
end)
t.("get forbidden item (403 path)", fn ->
  {:error, %Ash.Error.Forbidden{}} = Ash.get(Item, id.("r1c1g1"), actor: actor, authorize_with: :error); "forbidden"
end)
t.("batch of 50, filter policy, + permission", fn ->
  Item |> Ash.Query.filter(id in ^batch) |> Ash.Query.load(:permission) |> Ash.read!(actor: actor) |> length() |> then(&"#{&1} rows")
end)
t.("children of a folder (filter policy) + permission", fn ->
  p = parent.path
  Item
  |> Ash.Query.filter(fragment("? <@ ?", path, type(^p, AshPostgres.Ltree)) and fragment("nlevel(?) = nlevel(?) + 1", path, type(^p, AshPostgres.Ltree)))
  |> Ash.Query.load(:permission) |> Ash.read!(actor: actor) |> length() |> then(&"#{&1} rows")
end)
t.("home: top-most own memberships (core: 292 ms)", fn ->
  Item |> Ash.Query.for_read(:home, %{}, actor: actor) |> Ash.read!() |> length() |> then(&"#{&1} rows")
end)
t.("home, first page of 24 sorted by name", fn ->
  Item |> Ash.Query.for_read(:home, %{}, actor: actor) |> Ash.Query.sort(:name) |> Ash.read!(page: [limit: 24, count: true]) |> then(&"#{length(&1.results)} of #{&1.count}")
end)
