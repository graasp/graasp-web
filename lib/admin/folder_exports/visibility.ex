defmodule Admin.FolderExports.Visibility do
  @moduledoc """
  Decides what a Visitor can see of a folder, ported from the Node backend
  (`item_visibility` rows of type `public` and `hidden`).

    * public is checked per item: the item, or one of its ancestors, is public
    * a hidden item hides its descendants
    * recycled items (and their descendants) are left out
    * shortcuts are left out
  """
  import Ecto.Query, warn: false

  alias Admin.Items.Item
  alias Admin.Repo
  alias EctoLtree.LabelTree

  @doc """
  Returns the folder if a Visitor can export it: it exists, is a folder, is
  not recycled or hidden, and is public.
  """
  @spec get_public_folder(String.t()) :: {:ok, Item.t()} | {:error, :not_found}
  def get_public_folder(item_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(item_id),
         %Item{type: "folder"} = item <- Repo.get(Item, uuid),
         true <- visible_to_visitor?(item) do
      {:ok, item}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Lists the folder and every descendant a Visitor can see, shallowest first.
  Shortcuts are not part of the list. The folder must be public.
  """
  @spec list_visible_tree(Item.t()) :: [Item.t()]
  def list_visible_tree(%Item{path: root_path}) do
    root = LabelTree.decode(root_path)

    from(i in Item,
      as: :item,
      where: fragment("? @> ?", ^root, i.path),
      where: is_nil(i.deleted_at),
      where: i.type != "shortcut",
      where: ^public_condition(),
      where: ^not_hidden_condition(),
      where: ^not_recycled_condition(),
      order_by: [asc: fragment("nlevel(?)", i.path), asc_nulls_first: i.order, asc: i.name]
    )
    |> Repo.all()
  end

  defp visible_to_visitor?(%Item{} = item) do
    from(i in Item,
      as: :item,
      where: i.id == ^item.id,
      where: is_nil(i.deleted_at),
      where: ^public_condition(),
      where: ^not_hidden_condition(),
      where: ^not_recycled_condition(),
      select: true
    )
    |> Repo.exists?()
  end

  # the item, or one of its ancestors, is public
  defp public_condition do
    dynamic(
      exists(
        from(v in "item_visibility",
          where: fragment("?::text = 'public'", v.type),
          where: fragment("? @> ?", v.item_path, parent_as(:item).path),
          select: 1
        )
      )
    )
  end

  # the item, or one of its ancestors, is hidden
  defp not_hidden_condition do
    dynamic(
      not exists(
        from(v in "item_visibility",
          where: fragment("?::text = 'hidden'", v.type),
          where: fragment("? @> ?", v.item_path, parent_as(:item).path),
          select: 1
        )
      )
    )
  end

  # the item, or one of its ancestors, is in the recycle bin
  defp not_recycled_condition do
    dynamic(
      not exists(
        from(r in Admin.RecycledItems.RecycledItemData,
          where: fragment("? @> ?", r.item_path, parent_as(:item).path),
          select: 1
        )
      )
    )
  end
end
