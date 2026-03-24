defmodule Admin.Items do
  @moduledoc """
  The Items context.
  """
  require Logger

  import Ecto.Query, warn: false
  import EctoLtree.Functions, only: [nlevel: 1]

  alias Admin.Accounts.Scope
  alias Admin.ItemFiles
  alias Admin.Items.{Item, ItemMembership, PathUtils}
  alias Admin.Repo
  alias Admin.Validation.NudenetValidation

  @doc """
  Subscribes to scoped notifications about any item changes.

  The broadcasted messages match the pattern:

    * {:created, %Item{}}
    * {:updated, %Item{}}
    * {:deleted, %Item{}}

  """
  def subscribe_item do
    Phoenix.PubSub.subscribe(Admin.PubSub, "user:item")
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Admin.PubSub, "user:item", message)
  end

  @doc """
  Returns the list of item.

  ## Examples

      iex> list_item(scope)
      [%Item{}, ...]

  """
  def list_item(%Scope{} = _scope) do
    Repo.all(Item)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(scope, 123)
      %Item{}

      iex> get_item!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(%Scope{} = _scope, id) do
    Repo.get!(Item, id)
    |> populate_thumbnails()
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(scope, %{field: value})
      {:ok, %Item{}}

      iex> create_item(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_item(%Scope{} = scope, attrs, file_attrs \\ %{}) do
    with {:ok, item = %Item{}} <-
           %Item{}
           |> Item.changeset(attrs)
           |> Repo.insert() do
      case attrs.type do
        "file" ->
          file_path = ItemFiles.upload(file_attrs, item.id)

          update_item(scope, item, %{
            extra: %{
              file: %{
                name: file_attrs.name,
                path: file_path,
                mimetype: file_attrs.mimetype,
                size: file_attrs.size
              }
            }
          })

        _ ->
          :ok
      end

      broadcast({:created, item})
      {:ok, item}
    end
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(scope, item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(scope, item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Scope{} = _scope, %Item{} = item, attrs) do
    with {:ok, item = %Item{}} <-
           item
           |> Item.changeset(attrs)
           |> Repo.update() do
      broadcast({:updated, item})
      {:ok, item}
    end
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(scope, item)
      {:ok, %Item{}}

      iex> delete_item(scope, item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Scope{} = _scope, %Item{} = item) do
    with {:ok, item = %Item{}} <-
           Repo.delete(item) do
      case item.type do
        "file" -> ItemFiles.delete(item)
        _ -> :ok
      end

      broadcast({:deleted, item})
      {:ok, item}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(scope, item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Scope{} = _scope, %Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  def get_descendants(%EctoLtree.LabelTree{} = item_path) do
    from(item in Item,
      order_by: [asc: nlevel(item.path), asc_nulls_first: item.order],
      where: fragment("? @> ?", ^(item_path |> EctoLtree.LabelTree.decode()), item.path)
    )
    |> Repo.all()
  end

  def delete_tree(%EctoLtree.LabelTree{} = item_path) do
    from(item in Item,
      where: fragment("? @> ?", ^(item_path |> EctoLtree.LabelTree.decode()), item.path)
    )
    |> Repo.delete_all(timeout: :infinity)
  end

  def delete_item(%EctoLtree.LabelTree{} = item_path) do
    id = PathUtils.to_uuids(item_path) |> List.last()

    case from(item in Item, where: item.id == ^id)
         |> Repo.delete_all() do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  def get_by_h5p_content_id(h5p_content_id) do
    from(item in Item,
      select: item.id,
      where:
        item.type == "h5p" and
          fragment("?->'h5p'->'contentId' = ?", item.extra, ^h5p_content_id)
    )
    |> Repo.one()
  end

  def get_recent_files do
    from(item in Item,
      order_by: [desc: item.created_at],
      where: item.type == "file",
      limit: 10
    )
    |> Repo.all()
    |> Enum.map(&populate_thumbnails(&1))
  end

  @doc """
  Returns items that have no memberships at all.
  They are effectively non-modifiable and not owned by anyone.
  But they could still be published or have a public access.

  These elements usually have a creator who has deleted their account.
  But sometimes also the creator has left the item and the last admin has deleted their account.
  """
  def get_orphans_last_year do
    from(item in Item,
      select: item,
      left_join: membership in ItemMembership,
      on: fragment("? @> ?", membership.item_path, item.path),
      where:
        is_nil(membership.item_path) and
          item.created_at >= date_add(^Date.utc_today(), -1, "year"),
      order_by: [desc: item.created_at],
      limit: 100
    )
    |> Repo.all()
  end

  defp populate_thumbnails(%Item{id: item_id} = item) do
    thumbnails =
      Admin.ItemThumbnails.get_item_thumbnails(item_id)

    Map.put(item, :thumbnails, thumbnails)
  end

  def validate_item(%Scope{} = _scope, item) do
    path = get_file_path(item)
    {image, result} = NudenetValidation.from_file(path)
    {:ok, png_bin} = Image.write(image, :memory, suffix: ".png")
    base64 = Base.encode64(png_bin)
    data_url = "data:image/png;base64," <> base64
    %{url: data_url, result: result}
  end

  defp get_file_path(%Item{type: "file", extra: %{"file" => %{"path" => path}}}), do: path
  defp get_file_path(%Item{type: "file", extra: %{"file" => %{"key" => path}}}), do: path
  defp get_file_path(_item), do: nil
end
