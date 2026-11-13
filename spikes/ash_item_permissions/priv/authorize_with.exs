# PROTOTYPE: what does authorize_with: :error return for exists-but-forbidden vs missing?
alias Spike.Items.{Account, Item}
require Ash.Query
by = fn n -> Item |> Ash.Query.filter(name == ^n) |> Ash.read_one!(authorize?: false) end
erin = Account |> Ash.Query.filter(name == "erin") |> Ash.read_one!(authorize?: false)
bob = Account |> Ash.Query.filter(name == "bob") |> Ash.read_one!(authorize?: false)
show = fn label, r ->
  s = case r do
    {:ok, i} -> "ok #{i.name}"
    {:error, %{errors: [e | _]} = top} -> "#{inspect(top.__struct__)} / #{inspect(e.__struct__)}"
  end
  IO.puts(String.pad_trailing(label, 52) <> s)
end
show.("erin get C (exists, no access), filter", Ash.get(Item, by.("C").id, actor: erin))
show.("erin get C, authorize_with: :error", Ash.get(Item, by.("C").id, actor: erin, authorize_with: :error))
show.("erin get missing id, authorize_with: :error", Ash.get(Item, Ecto.UUID.generate(), actor: erin, authorize_with: :error))
show.("bob get a1x (read member, hidden), :error", Ash.get(Item, by.("a1x").id, actor: bob, authorize_with: :error))
show.("bob get a1y (read member), :error", Ash.get(Item, by.("a1y").id, actor: bob, authorize_with: :error))
show.("anon get a2 (public), :error", Ash.get(Item, by.("a2").id, actor: nil, authorize_with: :error))
ids = Enum.map(~w(a1y a1x), &by.(&1).id)
r = Item |> Ash.Query.filter(id in ^ids) |> Ash.read(actor: bob, authorize_with: :error)
show.("bob batch [a1y, a1x], :error", case r do {:ok, l} -> {:ok, %{name: inspect(Enum.map(l, & &1.name))}}; e -> e end)
