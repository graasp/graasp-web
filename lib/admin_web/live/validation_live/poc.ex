defmodule AdminWeb.ValidationLive.Poc do
  use AdminWeb, :live_view

  alias Admin.Items

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin {assigns}>
      <h2>Recent files</h2>
      <div class="flex flex-col gap-2 w-full">
        <div :for={file <- @recent_files} class="flex flex-row gap-2">
          <img
            :if={Map.get(file, :thumbnails)}
            src={file.thumbnails.medium}
            alt={file.name}
            class="size-24 object-cover"
          />
          <div class="flex flex-col">
            <p>{file.name}</p>
            <span class="text-sm text-neutral">{file.id}</span>
            <div class="flex flex-row gap-1">
              <.button class="w-fit" color="error" phx-click="delete-item" phx-value-id={file.id}>
                <.icon name="hero-trash" class="size-4" /> Delete
              </.button>
              <.button
                class="w-fit"
                color="primary"
                navigate={~p"/admin/validation/#{file.id}/validate"}
              >
                Validate
              </.button>
            </div>
          </div>
        </div>
      </div>

      <h2>Experimental upload of files to validate</h2>
      <form id="upload-form" phx-change="validate" phx-submit="save">
        <.live_file_input upload={@uploads.file} class="file-input" />
        <.button type="submit">Upload</.button>
      </form>

      <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
      <section phx-drop-target={@uploads.file.ref}>
        <%!-- render each file entry --%>
        <article :for={entry <- @uploads.file.entries} class="upload-entry">
          <figure class="max-w-[200px]">
            <.live_img_preview entry={entry} />
            <figcaption class="text-sm">{entry.client_name}</figcaption>
          </figure>

          <div class="flex flex-row items-center gap-2">
            <%!-- entry.progress will update automatically for in-flight entries --%>
            <progress class="progress" value={entry.progress} max="100">{entry.progress}% </progress>

            <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
            <.button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </.button>
          </div>

          <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
          <p :for={err <- upload_errors(@uploads.file, entry)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </article>

        <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
        <p :for={err <- upload_errors(@uploads.file)} class="alert alert-danger">
          {error_to_string(err)}
        </p>
      </section>
    </Layouts.admin>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:recent_files, Admin.Items.get_recent_files())
     |> allow_upload(:file, accept: ~w(.jpg .jpeg .png .webp), max_entries: 2)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
      {:ok, item} =
        Items.create_item(
          socket.assigns.current_scope,
          %{
            name: Path.basename(path),
            type: "file"
          },
          %{
            path: path,
            name: entry.client_name,
            mimetype: entry.client_type,
            size: entry.client_size
          }
        )

      {:ok, item}
    end)

    {:noreply,
     socket
     |> assign(:recent_files, Admin.Items.get_recent_files())}
  end

  def handle_event("delete-item", %{"id" => id}, socket) do
    item = socket.assigns.recent_files |> Enum.find(&(&1.id == id))
    {:ok, _} = Items.delete_item(socket.assigns.current_scope, item)

    {:noreply, update(socket, :recent_files, fn files -> Enum.reject(files, &(&1.id == id)) end)}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
