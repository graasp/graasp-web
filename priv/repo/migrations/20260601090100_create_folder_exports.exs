defmodule Admin.Repo.Migrations.CreateFolderExports do
  use Ecto.Migration

  def change do
    create table(:folder_exports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :item_id, references(:item, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"
      add :processed_count, :integer, null: false, default: 0
      add :total_count, :integer
      add :s3_key, :string
      add :error, :text
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, inserted_at: :created_at)
    end

    create index(:folder_exports, [:item_id])
    create index(:folder_exports, [:expires_at])

    # at most one in-flight export per folder
    create unique_index(:folder_exports, [:item_id],
             where: "status IN ('pending', 'running')",
             name: :folder_exports_in_flight_index
           )
  end
end
