defmodule Spike.Items.Item do
  @moduledoc """
  PROTOTYPE: core's `item` table with Graasp's permission model as Ash policies.

  Port of core's `AuthorizedItemService.getPropertiesForItem` (single) /
  `getPropertiesForItems` (batch) and `filterOutItems` (children).
  """
  use Ash.Resource,
    domain: Spike.Items,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Spike.Items.{ItemMembership, ItemVisibility}

  postgres do
    table "item"
    repo Spike.Repo
    migrate? false
  end

  resource do
    # core's items table hides soft-deleted rows (item_view does the same)
    base_filter expr(is_nil(deleted_at))
  end

  attributes do
    attribute :id, :uuid, primary_key?: true, allow_nil?: false, public?: true
    attribute :name, :string, public?: true
    attribute :type, :string, public?: true
    attribute :path, AshPostgres.Ltree, public?: true
    attribute :order, :decimal, public?: true
    # core columns are timestamptz: :utc_datetime_usec would cast them to `timestamp`
    # in every filter, which breaks row estimates and index use
    attribute :created_at, AshPostgres.TimestamptzUsec, public?: true
    attribute :deleted_at, AshPostgres.TimestamptzUsec, public?: true
  end

  relationships do
    # Q3: has_many over the ltree foreign key, the other side of the belongs_to
    has_many :memberships, ItemMembership,
      source_attribute: :path,
      destination_attribute: :item_path,
      public?: true

    # v2: memberships and visibilities on self-or-ancestors, as relationships with no
    # shared attribute, so aggregates over them compile to one lateral join each
    has_many :ancestor_memberships, ItemMembership do
      no_attributes? true
      filter expr(fragment("? @> ?", item_path, parent(path)))
    end

    has_many :ancestor_visibilities, ItemVisibility do
      no_attributes? true
      filter expr(fragment("? @> ?", item_path, parent(path)))
    end
  end

  aggregates do
    max :highest_rank, :ancestor_memberships, :rank do
      filter expr(account_id == ^actor(:id))
      public? true
    end

    exists :hidden_v2, :ancestor_visibilities do
      filter expr(type == "hidden")
      public? true
    end

    exists :public_v2, :ancestor_visibilities do
      filter expr(type == "public")
      public? true
    end
  end

  calculations do
    # Highest permission the actor holds on this item or an ancestor.
    # "highest >= X" == "exists a membership on self-or-ancestor with permission in allowed(X)".
    calculate :highest_permission,
              :string,
              expr(
                cond do
                  exists(
                    ItemMembership,
                    account_id == ^actor(:id) and permission == "admin" and
                      fragment("? @> ?", item_path, parent(path))
                  ) ->
                    "admin"

                  exists(
                    ItemMembership,
                    account_id == ^actor(:id) and permission == "write" and
                      fragment("? @> ?", item_path, parent(path))
                  ) ->
                    "write"

                  exists(
                    ItemMembership,
                    account_id == ^actor(:id) and permission == "read" and
                      fragment("? @> ?", item_path, parent(path))
                  ) ->
                    "read"

                  true ->
                    nil
                end
              ),
              public?: true

    calculate :is_hidden,
              :boolean,
              expr(
                exists(
                  ItemVisibility,
                  type == "hidden" and fragment("? @> ?", item_path, parent(path))
                )
              ),
              public?: true

    calculate :is_public,
              :boolean,
              expr(
                exists(
                  ItemVisibility,
                  type == "public" and fragment("? @> ?", item_path, parent(path))
                )
              ),
              public?: true

    # Core's decision, including the error kind: "ok" | "member_cannot_access" |
    # "member_cannot_read" | "member_cannot_write" | "member_cannot_admin".
    calculate :access,
              :string,
              expr(
                cond do
                  # HIDDEN CHECK: read-only members and public visitors can't see hidden items
                  (highest_permission == "read" or (is_nil(highest_permission) and is_public)) and
                      is_hidden ->
                    "member_cannot_access"

                  # correct membership level
                  (^arg(:required) == "read" and not is_nil(highest_permission)) or
                    (^arg(:required) == "write" and highest_permission in ["write", "admin"]) or
                      (^arg(:required) == "admin" and highest_permission == "admin") ->
                    "ok"

                  # PUBLIC CHECK
                  ^arg(:required) == "read" and is_public ->
                    "ok"

                  is_nil(highest_permission) ->
                    "member_cannot_access"

                  ^arg(:required) == "read" ->
                    "member_cannot_read"

                  ^arg(:required) == "write" ->
                    "member_cannot_write"

                  true ->
                    "member_cannot_admin"
                end
              ) do
      public? true
      argument :required, :string, allow_nil?: false
    end
  end

  calculations do
    # v2: same decision on top of the aggregates (each fact computed once)
    calculate :access_v2,
              :string,
              expr(
                cond do
                  (highest_rank == 1 or (is_nil(highest_rank) and public_v2)) and hidden_v2 ->
                    "member_cannot_access"

                  (^arg(:required) == "read" and highest_rank >= 1) or
                    (^arg(:required) == "write" and highest_rank >= 2) or
                      (^arg(:required) == "admin" and highest_rank >= 3) ->
                    "ok"

                  ^arg(:required) == "read" and public_v2 ->
                    "ok"

                  is_nil(highest_rank) ->
                    "member_cannot_access"

                  ^arg(:required) == "read" ->
                    "member_cannot_read"

                  ^arg(:required) == "write" ->
                    "member_cannot_write"

                  true ->
                    "member_cannot_admin"
                end
              ) do
      public? true
      argument :required, :string, allow_nil?: false
    end
  end

  actions do
    defaults [:read]

    # direct children of `parent_path`, in core's order (order, created_at)
    read :children do
      argument :parent_path, AshPostgres.Ltree, allow_nil?: false

      filter expr(
               fragment("? <@ ?", path, type(^arg(:parent_path), AshPostgres.Ltree)) and
                 fragment(
                   "nlevel(?) = nlevel(?) + 1",
                   path,
                   type(^arg(:parent_path), AshPostgres.Ltree)
                 )
             )

      prepare build(sort: [order: :asc, created_at: :asc])
    end

    # "filter by permission": every item the actor holds at least `min_permission` on
    read :accessible do
      argument :min_permission, :string, allow_nil?: false
      filter expr(access(required: ^arg(:min_permission)) == "ok")
    end

    read :accessible_v2 do
      argument :min_permission, :string, allow_nil?: false
      filter expr(access_v2(required: ^arg(:min_permission)) == "ok")
    end

    # v3: narrow candidates to subtrees of the actor's memberships first, like core's
    # getAccessibleItems (write/admin only: public items need no membership)
    read :accessible_v3 do
      argument :min_permission, :string, allow_nil?: false

      filter expr(
               fragment(
                 "? <@ ANY(ARRAY(SELECT item_path FROM item_membership WHERE account_id = ?))",
                 path,
                 type(^actor(:id), :uuid)
               ) and access_v2(required: ^arg(:min_permission)) == "ok"
             )
    end

    # a route guarded by matchOne(validatedMember, guest) on top of the item check
    read :for_validated_member_or_guest
  end

  policies do
    # == core's item check, for every read: rows the actor may not read are dropped
    policy action_type(:read) do
      description "item_access_read"
      # v2 (aggregates); v1 `access` passed the same matrix as the policy first
      authorize_if expr(access_v2(required: "read") == "ok")
    end

    # == matchOne(validatedMemberAccountRole, guestAccountRole): checks inside one
    # policy are ORed; separate policies are ANDed with the item check above
    policy action(:for_validated_member_or_guest) do
      description "match_one_validated_member_or_guest"
      authorize_if actor_attribute_equals(:type, "guest")
      authorize_if expr(^actor(:type) == "individual" and ^actor(:is_validated) == true)
    end
  end
end
