defmodule Admin.FolderExports do
  @moduledoc """
  The Folder Exports context: a Visitor requests a zip of a Public Folder,
  which is built in the background (see `Admin.FolderExports.Worker`) and kept
  for 24 hours.

  Progress is persisted and broadcast on `Admin.PubSub`, on one topic per
  export. Subscribers receive `{:folder_export_updated, %FolderExport{}}`.
  """
  import Ecto.Query, warn: false

  alias Admin.FolderExports.FolderExport
  alias Admin.FolderExports.Visibility
  alias Admin.FolderExports.Worker
  alias Admin.Repo

  @ttl_seconds 24 * 60 * 60
  # an in-flight export that did not move for that long is considered dead
  @stale_after_seconds 3 * 60 * 60

  @doc "Where exported zips are stored in the bucket."
  def prefix, do: "public-exports/"

  def bucket, do: Admin.ItemFiles.bucket()

  @doc "How long an export is kept, in seconds."
  def ttl_seconds, do: @ttl_seconds

  @doc """
  Requests the export of a Public Folder.

  A pending or running export of the same folder is returned instead of
  creating a new one, this is what bounds the work anonymous traffic can create.
  Returns `{:error, :not_found}` unless the folder is public.
  """
  @spec request_export(String.t()) :: {:ok, FolderExport.t()} | {:error, :not_found}
  def request_export(item_id) do
    with {:ok, folder} <- Visibility.get_public_folder(item_id) do
      Repo.transaction(fn ->
        # serialize the requests for the same folder
        Repo.query!("SELECT pg_advisory_xact_lock(hashtext($1))", [folder.id])
        fail_stale(folder.id)

        case get_in_flight(folder.id) do
          %FolderExport{} = export -> export
          nil -> create_export(folder)
        end
      end)
    end
  end

  @doc "Starts a new export for the folder of a (failed) export."
  @spec retry(FolderExport.t()) :: {:ok, FolderExport.t()} | {:error, :not_found}
  def retry(%FolderExport{item_id: item_id}), do: request_export(item_id)

  @doc "Gets an export, `nil` when the id is unknown."
  @spec get_export(String.t()) :: FolderExport.t() | nil
  def get_export(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(FolderExport, uuid) |> Repo.preload(:item)
      :error -> nil
    end
  end

  @doc "The pending or running export of a folder, if any."
  def get_in_flight(item_id) do
    from(e in FolderExport,
      where: e.item_id == ^item_id and e.status in ["pending", "running"],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  The most recent exports, newest first, with their folder. `status` narrows
  the list to one status, `nil` or `""` keeps them all.
  """
  @spec list_recent(String.t() | nil, pos_integer()) :: [FolderExport.t()]
  def list_recent(status \\ nil, limit \\ 200) do
    from(e in FolderExport,
      order_by: [desc: e.created_at, desc: e.id],
      limit: ^limit,
      preload: :item
    )
    |> filter_status(status)
    |> Repo.all()
  end

  defp filter_status(query, status) when status in [nil, ""], do: query
  defp filter_status(query, status), do: where(query, [e], e.status == ^status)

  def subscribe(export_id) do
    Phoenix.PubSub.subscribe(Admin.PubSub, topic(export_id))
  end

  defp topic(export_id), do: "folder_export:#{export_id}"

  ## State changes, used by the worker

  def mark_running(%FolderExport{} = export) do
    update_and_broadcast(export, status: "running", processed_count: 0, error: nil)
  end

  def set_total(%FolderExport{} = export, total) do
    update_and_broadcast(export, total_count: total)
  end

  def update_progress(%FolderExport{} = export, processed) do
    update_and_broadcast(export, processed_count: processed)
  end

  @doc "Marks the export done. Without `s3_key` the folder had nothing to export."
  def mark_done(%FolderExport{} = export, s3_key) do
    update_and_broadcast(export,
      status: "done",
      s3_key: s3_key,
      processed_count: export.total_count || 0,
      expires_at: new_expiration()
    )
  end

  def mark_failed(%FolderExport{} = export, error) do
    update_and_broadcast(export, status: "failed", error: error)
  end

  ## Download

  @doc """
  A download link for a done export, valid until the export expires.
  `nil` when there is nothing to download.
  """
  @spec download_url(FolderExport.t()) :: String.t() | nil
  def download_url(%FolderExport{status: "done", s3_key: key} = export) when is_binary(key) do
    if FolderExport.expired?(export) do
      nil
    else
      expires_in = max(DateTime.diff(export.expires_at, DateTime.utc_now()), 1)
      filename = URI.encode("#{folder_name(export)}.zip", &URI.char_unreserved?/1)

      Admin.S3.get_object_url(bucket(), key,
        expires_in: expires_in,
        query_params: [
          {"response-content-disposition", "attachment; filename*=UTF-8''#{filename}"}
        ]
      )
    end
  end

  def download_url(_export), do: nil

  defp folder_name(%FolderExport{item: %{name: name}}), do: name
  defp folder_name(%FolderExport{}), do: "export"

  ## Expiry

  @doc """
  Deletes the zips of the expired exports, as a fallback to the lifecycle rule
  of the bucket, and the rows once they have been expired for a while (so that
  the page keeps telling a Visitor that the export expired).
  """
  def delete_expired(now \\ DateTime.utc_now()) do
    expired = from(e in FolderExport, where: e.expires_at <= ^now)

    # exports that never finished can not be reused anymore
    expired
    |> where([e], e.status in ["pending", "running"])
    |> Repo.update_all(set: [status: "failed", error: "The export took too long."])

    with_object = from(e in expired, where: not is_nil(e.s3_key))
    keys = Repo.all(from e in with_object, select: e.s3_key)

    if keys != [] do
      keys |> Enum.chunk_every(1000) |> Enum.each(&Admin.S3.delete_objects(bucket(), &1))
      Repo.update_all(with_object, set: [s3_key: nil])
    end

    purge_before = DateTime.add(now, -7 * 24 * 60 * 60)

    {rows, _} = Repo.delete_all(from(e in FolderExport, where: e.expires_at <= ^purge_before))

    %{objects: length(keys), rows: rows}
  end

  ## Internals

  defp create_export(folder) do
    export =
      %FolderExport{item_id: folder.id, expires_at: new_expiration()}
      |> Repo.insert!()

    {:ok, _job} = %{export_id: export.id} |> Worker.new() |> Oban.insert()
    export
  end

  defp fail_stale(item_id) do
    threshold = DateTime.add(DateTime.utc_now(), -@stale_after_seconds)

    from(e in FolderExport,
      where: e.item_id == ^item_id and e.status in ["pending", "running"],
      where: e.updated_at <= ^threshold
    )
    |> Repo.update_all(set: [status: "failed", error: "The export took too long."])
  end

  defp new_expiration do
    DateTime.utc_now() |> DateTime.add(@ttl_seconds) |> DateTime.truncate(:second)
  end

  defp update_and_broadcast(%FolderExport{} = export, changes) do
    updated =
      export
      |> Ecto.Changeset.change(changes)
      |> Repo.update!()

    Phoenix.PubSub.broadcast(
      Admin.PubSub,
      topic(export.id),
      {:folder_export_updated, updated}
    )

    updated
  end
end
