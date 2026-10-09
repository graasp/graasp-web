defmodule AdminWeb.FolderExportLive.Show do
  @moduledoc """
  The Export Progress Page: a Visitor follows a Folder Export here, and gets
  its download link once it is ready. The link to this page is unguessable, it
  is the only access control.
  """
  use AdminWeb, :live_view

  alias Admin.FolderExports
  alias Admin.FolderExports.FolderExport

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    # subscribe before reading, so that no update is lost in between
    if connected?(socket) and match?({:ok, _}, Ecto.UUID.cast(id)),
      do: FolderExports.subscribe(id)

    case FolderExports.get_export(id) do
      nil ->
        raise Ecto.NoResultsError, queryable: FolderExport

      export ->
        if connected?(socket), do: schedule_expiry(export)

        {:ok, socket |> assign(:page_title, gettext("Download zip")) |> assign_export(export)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:folder_export_updated, export}, socket) do
    export = %{export | item: socket.assigns.export.item}
    {:noreply, assign_export(socket, export)}
  end

  def handle_info(:check_expiry, socket) do
    {:noreply, assign_export(socket, socket.assigns.export)}
  end

  @impl Phoenix.LiveView
  def handle_event("retry", _params, socket) do
    case FolderExports.retry(socket.assigns.export) do
      {:ok, export} -> {:noreply, push_navigate(socket, to: ~p"/export/#{export.id}")}
      {:error, :not_found} -> {:noreply, assign(socket, :state, :unavailable)}
    end
  end

  defp assign_export(socket, export) do
    state = state(export)

    socket
    |> assign(:export, export)
    |> assign(:state, state)
    |> assign(:download_url, if(state == :done, do: FolderExports.download_url(export)))
  end

  defp state(%FolderExport{} = export) do
    cond do
      FolderExport.expired?(export) -> :expired
      export.status == "pending" -> :pending
      export.status == "running" -> :running
      export.status == "failed" -> :failed
      export.s3_key == nil -> :empty
      true -> :done
    end
  end

  # flips the page to the expired state without a reload
  defp schedule_expiry(%FolderExport{} = export) do
    delay = DateTime.diff(export.expires_at, DateTime.utc_now(), :millisecond)

    # `send_after` does not accept delays above 2^32 - 1 ms (~49 days)
    if delay > 0 and delay < 4_294_967_295 do
      Process.send_after(self(), :check_expiry, delay + 1_000)
    end
  end

  defp percent(%FolderExport{total_count: total, processed_count: processed})
       when is_integer(total) and total > 0,
       do: min(round(processed / total * 100), 100)

  defp percent(_export), do: 0

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.simple flash={@flash} current_scope={@current_scope}>
      <div id="folder-export" class="max-w-screen-sm mx-auto p-4 mt-10 flex flex-col gap-6">
        <h1 class="text-2xl font-bold">
          {gettext("Download %{name} as a zip", name: @export.item && @export.item.name)}
        </h1>

        <%= case @state do %>
          <% :pending -> %>
            <div id="export-pending" class="flex flex-col gap-2">
              <progress class="progress w-full"></progress>
              <p>{gettext("Your export is queued. It will start in a moment.")}</p>
            </div>
          <% :running -> %>
            <div id="export-running" class="flex flex-col gap-2">
              <progress
                id="export-progress"
                class="progress progress-primary w-full"
                value={percent(@export)}
                max="100"
              >
              </progress>
              <p id="export-progress-count">
                <%= if @export.total_count do %>
                  {gettext("%{processed} of %{total} items",
                    processed: @export.processed_count,
                    total: @export.total_count
                  )}
                <% else %>
                  {gettext("Preparing the export…")}
                <% end %>
              </p>
            </div>
          <% :done -> %>
            <div id="export-done" class="flex flex-col gap-4 items-start">
              <p>{gettext("Your zip is ready.")}</p>
              <a id="export-download-link" href={@download_url} class="btn btn-primary">
                <.icon name="hero-arrow-down-tray" class="size-5" />
                {gettext("Download zip")}
              </a>
              <p class="text-sm text-base-content/70">
                {gettext(
                  "This link is valid for 24 hours. You can bookmark this page and come back later."
                )}
              </p>
            </div>
          <% :empty -> %>
            <p id="export-empty">
              {gettext(
                "This folder has nothing to export: it contains no files, documents, links or descriptions."
              )}
            </p>
          <% :failed -> %>
            <div id="export-failed" class="flex flex-col gap-4 items-start">
              <p class="text-error">
                {gettext("The export failed. You can try again.")}
              </p>
              <button id="export-retry" type="button" class="btn btn-primary" phx-click="retry">
                {gettext("Try again")}
              </button>
            </div>
          <% :expired -> %>
            <p id="export-expired">
              {gettext(
                "This export has expired. Exports are kept for 24 hours, go back to the folder to start a new one."
              )}
            </p>
          <% :unavailable -> %>
            <p id="export-unavailable">
              {gettext("This folder is not available anymore.")}
            </p>
        <% end %>
      </div>
    </Layouts.simple>
    """
  end
end
