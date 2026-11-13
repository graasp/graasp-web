defmodule Admin.Repo.Migrations.CreateItemVisibilityIfMissing do
  use Ecto.Migration

  # Superseded by 20250806000000_core_baseline (ADR 0002). This migration created the item_visibility table when missing,
  # which the baseline now creates as it exists in production. Databases that
  # already ran it never run it again (Ecto keeps no checksums).
  def up, do: :ok

  def down, do: :ok
end
