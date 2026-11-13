defmodule Spike.Plain.ItemMembership do
  @moduledoc "PROTOTYPE: plain Ecto schema for `item_membership`."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "item_membership" do
    field :permission, :string
    field :item_path, EctoLtree.LabelTree
    field :account_id, :binary_id
  end
end
