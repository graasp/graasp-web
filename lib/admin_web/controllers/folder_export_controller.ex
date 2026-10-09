defmodule AdminWeb.FolderExportController do
  use AdminWeb, :controller

  alias Admin.FolderExports

  @doc """
  Entry point of the "Download zip" action of a Public Folder: starts (or joins)
  the Folder Export and sends the Visitor to its Export Progress Page.
  """
  def create(conn, %{"item_id" => item_id}) do
    case FolderExports.request_export(item_id) do
      {:ok, export} ->
        redirect(conn, to: ~p"/export/#{export.id}")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_layout(false)
        |> put_root_layout(false)
        |> put_view(html: AdminWeb.ErrorHTML)
        |> render(:"404")
    end
  end
end
