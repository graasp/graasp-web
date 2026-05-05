defmodule Admin.Items.Item do
  @moduledoc """
  This represents an item in Graasp
  """
  use Admin.Schema

  import Ecto.Changeset

  alias Admin.Items.PathUtils
  alias EctoLtree.LabelTree, as: Ltree

  schema "item" do
    field :name, :string
    field :description, :string
    field :path, Ltree
    field :extra, :map
    field :type, :string
    field :settings, :map
    field :lang, :string, default: "en"
    field :order, :decimal
    field :deleted_at, :utc_datetime
    field :thumbnails, :map, virtual: true

    belongs_to :creator, Admin.Accounts.Account, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :id,
      :name,
      :description,
      :path,
      :extra,
      :type,
      :settings,
      :creator_id,
      :lang,
      :order
    ])
    |> validate_required([:name, :type, :lang])
    |> add_id_if_not_provided()
    |> add_path_if_not_exists()

    # validate extra fields
  end

  defp add_id_if_not_provided(changeset) do
    case get_field(changeset, :id) do
      nil ->
        put_change(changeset, :id, Ecto.UUID.generate())

      _ ->
        changeset
    end
  end

  defp add_path_if_not_exists(changeset) do
    case get_field(changeset, :path) do
      nil ->
        id = get_field(changeset, :id)
        path = PathUtils.to_ltree([id])
        put_change(changeset, :path, path)

      _ ->
        changeset
    end
  end
end
