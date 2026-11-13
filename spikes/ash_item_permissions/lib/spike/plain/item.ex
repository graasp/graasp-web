defmodule Spike.Plain.Item do
  @moduledoc "PROTOTYPE: plain Ecto schema, shaped like admin's `Admin.Items.Item`."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "item" do
    field :name, :string
    field :type, :string
    field :path, EctoLtree.LabelTree
    field :order, :decimal
    field :deleted_at, :utc_datetime_usec
    field :created_at, :utc_datetime_usec
  end
end
