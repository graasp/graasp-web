defmodule Admin.Accounts do
  @moduledoc """
  The Accounts context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias Admin.Accounts.Account
  alias Admin.ItemThumbnails
  alias Admin.Repo

  alias Admin.Accounts.{User, UserNotifier, UserToken}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Get a user with their notices associations
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    with {:ok, user = %User{}} <-
           %User{}
           |> User.email_changeset(attrs)
           |> Repo.insert() do
      broadcast_users({:created, user})
      {:ok, user}
    end
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Admin.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Admin.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def change_user_name(user, attrs \\ %{}) do
    User.name_changeset(user, attrs)
  end

  def update_user_name(user, attrs \\ %{}) do
    user
    |> User.name_changeset(attrs)
    |> Repo.update()
  end

  def change_user_language(user, attrs \\ %{}) do
    User.language_changeset(user, attrs)
  end

  def update_user_language(user, attrs \\ %{}) do
    user
    |> User.language_changeset(attrs)
    |> Repo.update()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_created_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  @doc """
  Returns all users
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Deletes a user by id
  """
  def delete_user_by_id(id) do
    with {1, [user | _]} <- Repo.delete_all(from(u in User, where: [id: ^id], select: u)) do
      broadcast_users({:deleted, user})
      Logger.info("broadcased the change for #{inspect(user)}")
      {:ok, user}
    end
  end

  @doc """
  Allows to subscribe to Messages sent via PubSub on the `users` topic

  The broadcasted messages match the patterns:
    * {:created, %User{}}
    * {:deleted, %User{}}
    * {:updated, %User{}}
  """
  def subscribe_users do
    Phoenix.PubSub.subscribe(Admin.PubSub, "users")
  end

  defp broadcast_users(message) do
    Phoenix.PubSub.broadcast(Admin.PubSub, "users", message)
  end

  ## Statistics

  @doc """
  Return the total number of users registered on the platform
  """
  def user_stats do
    %{
      total: Admin.Repo.aggregate(User, :count),
      confirmed: Admin.Repo.aggregate(from(u in User, where: not is_nil(u.confirmed_at)), :count)
    }
  end

  # Graasp Members

  def get_member!(id) do
    Repo.get!(Account, id)
  end

  def get_member_by_email(email) do
    case Repo.get_by(Account, email: email) do
      %Account{} = user -> {:ok, user}
      nil -> {:error, :member_not_found}
    end
  end

  @type audience :: %{
          id: Ecto.UUID.t(),
          name: String.t(),
          email: String.t(),
          lang: String.t(),
          marketing_emails_subscribed_at: DateTime.t()
        }

  @spec get_active_members() :: [audience]
  def get_active_members do
    Repo.all(
      from(m in Account,
        select: %{
          id: m.id,
          name: m.name,
          email: m.email,
          lang: fragment("?->>?", m.extra, "lang"),
          marketing_emails_subscribed_at: m.marketing_emails_subscribed_at
        },
        where:
          not is_nil(m.last_authenticated_at) and m.last_authenticated_at > ago(90, "day") and
            m.type == "individual"
      )
    )
  end

  @spec get_members_by_language(String.t()) :: [audience]
  def get_members_by_language(language) do
    Repo.all(
      from(m in Account,
        select: %{
          id: m.id,
          name: m.name,
          email: m.email,
          lang: fragment("?->>?", m.extra, "lang"),
          marketing_emails_subscribed_at: m.marketing_emails_subscribed_at
        },
        where: fragment("?->>? = ?", m.extra, "lang", ^language) and m.type == "individual"
      )
    )
  end

  def create_member(attrs \\ %{}) do
    %Account{}
    |> Account.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_member_marketing_emails(%Account{} = account, enable_emails) do
    account |> Account.marketing_emails_changeset(enable_emails) |> Repo.update()
  end

  def populate_avatar_url(%Account{} = account) do
    thumbnails = ItemThumbnails.avatar_thumbnails(account.id)
    %{account | thumbnails: thumbnails}
  end
end
