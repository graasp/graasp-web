defmodule Spike.AshApi do
  @moduledoc """
  PROTOTYPE: what a ported controller would call on the Ash side.

  Policies decide *which* rows; the `access` calculation says *why not*, so the
  controller can answer with core's exact error.
  """
  require Ash.Query
  alias Spike.Items.Item

  @doc "decision for many items in one query: %{id => decision}"
  def access_for(actor, ids, required, calc \\ :access_v2) do
    Item
    |> Ash.Query.filter(id in ^ids)
    |> Ash.Query.load([{calc, %{required: required}}])
    |> Ash.read!(actor: actor, authorize?: false)
    |> Map.new(&{&1.id, Map.get(&1, calc)})
  end

  def get_item(actor, id, required \\ "read") do
    Item
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.load(access_v2: %{required: required})
    |> Ash.read_one!(actor: actor, authorize?: false)
    |> case do
      nil -> {:error, :not_found}
      %{access_v2: "ok"} = item -> {:ok, item}
      %{access_v2: error} -> {:error, error}
    end
  end

  def children(actor, parent_id) do
    with {:ok, parent} <- get_item(actor, parent_id) do
      Item
      |> Ash.Query.for_read(:children, %{parent_path: parent.path}, actor: actor)
      |> Ash.read!()
      |> Enum.map(& &1.name)
      |> then(&{:ok, &1})
    end
  end

  def accessible(actor, min_permission) do
    Item
    |> Ash.Query.for_read(:accessible_v2, %{min_permission: min_permission}, actor: actor)
    |> Ash.read!()
    |> Enum.map(& &1.name)
  end
end
