defmodule AdminWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AdminWeb, :html

  alias AdminWeb.LandingHTML

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true
  attr :class, :string, default: nil, doc: "the class attribute for the main div"

  def admin(assigns) do
    ~H"""
    <.menu_bar {assigns} />

    <main class={["grow px-4 py-8 sm:px-6 lg:px-8 bg-base-200", @class]}>
      <div class="mx-auto max-w-4xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :locale_form, :map,
    default: nil,
    doc: "the form for locale selection"

  slot :inner_block, required: true
  attr :class, :string, default: nil, doc: "the class attribute for the main div"

  def landing(assigns) do
    ~H"""
    <.landing_menu {assigns} />
    <main class={["grow flex flex-col", @class]}>
      <div class="grow">
        {render_slot(@inner_block)}
      </div>
      <LandingHTML.landing_footer {assigns} />
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true, doc: "the inner block of the layout"

  def simple(assigns) do
    ~H"""
    <div class="navbar bg-base-100 shadow-sm ">
      <div class="flex flex-row max-w-screen-xl mx-auto w-full">
        <div class="navbar-start">
          <.graasp_logo_link />
        </div>
        <div class="navbar-end"></div>
      </div>
    </div>
    <main class="grow flex flex-col">
      <div class="grow">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:success} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label={gettext("Use system theme")}
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label={gettext("Use light theme")}
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label={gettext("Use dark theme")}
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  defp burger_menu(assigns) do
    ~H"""
    <div
      tabindex="0"
      role="button"
      aria-label={gettext("Open navigation menu")}
      class="btn btn-ghost lg:hidden"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="h-5 w-5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M4 6h16M4 12h8m-8 6h16"
        />
      </svg>
    </div>
    """
  end

  def menu_bar(assigns) do
    ~H"""
    <div class="navbar shadow-sm">
      <div class="navbar-start">
        <%= if @current_scope do %>
          <div class="dropdown">
            <.burger_menu />
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
            >
              <li>
                <.link navigate={~p"/admin/published_items"}>Publications</.link>
                <ul class="p-2">
                  <li><.link navigate={~p"/admin/published_items"}>Recent</.link></li>
                  <li><.link navigate={~p"/admin/published_items/featured"}>Featured</.link></li>
                  <li><.link navigate={~p"/admin/validation"}>Validation Review</.link></li>
                  <li>
                    <.link navigate={~p"/admin/published_items/search_index"}>Search Index</.link>
                  </li>
                </ul>
              </li>
              <li><.link navigate={~p"/admin/publishers"}>Apps</.link></li>
              <li><.link navigate={~p"/admin/notifications"}>Mailing</.link></li>
              <li><.link navigate={~p"/admin/users"}>Admins</.link></li>
              <li><.link navigate={~p"/admin/analytics/graph"}>Analytics</.link></li>
              <li>
                <span>Development</span>
                <ul class="p-2">
                  <li><.link navigate={~p"/admin/about"}>About</.link></li>
                  <li><.link navigate={~p"/admin/trash"}>Trash</.link></li>
                  <li><.link navigate={~p"/admin/oban"}>Job Queues</.link></li>
                  <li><.link navigate={~p"/admin/dev/dashboard"}>Live Dashboard</.link></li>
                </ul>
              </li>

              <div class="divider m-0"></div>
              <div class="flex flex-col items-center gap-1">
                <%= if @current_scope do %>
                  <span>{@current_scope.user.email}</span>

                  <.link class="btn btn-soft" navigate={~p"/admin/users/settings"}>
                    <.icon name="hero-cog" class="size-5 " /> Settings
                  </.link>
                  <.link class="btn btn-soft" href={~p"/admin/users/log-out"} method="delete">
                    <.icon name="hero-arrow-right-on-rectangle" class="size-5 " /> Log out
                  </.link>
                <% else %>
                  <.link class="btn btn-ghost" href={~p"/admin/users/log-in"}>Log in</.link>
                <% end %>
              </div>
            </ul>
          </div>
        <% end %>
        <.link navigate={~p"/admin/dashboard"} class="btn btn-ghost text-xl">
          <img src="/images/logo.svg" width="32" />
          <span class="text-sm font-semibold">Admin</span>
        </.link>
      </div>
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1 z-1000">
          <%= if @current_scope do %>
            <li>
              <details>
                <summary>Publications</summary>
                <ul class="p-2">
                  <li><.link navigate={~p"/admin/published_items"}>Recent</.link></li>
                  <li>
                    <.link navigate={~p"/admin/published_items/featured"}>Featured</.link>
                  </li>
                  <li><.link navigate={~p"/admin/validation"}>Validation Review</.link></li>
                  <li>
                    <.link navigate={~p"/admin/published_items/search_index"}>Search Index</.link>
                  </li>
                </ul>
              </details>
            </li>
            <li><.link navigate={~p"/admin/publishers"}>Apps</.link></li>
            <li><.link navigate={~p"/admin/notifications"}>Mailing</.link></li>
            <li><.link navigate={~p"/admin/users"}>Admins</.link></li>
            <li><.link navigate={~p"/admin/analytics/graph"}>Analytics</.link></li>
            <li>
              <details>
                <summary>Development</summary>
                <ul class="p-2">
                  <li><.link navigate={~p"/admin/about"}>About</.link></li>
                  <li><.link navigate={~p"/admin/trash"}>Trash</.link></li>
                  <li><.link navigate={~p"/admin/oban"}>Job Queues</.link></li>
                  <li><.link navigate={~p"/admin/dev/dashboard"}>Live Dashboard</.link></li>
                </ul>
              </details>
            </li>
          <% end %>
        </ul>
      </div>
      <div class="navbar-end gap-1">
        <div class="hidden items-center lg:flex gap-2">
          <%= if @current_scope do %>
            <span>{@current_scope.user.email}</span>
            <.link class="btn btn-circle" navigate={~p"/admin/users/settings"} title="Settings">
              <.icon name="hero-cog" class="size-5 " />
            </.link>
            <.link
              class="btn btn-circle"
              href={~p"/admin/users/log-out"}
              title="Log out"
              method="delete"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-5 " />
            </.link>
          <% else %>
            <.link class="btn btn-ghost" href={~p"/admin/users/log-in"}>Log in</.link>
          <% end %>
        </div>
        <.theme_toggle />
      </div>
    </div>
    """
  end

  def landing_menu(assigns) do
    ~H"""
    <div class="navbar bg-base-100 shadow-xl shadow-xl/30">
      <div class="w-full flex flex-row lg:max-w-screen-xl lg:mx-auto gap-4">
        <div class="navbar-start w-fit">
          <div class="dropdown">
            <.burger_menu />
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
            >
              <li>
                <.link navigate={~p"/library"}>{gettext("Library")}</.link>
              </li>
              <li>
                <.link navigate={~p"/blog"}>{gettext("Blog")}</.link>
              </li>
              <li>
                <.link navigate={~p"/docs"}>{gettext("Support")}</.link>
              </li>
              <li>
                <.link navigate={~p"/about-us"}>{gettext("About")}</.link>
              </li>
              <li>
                <.link navigate={~p"/contact"}>{gettext("Contact")}</.link>
              </li>
              <li>
                <.link navigate={~p"/admin/dashboard"}>{gettext("Admin")}</.link>
              </li>

              <div class="divider m-0"></div>
              <div class="flex flex-col items-center gap-1">
                <%= if @current_scope do %>
                  <.link class="btn btn-soft" navigate="/builder">
                    {gettext("Get started")}
                  </.link>
                <% else %>
                  <.link class="btn btn-soft" navigate={~p"/auth/login?lang=#{Gettext.get_locale()}"}>
                    {gettext("Log in")}
                  </.link>
                <% end %>
              </div>
            </ul>
          </div>
          <.graasp_logo_link />
        </div>
        <div class="navbar-center hidden lg:flex">
          <ul class="menu menu-horizontal px-1">
            <li><.link class="text-primary" navigate={~p"/library"}>{gettext("Library")}</.link></li>
            <li><.link class="text-primary" navigate={~p"/blog"}>{gettext("Blog")}</.link></li>
            <li>
              <.link class="text-primary" navigate={~p"/docs"}>{gettext("Support")}</.link>
            </li>
            <li><.link class="text-primary" navigate={~p"/about-us"}>{gettext("About")}</.link></li>
            <li><.link class="text-primary" navigate={~p"/contact"}>{gettext("Contact")}</.link></li>
            <%= if @current_scope do %>
              <li>
                <.link class="text-primary" navigate={~p"/admin/dashboard"}>{gettext("Admin")}</.link>
              </li>
            <% end %>
          </ul>
        </div>
        <div class="navbar-end gap-1 w-full">
          <div class="hidden items-center lg:flex gap-2">
            <%= if @current_scope do %>
              <.link class="btn btn-accent" navigate="/builder">
                {gettext("Get started")}
              </.link>
            <% else %>
              <.link class="btn btn-accent" navigate={~p"/auth/login?lang=#{Gettext.get_locale()}"}>
                {gettext("Log in")}
              </.link>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def graasp_logo_link(assigns) do
    ~H"""
    <.link navigate={~p"/"} class="flex flex-row items-center gap-2 text-primary">
      <.logo size={44} fill="var(--color-primary)" />
      <span class="text-2xl font-semibold">Graasp</span>
    </.link>
    """
  end
end
