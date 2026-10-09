defmodule AdminWeb.FolderExportLive.Index do
  @moduledoc """
  Admin view of the recent Folder Exports, with a way to run the expired
  exports cleanup on demand.
  """
  use AdminWeb, :live_view

  alias Admin.FolderExports
  alias Admin.Repo

  @statuses ["pending", "running", "done", "failed"]

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope}>
      <.header>
        Folder exports
        <:actions>
          <.button
            id="run-cleanup"
            phx-click="run_cleanup"
            phx-disable-with="Cleaning up"
            data-confirm="Delete the expired exports and their zips?"
          >
            Run cleanup
          </.button>
        </:actions>
      </.header>

      <.form for={@filter} id="status-filter" phx-change="filter">
        <.input
          field={@filter[:status]}
          type="select"
          label="Status"
          options={@statuses}
          prompt="All"
        />
      </.form>

      <div class="overflow-x-auto">
        <table class="table">
          <thead>
            <tr>
              <th>Folder</th>
              <th>Status</th>
              <th>Progress</th>
              <th>Created</th>
              <th>Expires</th>
              <th>Error</th>
            </tr>
          </thead>
          <tbody id="folder-exports" phx-update="stream">
            <tr id="folder-exports-empty" class="hidden only:table-row">
              <td colspan="6">No exports</td>
            </tr>
            <tr :for={{id, export} <- @streams.exports} id={id}>
              <td>
                <.link navigate={~p"/library-beta/collections/#{export.item_id}"} class="link">
                  {export.item.name}
                </.link>
              </td>
              <td data-role="status">{export.status}</td>
              <td>{export.processed_count}/{export.total_count || "?"}</td>
              <td>{Calendar.strftime(export.created_at, "%Y-%m-%d %H:%M")}</td>
              <td>{Calendar.strftime(export.expires_at, "%Y-%m-%d %H:%M")}</td>
              <td>{export.error}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:statuses, @statuses)
      |> assign(:subscribed, MapSet.new())
      |> stream_configure(:exports, dom_id: &"folder-exports-#{&1.id}")
      |> load("")

    {:ok, socket}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply, load(socket, status)}
  end

  def handle_event("run_cleanup", _params, socket) do
    %{objects: objects, rows: rows} = FolderExports.delete_expired()
    status = socket.assigns.filter[:status].value

    {:noreply,
     socket
     |> put_flash(:info, "Cleanup done: #{objects} zips deleted, #{rows} exports purged")
     |> load(status)}
  end

  @impl true
  def handle_info({:folder_export_updated, export}, socket) do
    export = Repo.preload(export, :item)
    status = socket.assigns.filter[:status].value

    socket =
      if status in [nil, "", export.status] do
        stream_insert(socket, :exports, export)
      else
        stream_delete(socket, :exports, export)
      end

    {:noreply, socket}
  end

  defp load(socket, status) do
    exports = FolderExports.list_recent(status)

    socket
    |> assign(:filter, to_form(%{"status" => status}))
    |> stream(:exports, exports, reset: true)
    |> subscribe_to(exports)
  end

  # Each export has its own topic. Subscribe once per export, also while the
  # socket is not connected there is nothing to receive.
  defp subscribe_to(socket, exports) do
    if connected?(socket) do
      subscribed =
        Enum.reduce(exports, socket.assigns.subscribed, fn export, acc ->
          if MapSet.member?(acc, export.id) do
            acc
          else
            FolderExports.subscribe(export.id)
            MapSet.put(acc, export.id)
          end
        end)

      assign(socket, :subscribed, subscribed)
    else
      socket
    end
  end
end
