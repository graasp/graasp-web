defmodule Spike.Items.ItemVisibility do
  @moduledoc "PROTOTYPE: core's `item_visibility` table."
  use Ash.Resource, domain: Spike.Items, data_layer: AshPostgres.DataLayer

  postgres do
    table "item_visibility"
    repo Spike.Repo
    migrate? false
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    # "public" | "hidden"
    attribute :type, :string, public?: true
    attribute :item_path, AshPostgres.Ltree, public?: true
  end

  actions do
    defaults [:read]
  end
end
