defmodule Spike.Native.Membership do
  @moduledoc "PROTOTYPE: `item_membership` with permission as an ordered Ash enum."
  use Ash.Resource, domain: Spike.Native, data_layer: AshPostgres.DataLayer

  postgres do
    table "item_membership"
    repo Spike.Repo
    migrate? false
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    attribute :permission, Spike.Native.Permission, public?: true
    attribute :account_id, :uuid, public?: true
    attribute :item_path, AshPostgres.Ltree, public?: true
  end

  actions do
    defaults [:read]
  end
end
