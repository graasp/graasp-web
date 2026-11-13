# PROTOTYPE: mix run priv/explain.exs  (after priv/bulk.sql)
# Captures the SQL each side emits and runs EXPLAIN ANALYZE on it.
alias Spike.{AshApi, Plain, Repo}
alias Spike.Items.{Account, Item}
require Ash.Query

:ets.new(:cap, [:named_table, :public, :bag])
:telemetry.attach("cap", [:spike, :repo, :query], fn _, _, m, _ ->
  unless String.starts_with?(m.query, "EXPLAIN"), do: :ets.insert(:cap, {:q, m.query, m.params})
end, nil)

out = File.open!("priv/explain_output.txt", [:write])

explain = fn label, f ->
  :ets.delete_all_objects(:cap)
  f.()
  for {:q, sql, params} <- :ets.lookup(:cap, :q) do
    plan = Repo.query!("EXPLAIN (ANALYZE, BUFFERS) " <> sql, params).rows |> Enum.map(&hd/1)
    exec = Enum.find(plan, &String.starts_with?(&1, "Execution Time"))
    subplans = Enum.count(plan, &String.contains?(&1, "SubPlan"))
    seq = plan |> Enum.filter(&String.contains?(&1, "Seq Scan")) |> Enum.map(&String.trim/1) |> Enum.map(&(String.split(&1, "  (") |> hd)) |> Enum.uniq()
    IO.puts("#{String.pad_trailing(label, 44)} #{exec}  subplans=#{subplans}  sql=#{byte_size(sql)}B  seq=#{inspect(seq)}")
    IO.binwrite(out, "\n\n===== #{label}\n#{sql}\n-- params: #{inspect(params)}\n" <> Enum.join(plan, "\n"))
  end
end

actor = Account |> Ash.Query.filter(name == "bulk8") |> Ash.read_one!(authorize?: false)
item = Item |> Ash.Query.filter(name == "r1c1g2") |> Ash.read_one!(authorize?: false)
parent = Item |> Ash.Query.filter(name == "r1c1") |> Ash.read_one!(authorize?: false)
batch = Item |> Ash.Query.filter(fragment("? <@ 'r1'::ltree", path)) |> Ash.Query.limit(50) |> Ash.read!(authorize?: false) |> Enum.map(& &1.id)
path = Enum.join(item.path, ".")
IO.puts("actor bulk8 decision on r1c1g2: ash=#{inspect(AshApi.get_item(actor, item.id) |> elem(0))} plain=#{inspect(Plain.get_item(actor.id, item.id) |> elem(0))}\n")

explain.("core: getInherited + getByItemPath (2 queries)", fn ->
  Repo.query!("""
  select m.* from item_membership m join item i on m.item_path = i.path and m.item_path @> $2::ltree
  join account a on m.account_id = a.id where m.account_id = $1 order by nlevel(m.item_path) desc
  """, [Ecto.UUID.dump!(actor.id), path])
  Repo.query!("select * from item_visibility v where v.item_path @> $1::ltree", [path])
end)
explain.("ash: get one item + access calc", fn -> AshApi.get_item(actor, item.id) end)
explain.("plain: get one item + access", fn -> Plain.get_item(actor.id, item.id) end)
explain.("ash: get one item, anonymous", fn -> AshApi.get_item(nil, item.id) end)
explain.("plain: get one item, anonymous", fn -> Plain.get_item(nil, item.id) end)
explain.("ash: batch of 50 decisions", fn -> AshApi.access_for(actor, batch, "write") end)
explain.("plain: batch of 50 decisions", fn -> Plain.access_for(actor.id, batch, "write") end)
explain.("ash: children (policy filter)", fn -> AshApi.children(actor, parent.id) end)
explain.("plain: children", fn -> Plain.children(actor.id, parent.id) end)
explain.("ash: accessible(write) over 610k items", fn -> AshApi.accessible(actor, "write") end)
explain.("plain: accessible(write) over 610k items", fn -> Plain.accessible(actor.id, "write") end)
File.close(out)
