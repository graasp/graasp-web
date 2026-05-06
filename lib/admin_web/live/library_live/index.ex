defmodule AdminWeb.LibraryLive.Index do
  use AdminWeb, :live_view

  alias Admin.Publications

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:publications, Publications.list_published_items(24))
      |> assign(:page_title, gettext("Published Items"))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.landing {assigns}>
      <div class="max-w-screen-lg m-auto p-4 mt-10">
        <h1 class="text-2xl font-bold mb-4">Published Items</h1>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for publication <- @publications do %>
            <div class="bg-base-100 rounded-lg shadow-sm flex flex-row">
              <.link href={~p"/library/collections/#{publication.item.id}"}>
                <.thumbnail
                  src={publication.thumbnails.medium}
                  size="medium"
                  alt={publication.item.name}
                />
              </.link>
              <div class="p-2">
                <h3 class="font-bold">{publication.item.name}</h3>
                <span class="line-clamp-3">
                  <.raw_html class="line-clamp-3" html={publication.item.description} />
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.landing>
    """
  end
end
