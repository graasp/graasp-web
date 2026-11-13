defmodule Spike.Repo do
  # An AshPostgres.Repo is "a thin wrapper around an Ecto.Repo": the plain-Ecto
  # side of the spike uses this same repo.
  use AshPostgres.Repo, otp_app: :ash_item_permissions, warn_on_missing_ash_functions?: false

  # "ash-functions" lets AshPostgres raise errors in SQL (authorize_with: :error);
  # installed from priv/ash_functions.sql, a hand-written migration in admin
  def installed_extensions, do: ["ltree", "uuid-ossp", "citext", "ash-functions"]
  def min_pg_version, do: %Version{major: 16, minor: 0, patch: 0}
end
