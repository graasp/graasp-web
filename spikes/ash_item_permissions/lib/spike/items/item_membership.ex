defmodule Spike.Items.ItemMembership do
  @moduledoc "PROTOTYPE: core's `item_membership` table."
  use Ash.Resource, domain: Spike.Items, data_layer: AshPostgres.DataLayer

  postgres do
    table "item_membership"
    repo Spike.Repo
    migrate? false
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    # "read" | "write" | "admin"
    attribute :permission, :string, public?: true
    attribute :account_id, :uuid, public?: true
  end

  relationships do
    # Q3: belongs_to over the ltree foreign key `item_path -> item.path`
    belongs_to :item, Spike.Items.Item,
      source_attribute: :item_path,
      destination_attribute: :path,
      attribute_type: AshPostgres.Ltree,
      attribute_public?: true,
      public?: true

    belongs_to :account, Spike.Items.Account, define_attribute?: false, public?: true
  end

  calculations do
    calculate :rank,
              :integer,
              expr(
                cond do
                  permission == "admin" -> 3
                  permission == "write" -> 2
                  permission == "read" -> 1
                end
              ),
              public?: true
  end

  actions do
    defaults [:read]
  end
end
