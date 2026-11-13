# PROTOTYPE runner: mix run priv/matrix.exs
# Compares core's decision (oracle) with the Ash and plain-Ecto spikes.
alias Spike.{AshApi, CoreOracle, Plain}
alias Spike.Items.{Account, Item, ItemMembership}
require Ash.Query

# count SQL queries per call
:ets.new(:q, [:named_table, :public])
:ets.insert(:q, {:n, 0})
:telemetry.attach("count", [:spike, :repo, :query], fn _, _, _, _ -> :ets.update_counter(:q, :n, 1) end, nil)
counted = fn f ->
  :ets.insert(:q, {:n, 0})
  r = f.()
  [{:n, n}] = :ets.lookup(:q, :n)
  {r, n}
end

accounts = Ash.read!(Account, authorize?: false) |> Enum.sort_by(& &1.name)
actors = [nil | accounts]
aname = fn nil -> "anon"; a -> a.name end
items = Item |> Ash.Query.sort(:path) |> Ash.read!(authorize?: false)
pathstr = fn p -> Enum.join(p, ".") end
by_name = Map.new(items, &{&1.name, &1})
ids = Enum.map(items, & &1.id)

IO.puts("== base filter: soft-deleted a4 visible? #{Map.has_key?(by_name, "a4")}")

# --- 1. decision matrix ------------------------------------------------------
mismatches =
  for actor <- actors, req <- ~w(read write admin), reduce: [] do
    acc ->
      {ash_v1, _} = counted.(fn -> AshApi.access_for(actor, ids, req, :access) end)
      {ash, ash_q} = counted.(fn -> AshApi.access_for(actor, ids, req) end)
      {plain, plain_q} = counted.(fn -> Plain.access_for(actor && actor.id, ids, req) end)
      if ash_q != 1 or plain_q != 1, do: IO.puts("!! #{aname.(actor)}/#{req}: ash #{ash_q} queries, plain #{plain_q}")

      Enum.reduce(items, acc, fn item, acc ->
        oracle = CoreOracle.decide(actor && actor.id, pathstr.(item.path), req)
        a = ash[item.id]
        p = plain[item.id]
        v1 = ash_v1[item.id]
        if oracle == a and oracle == p and oracle == v1, do: acc, else: [{aname.(actor), req, item.name, oracle, v1, a, p} | acc]
      end)
  end

IO.puts("== decision matrix: #{length(actors) * 3 * length(items)} cases (actors x permission x items), batch = 1 query each side, mismatches: #{length(mismatches)}")
for m <- Enum.reverse(mismatches), do: IO.inspect(m, label: "  (actor, required, item, core, ash_v1, ash_v2, plain)")

IO.puts("\n   read decisions per actor (core == ash == plain unless listed above):")
for actor <- actors do
  row = AshApi.access_for(actor, ids, "read")
  cells = Enum.map(items, fn i -> "#{i.name}:" <> (row[i.id] |> String.replace("member_cannot_", "x-")) end)
  IO.puts("   #{String.pad_trailing(aname.(actor), 6)} " <> Enum.join(cells, " "))
end

# --- 2. children ------------------------------------------------------------
folders = Enum.filter(items, &(&1.type == "folder"))
child_mismatches =
  for actor <- actors, f <- folders, reduce: [] do
    acc ->
      o = CoreOracle.children(actor && actor.id, pathstr.(f.path))
      a = AshApi.children(actor, f.id)
      p = Plain.children(actor && actor.id, f.id)
      if o == a and o == p, do: acc, else: [{aname.(actor), f.name, o, a, p} | acc]
  end
IO.puts("\n== children: #{length(actors) * length(folders)} cases, mismatches: #{length(child_mismatches)}")
for m <- Enum.reverse(child_mismatches), do: IO.inspect(m, label: "  (actor, parent, core, ash, plain)")
IO.inspect(AshApi.children(Enum.find(accounts, &(&1.name == "carol")), by_name["a2"].id), label: "   carol children of a2")
IO.inspect(AshApi.children(nil, by_name["a2"].id), label: "   anon children of a2")

# --- 3. filter by permission ---------------------------------------------------
acc_mismatches =
  for actor <- actors, req <- ~w(read write admin), reduce: [] do
    acc ->
      o = items |> Enum.filter(&(CoreOracle.decide(actor && actor.id, pathstr.(&1.path), req) == "ok")) |> Enum.map(& &1.name) |> Enum.sort()
      a = AshApi.accessible(actor, req) |> Enum.sort()
      p = Plain.accessible(actor && actor.id, req) |> Enum.sort()
      if o == a and o == p, do: acc, else: [{aname.(actor), req, o, a, p} | acc]
  end
IO.puts("\n== accessible(min_permission): #{length(actors) * 3} cases, mismatches: #{length(acc_mismatches)}")
for m <- Enum.reverse(acc_mismatches), do: IO.inspect(m, label: "  (actor, min, core, ash, plain)")

# --- 4. policy errors -------------------------------------------------------------
IO.puts("\n== what the authorized read does with an inaccessible item (erin, item C)")
erin = Enum.find(accounts, &(&1.name == "erin"))
IO.inspect(Ash.get(Item, by_name["C"].id, actor: erin), label: "   Ash.get (filter policy)", limit: 3, printable_limit: 200)
IO.inspect(Ash.get(Item, by_name["C"].id, actor: erin, authorize_with: :error) |> elem(0), label: "   Ash.get authorize_with: :error")

IO.puts("\n== matchOne(validatedMember, guest) as a second policy")
for actor <- actors do
  r = Item |> Ash.Query.for_read(:for_validated_member_or_guest, %{}, actor: actor) |> Ash.read()
  case r do
    {:ok, rows} -> IO.puts("   #{aname.(actor)}: ok, #{length(rows)} rows")
    {:error, %Ash.Error.Forbidden{errors: [e | _]}} ->
      failed = e |> Map.get(:policies, []) |> Enum.map(& &1.description)
      IO.puts("   #{aname.(actor)}: forbidden #{inspect(e.__struct__)}; policy descriptions on the error: #{inspect(failed)}")
    {:error, e} -> IO.puts("   #{aname.(actor)}: #{inspect(e.__struct__)}")
  end
end

# --- 5. ltree relationships (Q3) --------------------------------------------------
IO.puts("\n== Q3 ltree foreign keys")
m = ItemMembership |> Ash.Query.load(:item) |> Ash.read!(authorize?: false) |> Enum.take(3)
IO.inspect(Enum.map(m, &{&1.permission, &1.item && &1.item.name}), label: "   membership belongs_to item")
a = by_name["A"] |> Ash.load!(:memberships, authorize?: false)
IO.inspect(Enum.map(a.memberships, & &1.permission), label: "   item A has_many memberships")
