import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/admin start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :admin, AdminWeb.Endpoint, server: true
end

# Lets the core repository migrate its own database with admin's migrations
# (admin owns the schema, ADR 0002): `DATABASE_URL=... mix ecto.migrate`.
# The URL takes precedence over the credentials in dev.exs and test.exs.
if config_env() in [:dev, :test] and System.get_env("DATABASE_URL") do
  config :admin, Admin.Repo, url: System.get_env("DATABASE_URL")
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :admin, Admin.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "graasp.org"
  port = String.to_integer(System.get_env("PORT") || "4000")
  protocol = System.get_env("PROTOCOL") || "https"
  public_port = String.to_integer(System.get_env("PUBLIC_PORT") || "443")

  config :admin, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :admin, AdminWeb.Endpoint,
    url: [scheme: protocol, host: host, port: public_port],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    check_origin: ["https://#{host}", "//#{host}"],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :admin, AdminWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :admin, AdminWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  if System.get_env("MAILER_CONNECTION") != nil do
    # get credentials from the connection string
    conn = System.get_env("MAILER_CONNECTION") |> URI.parse()
    [username, password] = conn.userinfo |> String.split(":", parts: 2)

    config :admin, Admin.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: conn.host,
      port: conn.port,
      username: username,
      password: password,
      ssl: System.get_env("MAILER_SSL") == "true"
  else
    config :admin, Admin.Mailer, adapter: Swoosh.Adapters.ExAwsAmazonSES
  end

  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  # Configure sentry environment name based on the environment where we deploy
  # Should be "development" when host contains "dev" and production otherwise
  #
  segments =
    host
    |> String.downcase()
    |> String.split(".")

  environment_name =
    cond do
      System.get_env("PHX_HOST") == nil -> "local"
      Enum.member?(segments, "dev") -> "development"
      Enum.member?(segments, "stage") -> "staging"
      true -> "production"
    end

  config :sentry,
    environment_name: environment_name,
    dsn: System.get_env("SENTRY_DSN")

  base_host =
    cond do
      environment_name == "production" -> "graasp.org"
      environment_name == "development" -> "dev.graasp.org"
      environment_name == "local" -> "localhost"
      true -> "graasp.org"
    end

  # A note about these configurations is made in the dev.exs file.
  # TLDR: We need to use 2 configs for now in development because of the vite proxy limitations.
  #       In production these configs have the same value.
  config :admin, base_host: base_host
  config :admin, backend_origin: "https://#{base_host}"
  config :admin, client_origin: "https://#{base_host}"
  config :admin, umami_origin: "https://umami.#{base_host}"
  config :admin, library_origin: "https://library.#{base_host}"

  # Get the value of the header secret to communicate with Meilisearch
  config :admin, :publication_reindex_headers, [
    {"meilisearch-rebuild", System.get_env("MEILISEARCH_REBUILD_SECRET")}
  ]

  # Config the File Items bucket name
  config :admin, :file_items_bucket, System.get_env("FILE_ITEMS_BUCKET_NAME", "file-items")
  config :admin, :h5p_bucket, System.get_env("H5P_CONTENT_BUCKET_NAME", "h5p-items")

  # Configure Ex_AWS using first env vars, then instance role (automatic credentials in ECS tasks)
  config :ex_aws,
    access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role, :pod_identity],
    secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role, :pod_identity],
    region: {:system, "AWS_REGION"}

  s3_config =
    [
      # If using custom endpoints like LocalStack or MinIO, path_style: true is often necessary.
      path_style: System.get_env("AWS_S3_USE_PATH_STYLE") == "true",
      region: System.get_env("AWS_REGION", "eu-central-1"),
      scheme: System.get_env("AWS_S3_SCHEME"),
      host: System.get_env("AWS_S3_HOST"),
      port: System.get_env("AWS_S3_PORT")
    ]
    # remove nil values
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)

  config :ex_aws, :s3, s3_config

  # override the ses region to use Frankfurt since SES does not exist in eu-central-2
  config :ex_aws, :ses, region: "eu-central-1"

  # Configure Umami
  config :admin, :umami,
    username: System.get_env("UMAMI_USERNAME"),
    password: System.get_env("UMAMI_PASSWORD")

  config :admin, :admin_shared_secret, System.get_env("ADMIN_SHARED_SECRET")

  config :admin,
         :graasp_apps_jwt_secret,
         System.get_env("GRAASP_APPS_JWT_SECRET") ||
           raise("environment variable GRAASP_APPS_JWT_SECRET is missing")

  config :admin,
         :graasp_app_key,
         System.get_env("GRAASP_APP_KEY") ||
           raise("environment variable GRAASP_APP_KEY is missing")

  config :admin,
         :chatbot_frame_ancestors,
         System.get_env("CHATBOT_FRAME_ANCESTORS", "https://#{base_host}")
         |> String.split(",")

  config :admin,
         :openai_api_key,
         System.get_env("OPENAI_API_KEY") ||
           raise("environment variable OPENAI_API_KEY is missing")

  config :admin, :openai_model, System.get_env("OPENAI_MODEL", "gpt-4o-mini")
end

config :admin, :umami_website_id, System.get_env("UMAMI_WEBSITE_ID")
config :admin, :recaptcha_site_key, System.get_env("RECAPTCHA_SITE_KEY")
