defmodule Spike.Native.Visibility do
  @moduledoc "PROTOTYPE: `item_visibility`."
  use Ash.Resource, domain: Spike.Native, data_layer: AshPostgres.DataLayer

  postgres do
    table "item_visibility"
    repo Spike.Repo
    migrate? false
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    attribute :type, :atom, constraints: [one_of: [:public, :hidden]], public?: true
    attribute :item_path, AshPostgres.Ltree, public?: true
  end

  actions do
    defaults [:read]
  end
end
