defmodule Admin.FolderExports.CleanupWorker do
  @moduledoc """
  Deletes the expired Folder Exports. The bucket has a lifecycle rule on the
  `public-exports/` prefix too, this makes expiry independent of it.
  """
  use Oban.Worker, queue: :default, max_attempts: 1

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    report = Admin.FolderExports.delete_expired()
    Logger.info("Folder exports cleanup: #{inspect(report)}")
    :ok
  end
end
