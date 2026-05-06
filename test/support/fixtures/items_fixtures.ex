defmodule Admin.ItemsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Admin.Items` context.
  """
  alias Admin.Items.PathUtils

  @doc """
  Generate a item.
  """
  def item_fixture(scope, attrs \\ %{}, file_attrs \\ %{}) do
    {:ok, creator} =
      Admin.Repo.insert(%Admin.Accounts.Account{
        id: Ecto.UUID.generate(),
        name: "some name",
        email: "some#{System.unique_integer([:positive])}@email.com",
        type: "individual"
      })

    item_id = Ecto.UUID.generate()

    attrs =
      Enum.into(attrs, %{
        id: item_id,
        description: "some description",
        extra: %{},
        name: "some name",
        path: "#{PathUtils.from_uuids([item_id])}",
        settings: %{},
        type: "some type",
        lang: "en",
        creator_id: creator.id
      })

    {:ok, item} = Admin.Items.create_item(scope, attrs, file_attrs)
    item
  end

  @doc """
  Generate a file item directly in the DB without triggering S3 uploads.
  Use this in tests that need a `type: "file"` item without real file storage.
  """
  def file_item_fixture(scope, attrs \\ %{}) do
    item_id = Ecto.UUID.generate()

    attrs =
      Enum.into(attrs, %{
        id: item_id,
        name: "test_image.jpg",
        description: "some description",
        extra: %{
          "file" => %{
            "name" => "test_image.jpg",
            "path" => "files/#{item_id}",
            "mimetype" => "image/jpeg",
            "size" => 1024
          }
        },
        path: "#{PathUtils.from_uuids([item_id])}",
        settings: %{},
        type: "file",
        lang: "en"
      })

    item_fixture(scope, attrs)
  end

  def build_tree(scope, tree_structure) when is_list(tree_structure) do
    build_tree_recursive(scope, [], tree_structure)
  end

  defp build_tree_recursive(scope, prefix, children) do
    Enum.reduce(children, [], fn {parent, children}, acc ->
      item_id = Ecto.UUID.generate()
      item_path = prefix ++ [item_id]

      attrs =
        Enum.into(parent, %{
          id: item_id,
          path: "#{PathUtils.from_uuids(item_path)}"
        })

      item = item_fixture(scope, attrs)

      res = build_tree_recursive(scope, item_path, children)
      acc ++ [{item, res}]
    end)
  end
end
