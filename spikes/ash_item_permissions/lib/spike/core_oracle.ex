defmodule Spike.CoreOracle do
  @moduledoc """
  PROTOTYPE: line-by-line port of core's `AuthorizedItemService.getPropertiesForItem`
  and `_filterOutItems`, with core's naive queries (one per item). Used as the
  reference both other implementations must match.
  """
  alias Spike.Repo

  @rank %{"read" => 1, "write" => 2, "admin" => 3}

  def decide(actor_id, path, permission) do
    highest =
      if actor_id do
        Repo.query!(
          "select permission::text from item_membership where account_id = $1 and item_path @> $2::ltree",
          [Ecto.UUID.dump!(actor_id), path]
        ).rows
        |> Enum.map(&hd/1)
        |> Enum.max_by(&@rank[&1], fn -> nil end)
      end

    visibilities =
      Repo.query!("select type::text from item_visibility where item_path @> $1::ltree", [path]).rows
      |> Enum.map(&hd/1)

    valid? = highest != nil and @rank[highest] >= @rank[permission]

    public? =
      if highest == "read" or permission == "read", do: "public" in visibilities, else: false

    cond do
      (highest == "read" or (public? and highest == nil)) and "hidden" in visibilities ->
        "member_cannot_access"

      valid? ->
        "ok"

      permission == "read" and public? ->
        "ok"

      highest == nil ->
        "member_cannot_access"

      true ->
        "member_cannot_#{permission}"
    end
  end

  @doc "core's getChildren: assert read on parent, then drop hidden children unless write+"
  def children(actor_id, parent_path) do
    case decide(actor_id, parent_path, "read") do
      "ok" ->
        Repo.query!(
          """
          select name, path::text from item
          where path <@ $1::ltree and nlevel(path) = nlevel($1::ltree) + 1 and deleted_at is null
          order by "order" asc, created_at asc
          """,
          [parent_path]
        ).rows
        |> Enum.filter(fn [_name, path] ->
          highest =
            if actor_id do
              Repo.query!(
                "select permission::text from item_membership where account_id = $1 and item_path @> $2::ltree",
                [Ecto.UUID.dump!(actor_id), path]
              ).rows
              |> Enum.map(&hd/1)
              |> Enum.max_by(&@rank[&1], fn -> nil end)
            end

          hidden? =
            Repo.query!(
              "select 1 from item_visibility where type = 'hidden' and item_path @> $1::ltree",
              [path]
            ).num_rows > 0

          (highest != nil and @rank[highest] >= 2) or not hidden?
        end)
        |> Enum.map(&hd/1)
        |> then(&{:ok, &1})

      error ->
        {:error, error}
    end
  end
end
