defmodule Admin.Accounts.Account do
  @moduledoc """
  This represents a graasp user.
  """
  use Admin.Schema
  import Ecto.Changeset

  schema "account" do
    field :name, :string
    field :email, :string
    field :type, :string
    field :extra, :map
    field :last_authenticated_at, :utc_datetime
    field :marketing_emails_subscribed_at, :utc_datetime
    field :thumbnails, :map, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :email, :type, :extra])
    |> validate_required([:name, :email, :type])
    |> validate_name()
    |> validate_email()
    |> validate_type()
    |> validate_change(:extra, fn _, value -> validate_lang(value) end)
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, min: 3, max: 60)
  end

  @doc false
  def create_changeset(account, attrs) do
    account
    |> changeset(attrs)
    |> put_change(:marketing_emails_subscribed_at, DateTime.utc_now(:second))
  end

  def marketing_emails_changeset(account, true) do
    account
    |> change(%{
      marketing_emails_subscribed_at: DateTime.utc_now(:second)
    })
    |> validate_required([:marketing_emails_subscribed_at])
  end

  def marketing_emails_changeset(account, false) do
    account
    |> change(%{
      marketing_emails_subscribed_at: nil
    })
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
  end

  defp validate_type(changeset) do
    changeset
    |> validate_inclusion(:type, ["individual", "guest"])
  end

  # Validates `lang` only if present; permits nil or empty maps.
  defp validate_lang(map) when is_map(map) and map == %{}, do: []

  defp validate_lang(map) when is_map(map) do
    case Map.fetch(map, "lang") do
      :error ->
        []

      {:ok, lang} when is_binary(lang) and lang != "" ->
        []

      {:ok, _} ->
        [extra: {"must be a non-empty string", []}]
    end
  end
end
