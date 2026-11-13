defmodule Spike.Repo do
  # An AshPostgres.Repo is "a thin wrapper around an Ecto.Repo": the plain-Ecto
  # side of the spike uses this same repo.
  use AshPostgres.Repo, otp_app: :ash_item_permissions, warn_on_missing_ash_functions?: false

  def installed_extensions, do: ["ltree", "uuid-ossp", "citext"]
  def min_pg_version, do: %Version{major: 16, minor: 0, patch: 0}
end
