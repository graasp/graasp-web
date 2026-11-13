defmodule Spike.Plain.ItemVisibility do
  @moduledoc "PROTOTYPE: plain Ecto schema for `item_visibility`."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "item_visibility" do
    field :type, :string
    field :item_path, EctoLtree.LabelTree
  end
end
