defmodule Spike.Plain do
  @moduledoc """
  PROTOTYPE: the same slice in plain Ecto. One lateral join per fact, the decision
  as one SQL CASE (`access/1`) reused for both `select` and `where`.
  """
  import Ecto.Query
  alias Spike.Plain.{Item, ItemMembership, ItemVisibility}
  alias Spike.Repo

  @rank %{"read" => 1, "write" => 2, "admin" => 3}

  # items joined with :rank (highest permission, 1..3 or nil), :hidden, :public
  defp with_facts(actor_id) do
    memberships =
      if actor_id do
        from m in ItemMembership,
          where:
            m.account_id == ^actor_id and fragment("? @> ?", m.item_path, parent_as(:item).path),
          select: %{
            rank:
              max(
                fragment(
                  "CASE ?::text WHEN 'read' THEN 1 WHEN 'write' THEN 2 WHEN 'admin' THEN 3 END",
                  m.permission
                )
              )
          }
      else
        # Ecto forbids `== ^nil`: a signed-out visitor needs an explicit branch
        from m in ItemMembership, where: false, select: %{rank: max(1)}
      end

    visibilities =
      from v in ItemVisibility,
        where: fragment("? @> ?", v.item_path, parent_as(:item).path),
        select: %{
          hidden: coalesce(fragment("bool_or(?::text = 'hidden')", v.type), false),
          public: coalesce(fragment("bool_or(?::text = 'public')", v.type), false)
        }

    from i in Item,
      as: :item,
      where: is_nil(i.deleted_at),
      left_lateral_join: f in subquery(memberships),
      as: :facts,
      on: true,
      left_lateral_join: v in subquery(visibilities),
      as: :vis,
      on: true
  end

  # core's decision as SQL, same branches as the oracle
  defp access(required) do
    req = Map.fetch!(@rank, required)

    dynamic(
      [facts: f, vis: v],
      fragment(
        """
        CASE
          WHEN (? = 1 OR (? IS NULL AND ?)) AND ? THEN 'member_cannot_access'
          WHEN coalesce(?, 0) >= ? THEN 'ok'
          WHEN ? = 1 AND ? THEN 'ok'
          WHEN ? IS NULL THEN 'member_cannot_access'
          ELSE ?
        END
        """,
        f.rank,
        f.rank,
        v.public,
        v.hidden,
        f.rank,
        ^req,
        ^req,
        v.public,
        f.rank,
        ^"member_cannot_#{required}"
      )
    )
  end

  @doc "decision for many items, one query: %{id => decision}"
  def access_for(actor_id, ids, required) do
    from([item: i] in with_facts(actor_id),
      where: i.id in ^ids,
      select: ^%{id: dynamic([item: i], i.id), access: access(required)}
    )
    |> Repo.all()
    |> Map.new(&{&1.id, &1.access})
  end

  def get_item(actor_id, id, required \\ "read") do
    from([item: i] in with_facts(actor_id), where: i.id == ^id, select: ^%{item: dynamic([item: i], i), access: access(required)})
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      %{item: item, access: "ok"} -> {:ok, item}
      %{access: error} -> {:error, error}
    end
  end

  def children(actor_id, parent_id) do
    with {:ok, parent} <- get_item(actor_id, parent_id) do
      p = parent.path
      # struct params inside fragment need an explicit type

      from([item: i] in with_facts(actor_id),
        where: fragment(
            "? <@ ? and nlevel(?) = nlevel(?) + 1",
            i.path,
            type(^p, EctoLtree.LabelTree),
            i.path,
            type(^p, EctoLtree.LabelTree)
          ),
        where: ^dynamic(^access("read") == "ok"),
        order_by: [asc: i.order, asc: i.created_at],
        select: i.name
      )
      |> Repo.all()
      |> then(&{:ok, &1})
    end
  end

  def accessible(actor_id, min_permission) do
    from([item: i] in with_facts(actor_id),
      where: ^dynamic(^access(min_permission) == "ok"),
      select: i.name
    )
    |> Repo.all()
  end

  @doc "v3: narrowed to subtrees of the actor's memberships (write/admin)"
  def accessible_narrowed(actor_id, min_permission) do
    from([item: i] in with_facts(actor_id),
      where:
        fragment(
          "? <@ ANY(ARRAY(SELECT item_path FROM item_membership WHERE account_id = ?))",
          i.path,
          type(^actor_id, :binary_id)
        ),
      where: ^dynamic(^access(min_permission) == "ok"),
      select: i.name
    )
    |> Repo.all()
  end

  def query_for_explain(actor_id, ids, required) do
    from([item: i] in with_facts(actor_id),
      where: i.id in ^ids,
      select: ^%{id: dynamic([item: i], i.id), access: access(required)}
    )
  end
end
