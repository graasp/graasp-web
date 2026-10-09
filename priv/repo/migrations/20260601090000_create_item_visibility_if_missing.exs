defmodule Admin.Repo.Migrations.CreateItemVisibilityIfMissing do
  use Ecto.Migration

  # `item_visibility` is owned by the Graasp core backend and already exists in
  # deployed databases. It is created here (idempotently) so that a fresh
  # database, such as the test one, has the table the folder export reads.
  def up do
    execute("""
    DO $$ BEGIN
      CREATE TYPE item_visibility_type AS ENUM ('public', 'hidden');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    """)

    execute("""
    CREATE TABLE IF NOT EXISTS item_visibility (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      type item_visibility_type NOT NULL,
      item_path ltree NOT NULL,
      creator_id uuid,
      created_at timestamptz NOT NULL DEFAULT now(),
      CONSTRAINT "item-visibility" UNIQUE (type, item_path)
    )
    """)

    execute(
      ~s|CREATE INDEX IF NOT EXISTS "IDX_gist_item_visibility_path" ON item_visibility USING gist (item_path)|
    )
  end

  # the table is not ours to drop
  def down, do: :ok
end
