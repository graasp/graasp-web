defmodule Admin.FolderExports.Worker do
  @moduledoc """
  Builds the zip of a Folder Export and streams it to S3, through a multipart
  upload: nothing is held in memory (beyond a few parts) or written to disk.
  """
  use Oban.Worker, queue: :exports, max_attempts: 3

  require Logger

  alias Admin.FolderExports
  alias Admin.FolderExports.FolderExport
  alias Admin.FolderExports.Plan
  alias Admin.FolderExports.Visibility
  alias Admin.FolderExports.ZipStream
  alias Admin.Repo

  # S3 multipart uploads need parts of at least 5 MiB
  @part_size 5 * 1024 * 1024
  # progress is persisted and broadcast at most once per second
  @progress_interval_ms 1_000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"export_id" => export_id}}) do
    case Repo.get(FolderExport, export_id) do
      %FolderExport{status: status} = export when status in ["pending", "running"] ->
        build(export)

      _ ->
        :ok
    end
  end

  defp build(export) do
    export = FolderExports.mark_running(export)

    try do
      case Visibility.get_public_folder(export.item_id) do
        {:ok, folder} ->
          entries = folder |> Visibility.list_visible_tree() |> Plan.build()
          export = FolderExports.set_total(export, Plan.count_items(entries))

          if export.total_count == 0 do
            FolderExports.mark_done(export, nil)
          else
            upload(export, entries)
          end

          :ok

        {:error, :not_found} ->
          FolderExports.mark_failed(export, "The folder is not available anymore.")
          :ok
      end
    rescue
      error ->
        Logger.error("Folder export #{export.id} failed: #{Exception.message(error)}")
        FolderExports.mark_failed(export, "The export could not be completed.")
        :ok
    end
  end

  defp upload(export, entries) do
    key = FolderExports.prefix() <> export.id <> ".zip"
    progress = new_progress(export)

    entries
    |> Stream.map(&to_zip_entry/1)
    |> ZipStream.encode(on_entry: &report(progress, &1))
    |> ZipStream.rechunk(@part_size)
    |> Admin.S3.upload_stream(FolderExports.bucket(), key)

    flush(progress)
    FolderExports.mark_done(Repo.reload!(export), key)
  end

  defp to_zip_entry(%Plan.Entry{data: {:s3, bucket, key}} = entry) do
    %{path: entry.path, data: Admin.S3.stream_object(bucket, key), item?: entry.item?}
  end

  defp to_zip_entry(%Plan.Entry{} = entry) do
    %{path: entry.path, data: entry.data, item?: entry.item?}
  end

  ## progress, shared by whichever process consumes the stream

  defp new_progress(export) do
    %{
      export: export,
      processed: :counters.new(1, []),
      last_flush: :atomics.new(1, [])
    }
  end

  defp report(_progress, %{item?: false}), do: :ok

  defp report(progress, %{item?: true}) do
    :counters.add(progress.processed, 1, 1)
    now = System.monotonic_time(:millisecond)

    if now - :atomics.get(progress.last_flush, 1) >= @progress_interval_ms do
      :atomics.put(progress.last_flush, 1, now)
      flush(progress)
    end

    :ok
  end

  defp flush(progress) do
    FolderExports.update_progress(
      Repo.reload!(progress.export),
      :counters.get(progress.processed, 1)
    )
  end
end
