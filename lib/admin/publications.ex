defmodule Admin.Publications do
  @moduledoc """
  The Publications context.
  """

  import Ecto.Query, warn: false

  alias Admin.Accounts
  alias Admin.Accounts.Account
  alias Admin.Accounts.Scope
  alias Admin.Accounts.UserNotifier
  alias Admin.Items.Item
  alias Admin.Items.ItemMembership
  alias Admin.Publications.PublicationRemovalNotice
  alias Admin.Publications.PublishedItem
  alias Admin.Repo
  alias Ecto.Multi

  @doc """
  Subscribes to scoped notifications about any published_item changes.

  The broadcasted messages match the pattern:

    * {:created, %PublishedItem{}}
    * {:updated, %PublishedItem{}}
    * {:deleted, %PublishedItem{}}

  """
  def subscribe_published_items do
    Phoenix.PubSub.subscribe(Admin.PubSub, "published_items")
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Admin.PubSub, "published_items", message)
  end

  @doc """
  Returns the list of published_items.

  ## Examples

      iex> list_published_items()
      [%PublishedItem{}, ...]

  """
  def list_published_items do
    Repo.all(from p in PublishedItem, order_by: [desc: :created_at], preload: [:item, :creator])
    |> Enum.map(&populate_thumbnails(&1))
  end

  @doc """
  Returns the list of published items for all users
  """
  def list_published_items(limit) do
    Repo.all(
      from p in PublishedItem,
        order_by: [desc: :created_at],
        limit: ^limit,
        preload: [:item, :creator]
    )
    |> Enum.map(&populate_thumbnails(&1))
  end

  def list_featured_published_items do
    # Repo.all(from p in PublishedItem, where: p.featured == true, order_by: [desc: :created_at])
    []
  end

  @doc """
  Checks if a published item exists for the supplied id
  """
  def exists?(id) do
    Repo.exists?(from(p in PublishedItem, where: p.id == ^id))
  end

  @doc """
  Checks if a an item exists for the supplied id
  """
  def item_exists?(item_id) do
    Repo.exists?(from(item in Item, where: item.id == ^item_id))
  end

  @doc """
  Gets a single published_item.

  Raises `Ecto.NoResultsError` if the Published item does not exist.

  ## Examples

      iex> get_published_item!(scope, 123)
      %PublishedItem{}

      iex> get_published_item!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_published_item!(id) do
    Repo.get!(PublishedItem, id)
    |> with_creator()
    |> with_item()
  end

  def get_published_item!(%Scope{} = _scope, id) do
    Repo.get_by!(PublishedItem, id: id)
    |> with_creator()
    |> with_item()
  end

  def get_stats do
    last_30_days =
      from(p in PublishedItem, where: p.created_at >= date_add(^Date.utc_today(), -30, "day"))
      |> Repo.aggregate(:count, :id)

    previous_30_days =
      from(p in PublishedItem,
        where:
          p.created_at >= date_add(^Date.utc_today(), -60, "day") and
            p.created_at < date_add(^Date.utc_today(), -30, "day")
      )
      |> Repo.aggregate(:count, :id)

    %{
      total: Repo.aggregate(PublishedItem, :count, :id),
      day: %{
        current:
          from(p in PublishedItem, where: p.created_at >= date_add(^Date.utc_today(), -1, "day"))
          |> Repo.aggregate(:count, :id),
        prev:
          from(p in PublishedItem,
            where:
              p.created_at >= date_add(^Date.utc_today(), -2, "day") and
                p.created_at < date_add(^Date.utc_today(), -1, "day")
          )
          |> Repo.aggregate(:count, :id)
      },
      month: %{
        current: last_30_days,
        prev: previous_30_days
      }
    }
  end

  def get_publication_id_for_item_id(item_id) do
    query =
      from pi in PublishedItem,
        join: i in Item,
        on: pi.item_path == i.path,
        where: i.id == ^item_id,
        select: pi.id

    Repo.one(query)
  end

  def with_item(%PublishedItem{} = published_item) do
    published_item
    |> Repo.preload([:item])
    |> populate_thumbnails()
  end

  def with_creator(%PublishedItem{} = published_item) do
    published_item |> Repo.preload([:creator])
  end

  @doc """
  Creates a published_item.

  ## Examples

      iex> create_published_item(scope, %{field: value})
      {:ok, %PublishedItem{}}

      iex> create_published_item(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_published_item(%Scope{} = _scope, attrs) do
    with {:ok, published_item = %PublishedItem{}} <-
           %PublishedItem{}
           |> PublishedItem.changeset(attrs)
           |> Repo.insert() do
      broadcast({:created, published_item})
      {:ok, published_item}
    end
  end

  @doc """
  Deletes a published_item.

  ## Examples

      iex> delete_published_item(scope, published_item)
      {:ok, %PublishedItem{}}

      iex> delete_published_item(scope, published_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_published_item(%Scope{} = _scope, %PublishedItem{} = published_item) do
    with {:ok, published_item = %PublishedItem{}} <-
           Repo.delete(published_item) do
      broadcast({:deleted, published_item})
      {:ok, published_item}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking published_item changes.

  ## Examples

      iex> change_published_item(scope, published_item)
      %Ecto.Changeset{data: %PublishedItem{}}

  """
  def change_published_item(%Scope{} = _scope, %PublishedItem{} = published_item, attrs \\ %{}) do
    # true = published_item.creator_id == scope.user.id

    PublishedItem.changeset(published_item, attrs)
  end

  @doc """
  Returns an `Ecto.Changeset{}` for tracking removal_notice changes.
  """
  def create_removal_notice(%Scope{} = scope, %PublishedItem{} = published_item, attrs \\ %{}) do
    PublicationRemovalNotice.changeset(%PublicationRemovalNotice{}, attrs, published_item, scope)
  end

  @doc """
  Removes a publication. Deletes the publication and send a notification email to the user to inform them.
  """

  def remove_publication_with_notice(
        %Scope{} = scope,
        %PublishedItem{} = published_item,
        attrs \\ %{}
      ) do
    removal_notice = create_removal_notice(scope, published_item, attrs)
    multi = build_removal_multi(removal_notice, published_item)

    try do
      case Repo.transaction(multi) do
        {:ok, %{notice: notice} = _result} ->
          {:ok, :removed, notice}

        {:error, :notice, changeset, _changes_so_far} when is_map(changeset) ->
          {:error, changeset}

        {:error, :publication, changeset, _changes_so_far} when is_map(changeset) ->
          {:error, changeset}

        {:error, :send_notice, reason, %{notice: notice_changeset}} ->
          changeset =
            Ecto.Changeset.add_error(
              notice_changeset,
              :base,
              "Failed to send notification: #{inspect(reason)}"
            )

          {:error, changeset}

        {:error, _step, _value, %{notice: notice_changeset}} ->
          changeset =
            Ecto.Changeset.add_error(
              notice_changeset,
              :base,
              "An unknown error occurred"
            )

          {:error, changeset}
      end
    rescue
      e in Ecto.StaleEntryError ->
        changeset =
          removal_notice
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:base, "Stale entry error: #{Exception.message(e)}")

        {:error, changeset}
    end
  end

  defp build_removal_multi(removal_notice, published_item) do
    Multi.new()
    |> Ecto.Multi.insert(:notice, removal_notice)
    |> Ecto.Multi.delete(:publication, published_item)
    |> Ecto.Multi.run(:send_notice, fn _repo,
                                       %{
                                         notice: notice,
                                         publication: publication
                                       } ->
      # Get the creator or nil
      creator =
        case publication.creator_id do
          nil ->
            nil

          creator_id ->
            Admin.Repo.one(from a in Admin.Accounts.Account, where: a.id == ^creator_id)
        end

      case UserNotifier.deliver_publication_removal(creator, publication, notice) do
        {:ok, :not_sent} -> {:ok, :not_sent}
        {:ok, _response} -> {:ok, :sent}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp populate_thumbnails(%PublishedItem{item: %Item{id: item_id}} = pub) do
    thumbnails =
      Admin.ItemThumbnails.get_item_thumbnails(item_id)

    Map.put(pub, :thumbnails, thumbnails)
  end

  # item association is not loaded
  defp populate_thumbnails(%PublishedItem{} = pub) do
    Map.put(pub, :thumbnails, %{small: nil, medium: nil, large: nil})
  end

  def get_authors(%Item{} = item) do
    from(m in ItemMembership,
      join: a in Account,
      # has a membership on the parents of the item or the item itself
      on: m.account_id == a.id,
      where:
        fragment("? @> ?", m.item_path, ^(item.path |> EctoLtree.LabelTree.decode())) and
          m.permission in ["admin", "write"] and a.type == "individual",
      select: a
    )
    |> Repo.all()
    |> Enum.map(&Accounts.populate_avatar_url(&1))
  end
end
