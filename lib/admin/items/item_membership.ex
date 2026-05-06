defmodule Admin.Items.ItemMembership do
  @moduledoc """
  This represents an item_membership in Graasp
  """
  use Admin.Schema
  import Ecto.Changeset
  alias EctoLtree.LabelTree, as: Ltree

  schema "item_membership" do
    field :permission, :string
    belongs_to :item, Admin.Items.Item, type: Ltree, foreign_key: :item_path
    belongs_to :creator, Admin.Accounts.Account, type: :binary_id
    belongs_to :account, Admin.Accounts.Account, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :permission,
      :item_path,
      :creator_id,
      :account_id
    ])
    |> validate_required([:permission, :item_path, :account_id])

    # validate extra fields
  end
end
