# PROTOTYPE: mix run priv/native_matrix.exs — "Ash all the way" (Spike.Native) vs core's oracle
alias Spike.{CoreOracle, Repo}
alias Spike.Native.Item
require Ash.Query

seed = fn q -> Ash.Query.filter(q, fragment("subpath(?, 0, 1) IN ('A', 'B', 'C')", path)) end
accounts = Spike.Items.Account |> Ash.Query.filter(not contains(name, "bulk")) |> Ash.read!(authorize?: false) |> Enum.sort_by(& &1.name)
actors = [nil | accounts]
aname = fn nil -> "anon"; a -> a.name end
items = Item |> seed.() |> Ash.Query.sort(:path) |> Ash.read!(authorize?: false)
pstr = &Enum.join(&1, ".")

oracle_highest = fn nil, _ -> nil
  a, path ->
    Repo.query!("select max(permission)::text from item_membership where account_id = $1 and item_path @> $2::ltree", [Ecto.UUID.dump!(a.id), path]).rows |> hd() |> hd()
end
names = fn action, actor -> Item |> seed.() |> Ash.Query.for_read(action, %{}, actor: actor) |> Ash.read!() |> Enum.map(& &1.name) |> Enum.sort() end
ok_names = fn actor, req -> items |> Enum.filter(&(CoreOracle.decide(actor && actor.id, pstr.(&1.path), req) == "ok")) |> Enum.map(& &1.name) |> Enum.sort() end

bad =
  for actor <- actors, reduce: [] do
    acc ->
      acc = for {action, req} <- [read: "read", as_writer: "write", as_admin: "admin"], (n = names.(action, actor)) != (o = ok_names.(actor, req)), reduce: acc, do: (acc -> [{aname.(actor), action, :ash, n, :core, o} | acc])
      perms = Item |> seed.() |> Ash.Query.load(:permission) |> Ash.read!(actor: actor, authorize?: false)
      acc = for i <- perms, (p = i.permission && to_string(i.permission)) != (o = oracle_highest.(actor, pstr.(i.path))), reduce: acc, do: (acc -> [{aname.(actor), i.name, :permission, p, :core, o} | acc])
      for i <- items, reduce: acc do
        acc ->
          got = case Ash.get(Item, i.id, actor: actor, authorize_with: :error) do
            {:ok, _} -> "ok"
            {:error, %Ash.Error.Forbidden{}} -> "forbidden"
            {:error, e} -> inspect(e.__struct__)
          end
          want = if CoreOracle.decide(actor && actor.id, pstr.(i.path), "read") == "ok", do: "ok", else: "forbidden"
          if got == want, do: acc, else: [{aname.(actor), i.name, :get, got, :core, want} | acc]
      end
  end
IO.puts("== Spike.Native vs core: #{length(actors)} actors x #{length(items)} items: read/write/admin sets, packed permission, get 403 vs ok")
IO.puts("   mismatches: #{length(bad)}")
for b <- Enum.reverse(bad), do: IO.inspect(b)

home_bad =
  for a <- accounts, reduce: [] do
    acc ->
      n = Item |> seed.() |> Ash.Query.for_read(:home, %{}, actor: a) |> Ash.read!() |> Enum.map(& &1.name) |> Enum.sort()
      o = Repo.query!("""
      SELECT i.name FROM item_membership m JOIN item i ON i.path = m.item_path AND i.deleted_at IS NULL
      WHERE m.account_id = $1 AND subpath(i.path, 0, 1) IN ('A','B','C') AND NOT EXISTS (
        SELECT 1 FROM item_membership p WHERE p.account_id = m.account_id AND p.item_path @> m.item_path AND p.item_path <> m.item_path)
      """, [Ecto.UUID.dump!(a.id)]).rows |> Enum.map(&hd/1) |> Enum.sort()
      if n == o, do: acc, else: [{a.name, n, o} | acc]
  end
IO.puts("== home (top-most own memberships): #{length(accounts)} accounts, mismatches: #{length(home_bad)}")
for b <- home_bad, do: IO.inspect(b)
