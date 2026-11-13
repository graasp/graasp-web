import Config

# PROTOTYPE: scratch database built from core's drizzle migrations 0000-0021.
config :ash_item_permissions, Spike.Repo,
  database: "graasp_ash_spike_prototype",
  hostname: "localhost",
  pool_size: 5,
  timeout: 300_000,
  log: false,
  types: Spike.PostgresTypes

config :ash_item_permissions, ecto_repos: [Spike.Repo], ash_domains: [Spike.Items]
config :ash, disable_async?: true, default_string_length_count: :codepoints
config :logger, level: :warning
