defmodule Admin.ItemFiles do
  @moduledoc """
  Handles items files operations.
  """

  alias Admin.Items.Item
  alias Admin.ItemThumbnails
  alias Admin.S3

  require Logger
  def bucket, do: Application.get_env(:admin, :file_items_bucket, "file-items")

  @spec delete(list(%{id: binary(), path: binary()})) :: :ok
  def delete([]), do: :ok

  def delete(files_data) when is_list(files_data) and files_data != [] do
    file_paths = files_data |> Enum.map(& &1.path)
    # key length can not exceed 1024 bytes
    {valid_keys, _invalid_keys} = file_paths |> Enum.split_with(&(String.length(&1) <= 1023))
    {:ok, _} = S3.delete_objects(bucket(), valid_keys)

    files_data
    |> Enum.each(fn file ->
      {:ok, _} = Admin.ItemThumbnails.delete_thumbnails(file.id)
    end)

    :ok
  end

  def delete(%Item{} = item) do
    path =
      get_in(item.extra, ["file", "path"]) ||
        get_in(item.extra, ["file", "key"])

    case path do
      nil ->
        # try deleting thumbnails by item id
        {:ok, _} = ItemThumbnails.delete_thumbnails(item.id)

      _ ->
        delete([%{id: item.id, path: path}])
    end
  end

  def upload(%{path: file_path, mimetype: _mimetype} = file_attrs, item_id)
      when is_binary(item_id) do
    # create thumbnails
    :ok = ItemThumbnails.create_thumbnail(file_attrs, item_id)
    # upload file
    key = "files/#{item_id}"
    S3.upload(bucket(), key, file_path)
    key
  end
end
