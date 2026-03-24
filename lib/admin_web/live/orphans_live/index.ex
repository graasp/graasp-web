defmodule AdminWeb.OrphansLive.Index do
  use AdminWeb, :live_view

  alias Admin.Items

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin {assigns}>
      <.header>
        Orphan items
      </.header>
      <.table rows={@streams.orphans} id="orphans">
        <:col :let={{_id, orphan}} label="Name">{orphan.name}</:col>
        <:col :let={{_id, orphan}} label="Type">{orphan.type}</:col>
        <:col :let={{_id, orphan}} label="Created">{orphan.created_at}</:col>
      </.table>
    </Layouts.admin>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = socket |> stream(:orphans, Items.get_orphans_last_year())
    {:ok, socket}
  end
end
