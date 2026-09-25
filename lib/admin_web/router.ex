defmodule AdminWeb.Router do
  use AdminWeb, :router

  import Oban.Web.Router
  import AdminWeb.UserAuth

  import AdminWeb.Marketing.Macros, only: [generate_localized_routes: 0]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AdminWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug AdminWeb.Plugs.Locale, "en"
  end

  pipeline :browser_admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AdminWeb.Layouts, :admin_root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug AdminWeb.Plugs.Locale, "en"
  end

  pipeline :browser_feed do
    plug :accepts, ["xml"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_bearer_auth do
    plug :accepts, ["json"]
    plug AdminWeb.Plugs.BearerAuth
  end

  # Pipeline for the chatbot app, embedded in an iframe by the Graasp
  # platform. Deliberately skips `put_secure_browser_headers` (which sends
  # `X-Frame-Options: SAMEORIGIN`, blocking cross-origin framing) in favor of
  # an explicit `frame-ancestors` CSP allow-list. Auth is per-item, via the
  # Graasp app JWT verified in the LiveView itself (Admin.Apps.Token), not
  # via admin's own user login, so this does not use `:fetch_current_scope_for_user`.
  pipeline :chatbot_frame do
    plug :accepts, ["html"]
    plug :fetch_session
    # required for LiveView's websocket connect to validate against the
    # session (LiveView ties its CSRF token to the session protect_from_forgery
    # sets up) — without it every mount fails its session check and the
    # client keeps reconnecting in a loop.
    # NOTE: this relies on the session cookie (SameSite=Lax) reaching the
    # server. In production the player and /apps/chatbot are both served
    # under graasp.org (admin serves the player as static assets too), so the
    # iframe embed is same-site and the cookie flows normally; same goes for
    # local dev since every port here is still "localhost". This would need
    # revisiting only if the chatbot app ever moved to a different
    # registrable domain than the player.
    plug :protect_from_forgery
    plug :fetch_live_flash
    plug :put_root_layout, html: {AdminWeb.Layouts, :chatbot_root}
    plug AdminWeb.Plugs.Locale, "en"
    plug :allow_chatbot_framing
  end

  scope "/", AdminWeb do
    pipe_through :api

    get "/up", HealthController, :up
    # alias route does the same as "/up"
    get "/health", HealthController, :up
  end

  # routes that are protected by the shared secret (for use by the nodejs backend)
  scope "/internal", AdminWeb do
    pipe_through :api_bearer_auth

    get "/version", HealthController, :version
  end

  scope "/", AdminWeb do
    pipe_through :browser_feed
    get "/blog/feed.atom", BlogController, :atom_feed
  end

  scope "/", AdminWeb do
    pipe_through :browser
    get "/", LandingController, :index
    get "/about-us", LandingController, :about
    get "/contact", LandingController, :contact

    scope "/blog" do
      get "/", BlogController, :index
      get "/:id", BlogController, :show
    end

    scope "/docs" do
      get "/", DocsController, :index
      get "/:id", DocsController, :show
    end

    scope "/technical/docs" do
      get "/", DocsController, :index_dev
      get "/:id", DocsController, :show_dev
    end

    # routes to test locale
    get "/locale", LandingController, :locale
    post "/locale", LandingController, :change_locale
    delete "/locale", LandingController, :remove_locale

    generate_localized_routes()

    get "/home", ClientController, :index
    get "/published", ClientController, :index
    get "/recycled", ClientController, :index
    get "/account/*path", ClientController, :index
    get "/auth/*path", ClientController, :index
    get "/builder/*path", ClientController, :index
    get "/player/*path", ClientController, :index
    get "/analytics/*path", ClientController, :index

    # TASK: remove once we migrate the library fully here
    get "/library", RedirectionController, :library

    get "/accounts/:account_id/marketing/unsubscribe",
        AccountController,
        :marketing_emails_unsubscribe

    get "/accounts/:account_id/marketing/subscribe",
        AccountController,
        :marketing_emails_subscribe
  end

  scope "/admin", AdminWeb do
    pipe_through :browser_admin

    get "/", AdminController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", AdminWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:admin, :dev_routes) do
    scope "/dev" do
      pipe_through :browser_admin

      forward "/mailbox", Plug.Swoosh.MailboxPreview

      # S3 debug interface
      delete "/s3/:id/:key", AdminWeb.Dev.S3Controller, :delete
      resources "/s3", AdminWeb.Dev.S3Controller, only: [:index, :show]

      # plays the Graasp parent frame role for the chatbot app, so /apps/chatbot
      # can be exercised without a running core instance
      get "/chatbot-mock", AdminWeb.Dev.ChatbotMockController, :index

      live_session :dev_authenticated_user,
        on_mount: [{AdminWeb.UserAuth, :require_authenticated}] do
        live "/tools", AdminWeb.DevLive.Index, :index
      end
    end
  end

  scope "/apps/chatbot", AdminWeb.Chatbot do
    pipe_through :chatbot_frame

    live_session :chatbot do
      live "/", PlayerLive, :index
    end
  end

  # Public LiveView pages
  scope "/", AdminWeb do
    pipe_through [:browser]

    get "/library/collections/:item_id/thumbnail", ThumbnailController, :show

    live_session :public,
      session: {AdminWeb.Public, :session, [[locale: "fr"]]},
      on_mount: [{AdminWeb.UserAuth, :mount_current_scope}, AdminWeb.RestoreLocale] do
      scope "/library-beta" do
        live "/", LibraryLive.Index, :index
        live "/collections/:item_id", LibraryLive.Show, :show
        live "/members/:member_id", LibraryLive.Member, :show
      end
    end
  end

  ## Authentication LV routes
  scope "/admin", AdminWeb do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    pipe_through [:browser_admin, :require_authenticated_user]

    live_dashboard "/dev/dashboard", metrics: AdminWeb.Telemetry, ecto_repos: [Admin.Repo]

    live_session :require_authenticated_user,
      on_mount: [{AdminWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # dashboard
      live "/dashboard", DashboardLive.Index, :index

      # users
      live "/users", UserLive.Listing, :list
      live "/users/new", UserLive.Form, :new

      # published_items
      live "/published_items/:id/unpublish", PublishedItemLive.Unpublish, :unpublish
      live "/published_items/search_index", PublicationSearchIndexLive, :index

      # apps
      scope "/apps" do
        live "/:app_id", AppInstanceLive.Show, :show
      end

      # analytics
      scope "/analytics" do
        live "/graph", AnalyticsLive.Example, :show
        live "/events", AnalyticsLive.EventGenerator, :show
      end

      scope "/publishers" do
        live "/", PublisherLive.Index, :index
        live "/new", PublisherLive.Form, :new

        scope "/:publisher_id" do
          live "/", PublisherLive.Show, :show
          live "/edit", PublisherLive.Form, :edit

          scope "/apps" do
            live "/new", AppInstanceLive.Form, :new

            scope "/:app_id" do
              live "/", AppInstanceLive.Show, :show
              live "/edit", AppInstanceLive.Form, :edit
            end
          end
        end
      end

      scope "/notifications" do
        live "/", NotificationLive.Index, :index
        live "/new", NotificationLive.Form, :new

        scope "/:notification_id" do
          live "/", NotificationLive.Show, :show
          live "/archive", NotificationLive.Show, :archive
          live "/edit", NotificationLive.Form, :edit

          live "/messages/new", NotificationMessageLive.Form, :new
          live "/messages/:lang/edit", NotificationMessageLive.Form, :edit
        end
      end

      scope "/test" do
        live "/sentry", TestLive.Sentry, :sentry
      end

      scope "/trash" do
        live "/", TrashLive.Index, :index
      end

      live "/housekeeping", HousekeepingLive.Index, :index

      scope "/validation" do
        live "/", ValidationLive.Poc, :index
        live "/:item_id/validate", ValidationLive.Form, :validate
      end

      scope "/orphans" do
        live "/", OrphansLive.Index, :index
      end
    end

    post "/users/update-password", UserSessionController, :update_password
    get "/about", AdminController, :about
  end

  ## Authentication related routes
  scope "/admin", AdminWeb do
    pipe_through [:browser_admin]

    live_session :current_user,
      on_mount: [{AdminWeb.UserAuth, :mount_current_scope}] do
      # live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    get "/users/register", UserSessionController, :register
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Authenticated controller routes
  scope "/admin", AdminWeb do
    pipe_through [:browser_admin, :require_authenticated_user]

    resources "/maintenance", PlannedMaintenanceController
    get "/users/:id", UserController, :show

    get "/published_items/featured", PublishedItemController, :featured
    resources "/published_items", PublishedItemController, except: [:update, :delete, :edit]
    post "/published_items/search", PublishedItemController, :search

    # oban dashboard for jobs
    oban_dashboard("/oban")
  end

  defp allow_chatbot_framing(conn, _opts) do
    ancestors =
      :admin
      |> Application.get_env(:chatbot_frame_ancestors, [])
      |> Enum.join(" ")

    Plug.Conn.put_resp_header(conn, "content-security-policy", "frame-ancestors #{ancestors}")
  end
end
