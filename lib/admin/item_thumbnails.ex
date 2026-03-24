defmodule Admin.ItemThumbnails do
  @moduledoc """
  Module for getting signed urls for item thumbnails.
  """

  alias Admin.S3

  defp bucket, do: Application.get_env(:admin, :file_items_bucket, "file-items")

  defp thumbnail_paths(item_id),
    do: [
      "thumbnails/#{item_id}/small",
      "thumbnails/#{item_id}/medium",
      "thumbnails/#{item_id}/large",
      "thumbnails/#{item_id}/original"
    ]

  defp thumbnail_sizes, do: %{"small" => 40, "medium" => 256, "large" => 512}

  def get_item_thumbnails(item_id) do
    %{
      small: get_item_thumbnail(item_id, "small"),
      medium: get_item_thumbnail(item_id, "medium"),
      large: get_item_thumbnail(item_id, "large")
    }
  end

  defp get_item_thumbnail(item_id, size) when size in ["small", "medium", "large", "original"] do
    key = "thumbnails/#{item_id}/#{size}"
    ttl = 3600
    get_url_for(key, ttl)
  end

  def delete_thumbnails(item_id) when is_binary(item_id) do
    S3.delete_objects(bucket(), thumbnail_paths(item_id))
  end

  def create_thumbnail(%{path: file_path} = _file_attrs, item_id) do
    image = Image.open!(file_path)

    Enum.each(thumbnail_sizes(), fn {size, width} ->
      image
      |> Image.thumbnail!(width)
      |> Image.stream!(suffix: ".webp", buffer_size: 5 * 1024 * 1024)
      |> S3.upload_stream(bucket(), "thumbnails/#{item_id}/#{size}")
    end)
  end

  def avatar_thumbnails(user_id)
      when is_binary(user_id) do
    %{
      small: get_avatar_thumbnail(user_id, "small"),
      medium: get_avatar_thumbnail(user_id, "medium"),
      large: get_avatar_thumbnail(user_id, "large")
    }
  end

  defp get_avatar_thumbnail(user_id, size)
       when is_binary(user_id)
       when size in ["small", "medium", "large"] do
    key = "avatars/#{user_id}/#{size}"
    ttl = 3600
    get_url_for(key, ttl)
  end

  defp get_url_for(key, ttl) do
    {:ok, url} =
      Admin.SignedUrlCache.get_or_put(key, ttl, fn ->
        S3.get_object_url(bucket(), key, expires_in: ttl)
      end)

    url
  end
end
