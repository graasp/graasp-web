defmodule Admin.Repo.Migrations.CreateItem do
  use Ecto.Migration

  def change do
    # TODO: rename table with plural once we are allowed to do so.
    create table(:item) do
      add :name, :string, size: 500, null: false
      add :type, :string, null: false
      add :description, :text
      add :path, :ltree, null: false
      # Add the references(:users, type: :id, on_delete: :delete_all)
      add :creator_id, :binary_id
      timestamps(type: :utc_datetime)
      add :lang, :string, null: false
      add :extra, :jsonb, null: false
      add :settings, :jsonb
      add :deleted_at, :utc_datetime
      add :order, :decimal, precision: 10, scale: 2
    end

    create index(:item, [:creator_id])
    create unique_index(:item, [:path], name: "item_path_key1")
    create index(:item, [:path], name: "IDX_gist_item_path", using: :gist)
    create index(:item, [:deleted_at], name: "IDX_item_deleted_at")

    create index(:item, [:path],
             name: "IDX_gist_item_path_deleted_at",
             using: :gist,
             where: "deleted_at IS NULL"
           )

    alter table(:published_items) do
      remove :name, :string
      remove :description, :text
    end

    # Add the new item_path column with the reference
    alter table(:published_items) do
      add :item_path,
          references(:item,
            column: :path,
            type: :ltree,
            on_delete: :delete_all,
            on_update: :update_all
          )
    end

    # Add the item_id column in removal_notice
    alter table(:removal_notices) do
      add :item_id,
          references(:item,
            column: :id,
            type: :binary_id,
            on_delete: :delete_all,
            on_update: :nothing
          )

      remove :user_id,
             references(:users, type: :binary_id, on_delete: :delete_all)
    end

    create index(:removal_notices, [:item_id])

    # create the recycled_item_data table
    create table(:recycled_item_data) do
      add :item_path,
          references(:item, column: :path, type: :ltree, on_delete: :delete_all),
          null: false

      add :creator_id,
          references(:account, column: :id, type: :binary_id, on_delete: :nilify_all)

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:recycled_item_data, [:item_path],
             name: "IDX_recycled_item_data_item_path",
             using: :gist,
             unique: false
           )

    create index(:recycled_item_data, [:created_at], name: "IDX_recycled_item_data_created_at")

    create table(:item_membership) do
      add :permission, :string
      add :item_path, references(:item, column: :path, type: :ltree, on_delete: :delete_all)
      add :creator_id, references(:account, column: :id, type: :binary_id, on_delete: :nilify_all)

      add :account_id,
          references(:account, column: :id, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:item_membership, [:item_path],
             name: "IDX_gist_item_membership_path",
             using: :gist,
             unique: false
           )
  end
end
