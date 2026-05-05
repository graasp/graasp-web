defmodule AdminWeb.NotificationLive.Index do
  use AdminWeb, :live_view
  alias Admin.Notifications

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope}>
      <.header>
        Mailing
        <:actions>
          <.button variant="primary" navigate={~p"/admin/notifications/new"}>
            <.icon name="hero-plus" /> New Mail
          </.button>
        </:actions>
      </.header>

      <%= if @sending_status do %>
        <div role="alert" class={["alert alert-info alert-soft", "alert-#{@sending_status.status}"]}>
          <span>{@sending_status.message}</span>
          <%= if @sending_status.status == :info do %>
            <progress
              class="progress progress-info"
              value={@sending_status.progress}
              max="100"
            >
            </progress>
            {@sending_status.progress}%
          <% end %>
        </div>
      <% end %>

      <div class="bg-base-100 p-6 rounded-lg">
        <h2 class="text-lg font-bold">Drafts</h2>
        <.table
          id="wip_notifications"
          rows={@streams.wip_notifications}
          row_id={fn {_id, notification} -> "notifications-#{notification.id}" end}
          row_click={
            fn {_id, notification} -> JS.navigate(~p"/admin/notifications/#{notification}") end
          }
        >
          <:col :let={{_id, notification}} label="Name">{notification.name}</:col>
          <:col :let={{_id, notification}} label="Audience">{notification.audience}</:col>
          <:action :let={{_id, notification}}>
            <div class="sr-only">
              <.link navigate={~p"/admin/notifications/#{notification}"}>Show</.link>
            </div>
          </:action>
          <:action :let={{_id, notification}}>
            <.link
              class="text-error"
              phx-click={
                JS.push("delete_wip", value: %{id: notification.id})
                |> hide("#notifications-#{notification.id}")
              }
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </:action>
        </.table>
      </div>

      <div class="bg-base-100 p-6 rounded-lg">
        <h2 class="text-lg font-bold">Sent</h2>
        <.table
          id="notifications"
          rows={@streams.sent_notifications}
          row_click={
            fn {_id, notification} ->
              JS.navigate(~p"/admin/notifications/#{notification}/archive")
            end
          }
        >
          <:col :let={{_id, notification}} label="Name">{notification.name}</:col>
          <:col :let={{_id, notification}} label="Audience">{notification.audience}</:col>
          <:col :let={{_id, notification}} label="Default Language">
            {notification.default_language}
          </:col>
          <:col :let={{_id, notification}} label="Sent">{length(notification.logs)}</:col>
          <:col :let={{_id, notification}} label="Sent On">{notification.sent_at || "Not Sent"}</:col>
          <:col :let={{_id, notification}} label="Total">{notification.total_recipients}</:col>
          <:action :let={{_id, notification}}>
            <div class="sr-only">
              <.link navigate={~p"/admin/notifications/#{notification}"}>Show</.link>
            </div>
          </:action>
          <:action :let={{id, notification}}>
            <.link
              class="text-error"
              phx-click={JS.push("delete_sent", value: %{id: notification.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </:action>
        </.table>
      </div>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Notifications.subscribe_notifications(socket.assigns.current_scope)

      Notifications.subscribe_sending_progress(socket.assigns.current_scope)
    end

    notifications = Notifications.list_notifications_by_status(socket.assigns.current_scope)

    {wip_notifications, sent_notifications} =
      notifications |> Enum.split_with(&(&1.sent_at == nil))

    {:ok,
     socket
     |> assign(:page_title, "Mailing")
     |> assign(:sending_status, nil)
     |> stream(
       :wip_notifications,
       wip_notifications
     )
     |> stream(
       :sent_notifications,
       sent_notifications
     )}
  end

  @impl true
  def handle_event("delete_sent", %{"id" => id}, socket) do
    notification = delete_notification(socket.assigns.current_scope, id)

    {:noreply, stream_delete(socket, :sent_notifications, notification)}
  end

  @impl true
  def handle_event("delete_wip", %{"id" => id}, socket) do
    notification = delete_notification(socket.assigns.current_scope, id)

    {:noreply, stream_delete(socket, :wip_notifications, notification)}
  end

  defp delete_notification(scope, id) do
    notification = Notifications.get_notification!(scope, id)
    {:ok, _} = Notifications.delete_notification(scope, notification)
    notification
  end

  @impl true
  def handle_info({type, %Admin.Notifications.Notification{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(
       socket,
       :notifications,
       Notifications.list_notifications(socket.assigns.current_scope),
       reset: true
     )}
  end

  def handle_info({:progress, notification_name, percent}, socket) do
    {:noreply,
     assign(
       socket,
       :sending_status,
       %{status: :info, message: "Sending: #{notification_name}", progress: percent}
     )}
  end

  def handle_info({:completed, notification_name}, socket) do
    # schedule an event to be sent in 10 seconds to clear the sending status
    :timer.send_after(10_000, "clear_sending_status")

    {:noreply,
     assign(
       socket,
       :sending_status,
       %{status: :success, message: "#{notification_name} has been sent successfully."}
     )}
  end

  def handle_info({:failed, notification_name}, socket) do
    {:noreply,
     assign(
       socket,
       :sending_status,
       %{status: :error, message: "#{notification_name} encountered an error."}
     )}
  end

  def handle_info("clear_sending_status", socket) do
    {:noreply, assign(socket, :sending_status, nil)}
  end
end
