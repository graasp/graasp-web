# PROTOTYPE: time the unbounded "filter by permission" read on bulk data
alias Spike.Plain
alias Spike.Items.{Account, Item}
require Ash.Query
actor = Account |> Ash.Query.filter(name == "bulk8") |> Ash.read_one!(authorize?: false)
t = fn label, f -> {us, r} = :timer.tc(f); IO.puts("#{String.pad_trailing(label, 44)} #{Float.round(us / 1000, 1)} ms, #{length(r)} rows") end
ash = fn action -> fn -> Item |> Ash.Query.for_read(action, %{min_permission: "write"}, actor: actor) |> Ash.read!(authorize?: false) end end
t.("ash v3 narrowed + aggregates", ash.(:accessible_v3))
t.("plain narrowed", fn -> Plain.accessible_narrowed(actor.id, "write") end)
t.("ash v2 aggregates, timestamptz, 610k scan", ash.(:accessible_v2))
t.("plain 610k scan", fn -> Plain.accessible(actor.id, "write") end)
