# PROTOTYPE: SPIKE_DB=graasp_prod_snapshot_prototype mix run priv/prod_native_timing.exs
# Spike.Native on the production snapshot, account with the most folder memberships. Prints counts and times only.
alias Spike.Native.Item
require Ash.Query
%{rows: [[a]]} = Spike.Repo.query!("SELECT m.account_id FROM item_membership m JOIN item i ON i.path = m.item_path AND i.type = 'folder' AND i.deleted_at IS NULL GROUP BY 1 ORDER BY count(*) DESC LIMIT 1")
actor = %{id: Ecto.UUID.cast!(a)}
%{rows: [[deep]]} = Spike.Repo.query!("SELECT i.id FROM item_membership m JOIN item i ON i.path <@ m.item_path WHERE m.account_id = $1 AND i.deleted_at IS NULL ORDER BY nlevel(i.path) DESC LIMIT 1", [a])
deep = Ecto.UUID.cast!(deep)
%{rows: [[folder]]} = Spike.Repo.query!("SELECT p.id FROM item_membership m JOIN item c ON c.path <@ m.item_path AND c.deleted_at IS NULL JOIN item p ON p.path = subpath(c.path, 0, nlevel(c.path) - 1) AND p.type = 'folder' WHERE m.account_id = $1 GROUP BY p.id ORDER BY count(*) DESC LIMIT 1", [a])
folder = Ecto.UUID.cast!(folder)
t = fn label, f ->
  f.()
  {us, r} = Enum.reduce(1..5, {0, nil}, fn _, {acc, _} -> {u, r} = :timer.tc(f); {acc + u, r} end)
  IO.puts("#{String.pad_trailing(label, 46)} #{Float.round(us / 5000, 2)} ms  #{r}")
end
t.("get deepest item + permission", fn ->
  case Ash.get(Item, deep, actor: actor, authorize_with: :error, load: [:permission]) do
    {:ok, i} -> "permission=#{i.permission}"
    {:error, e} -> inspect(e.__struct__)
  end
end)
t.("children of their biggest folder + permission", fn ->
  {:ok, p} = Ash.get(Item, folder, actor: actor, authorize_with: :error)
  pp = p.path
  Item
  |> Ash.Query.filter(fragment("? <@ ?", path, type(^pp, AshPostgres.Ltree)) and fragment("nlevel(?) = nlevel(?) + 1", path, type(^pp, AshPostgres.Ltree)))
  |> Ash.Query.load(:permission) |> Ash.read!(actor: actor) |> length() |> then(&"#{&1} rows")
end)
t.("home, first page of 24 + count", fn ->
  Item |> Ash.Query.for_read(:home, %{}, actor: actor) |> Ash.Query.sort(:name) |> Ash.Query.load(:permission)
  |> Ash.read!(page: [limit: 24, count: true]) |> then(&"#{length(&1.results)} of #{&1.count}")
end)
