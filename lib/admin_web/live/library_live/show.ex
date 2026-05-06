defmodule AdminWeb.LibraryLive.Show do
  use AdminWeb, :live_view

  alias Admin.Publications

  @impl Phoenix.LiveView
  def mount(%{"item_id" => item_id}, _session, socket) do
    publication =
      Publications.get_publication_id_for_item_id(item_id)
      |> Publications.get_published_item!()
      |> Publications.with_item()

    socket =
      socket
      |> assign(
        :publication,
        publication
      )
      |> assign(:authors, Publications.get_authors(publication.item))
      |> assign(:page_title, publication.item.name)
      |> assign(:page_description, publication.item.description)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.landing {assigns}>
      <div class="max-w-screen-lg m-auto p-4 mt-10">
        <div class="flex flex-col gap-4 ">
          <.button variant="ghost" class="w-fit" navigate={~p"/library"}>
            <.icon name="hero-arrow-left" class="size-5" />{gettext("Back")}
          </.button>
          <div class="flex flex-col gap-12 sm:flex-row">
            <.thumbnail
              src={@publication.thumbnails.large}
              size="large"
              alt={@publication.item.name}
            />
            <div class="flex flex-col gap-4">
              <h1 class="text-2xl font-bold mb-4">{@publication.item.name}</h1>
              <div class="flex flex-col gap-1">
                <.raw_html
                  id="description"
                  class="line-clamp-3"
                  html={@publication.item.description}
                />
                <.button
                  size="sm"
                  class="w-fit"
                  phx-click={JS.toggle_class("line-clamp-3", to: "#description")}
                >
                  {gettext("Show more")}
                </.button>
              </div>
              <div class="avatar-group -space-x-4">
                <div :for={user <- @authors}>
                  <object
                    data={user.thumbnails.small}
                    type="image/webp"
                  >
                    <div class="avatar avatar-placeholder">
                      <div class="bg-neutral text-neutral-content w-8 rounded-full">
                        <span class="text-xs"><.icon name="hero-user" class="size-4" /></span>
                      </div>
                    </div>
                  </object>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.landing>
    """
  end
end
