defmodule AdminWeb.UserLive.Listing do
  use AdminWeb, :live_view

  alias Admin.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope}>
      <.header>
        Admin users
        <:subtitle>Show users that are currently registered in the app</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/users/new"} id="new_user">Add an admin user</.button>
        </:actions>
      </.header>

      <div id="user-list" phx-update="stream" class="flex flex-col gap-2 bg-base-100 p-6 rounded-lg">
        <%= for {id, user} <- @streams.users do %>
          <div
            id={id}
            class="flex flex-row justify-between"
          >
            <div class="">
              <.link navigate={~p"/admin/users/#{user}"}>
                <span>{user.name}</span>

                <div class="flex flex-row gap-1">
                  <span>{user.email}</span>
                  <div
                    :if={user.id == @current_scope.user.id}
                    class="badge badge-soft badge-info text-xs"
                  >
                    You
                  </div>
                  <div :if={user.confirmed_at} class="badge badge-soft badge-success text-xs">
                    <.icon name="hero-check-circle" class="size-4 shrink-0" /> Email
                  </div>
                </div>
              </.link>
              <div class="text-xs">
                <span class="text-secondary">Language:</span> {user.language}
              </div>

              <div class="flex flex-row gap-2 text-xs">
                <span class="text-secondary">{user.id}</span>
                <AdminWeb.DateTimeComponents.relative_date date={user.created_at} />
              </div>
            </div>
            <.button class="btn" phx-click="confirm_delete" value={user.id}>Delete</.button>
          </div>
        <% end %>
      </div>

      <dialog
        id="delete_modal"
        class="modal"
        open={@show_modal}
      >
        <div class="modal-box">
          <h3 class="font-bold text-lg">Confirm Deletion</h3>
          <p class="py-4">Are you sure you want to delete this user?</p>
          <div class="modal-action">
            <button id="delete_button" class="btn btn-error" phx-click="delete_user">
              Delete
            </button>
            <button id="cancel_button" class="btn" phx-click="cancel_delete">Cancel</button>
          </div>
        </div>
      </dialog>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.subscribe_users()
    end

    socket =
      socket
      |> assign(:page_title, "Admin Users")
      |> stream(:users, Accounts.list_users())
      |> assign(:show_modal, false)
      |> assign(:user_to_delete, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("confirm_delete", %{"value" => user_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:user_to_delete, user_id)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, socket |> assign(:show_modal, false) |> assign(:user_to_delete, nil)}
  end

  def handle_event("delete_user", _params, socket) do
    id = socket.assigns.user_to_delete
    {:ok, user} = Accounts.delete_user_by_id(id)
    # Update the stream locally by removing the user.
    {:noreply,
     stream_delete(socket, :users, user)
     |> assign(:show_modal, false)
     |> assign(:user_to_delete, nil)}
  end

  def handle_event("new_random_user", _, socket) do
    {:ok, user} =
      Accounts.register_user(%{email: "#{System.unique_integer([:positive])}@graasp.org"})

    {:noreply, stream_insert(socket, :users, user) |> put_flash(:info, "New user created")}
  end

  @impl true
  def handle_info({type, %Admin.Accounts.User{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :users, Accounts.list_users(), reset: true)}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end
