defmodule AdminWeb.ValidationLive.Form do
  use AdminWeb, :live_view

  alias Admin.Items

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin {assigns}>
      <.header>
        Validation Form
        <:actions>
          <.button color="neutral" navigate={~p"/admin/validation"}>
            <.icon name="hero-arrow-left" class="size-4" /> Back
          </.button>
        </:actions>
      </.header>

      <p>{@item.name}</p>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
        <img src={@item.thumbnails.large} alt={@item.name} class="w-full object-cover aspect-square" />
        <%= if @validation != nil do %>
          <div class="flex flex-col w-full gap-2">
            <img
              src={@validation.url}
              alt={"validation result for #{@item.name}"}
              class="w-full object-cover aspect-square"
            />
            <div class="flex flex-col">
              <div :for={result <- @validation.result} class="flex flex-row items-center gap-1">
                <progress class="progress progress-ghost shrink-0 w-1/2" value={result.prob} max="1" />
                <span class="w-fit">{(result.prob * 100) |> round()}%</span>
                <span class="text-xs overflow-hidden text-ellipsis">{result.class}</span>
              </div>
            </div>
          </div>
        <% else %>
          <div class="w-full bg-base-100 aspect-square flex flex-col items-center justify-center">
            <.button phx-click="validate" class="btn-soft">Validate</.button>
          </div>
        <% end %>
      </div>
    </Layouts.admin>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"item_id" => item_id}, _session, socket) do
    socket =
      socket
      |> assign(:item, Items.get_item!(socket.assigns.current_scope, item_id))
      |> assign(:validation, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    validation = Items.validate_item(socket.assigns.current_scope, socket.assigns.item)
    {:noreply, assign(socket, :validation, validation)}
  end
end
