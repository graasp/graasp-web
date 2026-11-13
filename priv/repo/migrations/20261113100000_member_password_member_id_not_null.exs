defmodule Admin.Repo.Migrations.MemberPasswordMemberIdNotNull do
  use Ecto.Migration

  # Core's drizzle migration 0021, which production never ran. Setting NOT NULL
  # again is a no-op, so databases where drizzle already applied it are fine.
  # Drizzle also dropped and recreated `members_view` around it, which is not
  # needed: the view does not depend on the column's nullability.
  def change do
    execute "ALTER TABLE member_password ALTER COLUMN member_id SET NOT NULL",
            "ALTER TABLE member_password ALTER COLUMN member_id DROP NOT NULL"
  end
end
