defmodule AdminWeb.DashboardLive.Index do
  use AdminWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_scope={@current_scope} class="bg-base-200">
      <.header>
        Welcome, {@current_scope.user.name || @current_scope.user.email}
      </.header>

      <div class="flex flex-col md:flex-row gap-4">
        <div>
          <h2 class="text-lg text-bold">Publication Statistics</h2>
          <div class="stats stats-vertical sm:stats-horizontal bg-base-200">
            <StatisticsComponents.stat value={@publication_stats.total} title="Overall">
              Published collections
            </StatisticsComponents.stat>
            <StatisticsComponents.stat_comparison
              stat={@publication_stats.month}
              title="Last 30 days"
            />
            <StatisticsComponents.stat_comparison stat={@publication_stats.day} title="Last 24h" />
          </div>
        </div>

        <div>
          <h2 class="text-lg text-bold">Recycled items Statistics</h2>
          <div class="stats stats-vertical sm:stats-horizontal bg-base-200">
            <StatisticsComponents.stat
              value={@recycled_stats.scheduled}
              title="Scheduled for deletion"
            >
              {@recycled_stats.total} total
            </StatisticsComponents.stat>
          </div>
        </div>
      </div>

      <div class="flex flex-row flex-wrap gap-4">
        <div class="flex-1 min-w-2/5 bg-base-200 p-3 rounded-lg">
          <div class="flex items-center justify-between">
            <div class="flex flex-col align-start">
              <h2><.link navigate={~p"/admin/maintenance"}>Planned Maintenance</.link></h2>
              <span class="text-xs text-neutral">
                Showing {length(@maintenances)} upcoming events.
                <.link class="link" navigate={~p"/admin/maintenance"}>View all</.link>
              </span>
            </div>
            <.button navigate={~p"/admin/maintenance/new"}>
              <.icon name="hero-plus" /> New
            </.button>
          </div>
          <div class="flex flex-col mt-2 divide-y divide-neutral last:border-b-0">
            <%= for maintenance <- @maintenances do %>
              <AdminWeb.PlannedMaintenanceHTML.planned_maintenance_row
                maintenance={maintenance}
                row_click={&JS.navigate(~p"/admin/maintenance/#{&1}")}
              />
            <% end %>
            <%= if length(@maintenances) == 0 do %>
              <div class="flex flex-row items-center justify-center gap-3 italic text-neutral p-4 border border-dashed rounded-xl border-base-300">
                <.icon name="ghost" class="animate-wiggle" /> No upcoming maintenance events
              </div>
            <% end %>
          </div>
        </div>
        <div class="flex-1 min-w-2/5 bg-base-200 p-3 rounded-lg">
          <div class="flex items-center justify-between">
            <div class="flex flex-col align-start">
              <h2>H5P integrity check</h2>
              <span class="text-xs text-neutral">
                Check if there are any broken H5P content items.
              </span>
            </div>
            <.button phx-click="h5p-integrity-check" phx-disable-with>
              Check Integrity
            </.button>
          </div>
          <div class="flex flex-col mt-2 gap-1">
            <%= if @h5p_integrity_result do %>
              <% invalid_count = @h5p_integrity_result.invalid |> length() %> Found {invalid_count} invalid H5P content items.
              <%= if invalid_count > 0 do %>
                They can be removed from the storage layer to free up space.
                <.button phx-click="h5p-integrity-fix" phx-disable-with class="">
                  Remove unused H5P uploads
                </.button>
              <% end %>
            <% else %>
              <div class="flex flex-row italic text-neutral text-sm">
                Run the integrity check to find broken H5P content items.
              </div>
            <% end %>
          </div>
        </div>

        <div class="flex-1 min-w-2/5 bg-base-200 p-3 rounded-lg">
          <div class="flex items-center justify-between">
            <div class="flex flex-col align-start">
              <%!-- <h2><.link navigate={~p"/admin/orphans"}>Orphaned Items</.link></h2> --%>
              <%!-- <.button navigate={~p"/admin/orphans"}>View all</.button> --%>
            </div>
          </div>
        </div>

        <div class="w-full bg-base-200 p-3 rounded-lg">
          <div class="flex items-center justify-between">
            <div class="flex flex-col align-start">
              <h2>Recent Publications</h2>
              <span class="text-xs text-neutral">
                Showing {length(@publications)} most recent.
                <.link class="link" navigate={~p"/admin/published_items"}>View all</.link>
              </span>
            </div>
            <.button navigate={~p"/admin/published_items"}>View all</.button>
          </div>
          <div class="flex flex-col md:flex-row md: flex-wrap mt-2 gap-1">
            <%= for publication <- @publications do %>
              <AdminWeb.PublishedItemHTML.publication_row publication={publication}>
                <:action>
                  <.button navigate={~p"/admin/published_items/#{publication}"} class="btn btn-soft">
                    Manage
                  </.button>
                </:action>
              </AdminWeb.PublishedItemHTML.publication_row>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.admin>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, pgettext("page title", "Dashboard"))
      |> assign(
        :publications,
        Admin.Publications.list_published_items(10)
      )
      |> assign(
        :publication_stats,
        Admin.Publications.get_stats()
      )
      |> assign(
        :recycled_stats,
        Admin.RecycledItems.get_stats()
      )
      |> assign(
        :maintenances,
        Admin.Maintenance.list_upcoming_maintenance()
      )
      |> assign(:h5p_integrity_result, nil)

    {:ok, socket}
  end

  def handle_event("h5p-integrity-check", _params, socket) do
    result = Admin.H5PItems.integrity_check()
    {:noreply, assign(socket, :h5p_integrity_result, result)}
  end

  def handle_event("h5p-integrity-fix", _params, socket) do
    Admin.H5PItems.remove_inconsistent()
    result = Admin.H5PItems.integrity_check()
    {:noreply, assign(socket, :h5p_integrity_result, result)}
  end
end
