defmodule Spike.Items.Account do
  @moduledoc "PROTOTYPE: core's `account` table (members and guests), read-only."
  use Ash.Resource, domain: Spike.Items, data_layer: AshPostgres.DataLayer

  postgres do
    table "account"
    repo Spike.Repo
    migrate? false
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    attribute :name, :string, public?: true
    # "individual" | "guest"
    attribute :type, :string, public?: true
    attribute :is_validated, :boolean, public?: true
  end

  actions do
    defaults [:read]
  end
end
