defmodule AdminWeb.Forms.PublishedItemSearchForm do
  @moduledoc """
  This represents the search form for published items.
  """
  alias Admin.Publications
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :item_id, :string
    field :published_item_id, :string
  end

  def changeset(form, params) do
    form
    |> cast(params, [:item_id])
    |> validate_required([:item_id])
    |> validate_uuid(:item_id)
    |> validate_and_put_published_item_id()
    |> Map.put(:action, :validate)
  end

  defp validate_uuid(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case Ecto.UUID.cast(value) do
        {:ok, _} -> []
        :error -> [{field, "is not a valid UUID"}]
      end
    end)
  end

  @spec validate_and_put_published_item_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_and_put_published_item_id(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  defp validate_and_put_published_item_id(changeset) do
    item_id = Ecto.Changeset.get_field(changeset, :item_id)

    case Publications.get_publication_id_for_item_id(item_id) do
      nil ->
        Ecto.Changeset.add_error(
          changeset,
          # set the error on the item_id since the published_item_id is not displayed
          :item_id,
          "Publication does not exist for item with id '#{item_id}'"
        )

      published_item_id ->
        Ecto.Changeset.put_change(changeset, :published_item_id, published_item_id)
    end
  end
end
