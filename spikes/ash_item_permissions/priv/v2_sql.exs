# PROTOTYPE: print SQL + plan (no ANALYZE) of the unbounded reads
alias Spike.{Plain, Repo}
alias Spike.Items.{Account, Item}
require Ash.Query
actor = Account |> Ash.Query.filter(name == "bulk8") |> Ash.read_one!(authorize?: false)
:ets.new(:cap, [:named_table, :public, :bag])
:telemetry.attach("cap", [:spike, :repo, :query], fn _, _, m, _ -> :ets.insert(:cap, {:q, m.query, m.params}) end, nil)
# capture without running the slow query: statement_timeout aborts it after capture
Repo.query!("SET statement_timeout = 200")
try do
  Item |> Ash.Query.for_read(:accessible_v2, %{min_permission: "write"}, actor: actor) |> Ash.read!(authorize?: false)
rescue _ -> :ok end
try do
  Plain.accessible(actor.id, "write")
rescue _ -> :ok end
Repo.query!("SET statement_timeout = 0")
for {:q, sql, params} <- :ets.lookup(:cap, :q), String.contains?(sql, "item") do
  IO.puts("\n===== SQL (#{byte_size(sql)}B)\n#{sql}\n-- plan:")
  Repo.query!("EXPLAIN " <> sql, params).rows |> Enum.map(&hd/1) |> Enum.take(40) |> Enum.each(&IO.puts/1)
end
