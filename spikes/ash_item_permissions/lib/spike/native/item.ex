defmodule Spike.Native.Item do
  @moduledoc """
  PROTOTYPE: item permissions the Ash way.

  - `permission`: the actor's highest permission on self-or-ancestors (core's packed `permission`, nil when none).
  - policies say who may do what; reads use `authorize_with: :error` for 403 vs 404.
  """
  use Ash.Resource,
    domain: Spike.Native,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Spike.Native.{Membership, Visibility}

  postgres do
    table "item"
    repo Spike.Repo
    migrate? false
  end

  resource do
    base_filter expr(is_nil(deleted_at))
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    attribute :name, :string, public?: true
    attribute :type, :string, public?: true
    attribute :path, AshPostgres.Ltree, public?: true
    attribute :order, :decimal, public?: true
    attribute :created_at, AshPostgres.TimestamptzUsec, public?: true
    attribute :deleted_at, AshPostgres.TimestamptzUsec, public?: true
  end

  relationships do
    # memberships granted on this very item (plain equality on the path)
    has_many :direct_memberships, Membership,
      source_attribute: :path,
      destination_attribute: :item_path,
      public?: true

    has_many :ancestor_memberships, Membership do
      no_attributes? true
      filter expr(ancestor_or_self(item_path, parent(path)))
    end

    # memberships on a strict ancestor: used for the home "top-most" list
    has_many :strict_ancestor_memberships, Membership do
      no_attributes? true
      filter expr(ancestor_or_self(item_path, parent(path)) and item_path != parent(path))
    end

    has_many :ancestor_visibilities, Visibility do
      no_attributes? true
      filter expr(ancestor_or_self(item_path, parent(path)))
    end
  end

  aggregates do
    max :permission, :ancestor_memberships, :permission do
      filter expr(account_id == ^actor(:id))
      public? true
    end

    exists :is_hidden, :ancestor_visibilities do
      filter expr(type == :hidden)
      public? true
    end

    exists :is_public, :ancestor_visibilities do
      filter expr(type == :public)
      public? true
    end
  end

  actions do
    defaults [:read]

    # stand-ins for write / admin actions (update, delete, share, ...), same policies
    read :as_writer
    read :as_admin

    # home "my items": top-most items holding one of the actor's own memberships
    read :home do
      pagination offset?: true, required?: false, countable: true

      filter expr(
               exists(direct_memberships, account_id == ^actor(:id)) and
                 not exists(strict_ancestor_memberships, account_id == ^actor(:id))
             )
    end
  end

  policies do
    policy action_type(:read) do
      # writers and admins see everything, hidden included
      authorize_if expr(permission in [:write, :admin])
      # readers and public visitors see what isn't hidden
      authorize_if expr(not is_hidden and (not is_nil(permission) or is_public))
    end

    policy action(:as_writer) do
      authorize_if expr(permission in [:write, :admin])
    end

    policy action(:as_admin) do
      authorize_if expr(permission == :admin)
    end
  end
end
