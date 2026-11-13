defmodule Admin.Repo.Migrations.AddAppKey do
  use Ecto.Migration

  # Superseded by 20250806000000_core_baseline (ADR 0002). This migration added the key column to apps,
  # which the baseline now creates as it exists in production. Databases that
  # already ran it never run it again (Ecto keeps no checksums).
  def up, do: :ok

  def down, do: :ok
end
