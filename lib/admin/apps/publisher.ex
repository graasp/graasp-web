defmodule Admin.Apps.Publisher do
  @moduledoc """
  This module defines the Publisher struct which is used to represent an application publisher.
  This is an entity that that groups together apps. It is used for domain authorization of the apps.
  """
  use Admin.Schema
  import Ecto.Changeset
  alias Admin.Apps
  alias Admin.Validators

  schema "publishers" do
    field :name, :string
    field :origins, {:array, :string}, default: [""]

    has_many :apps, Apps.AppInstance, preload_order: [asc: :name]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(publisher, attrs) do
    publisher
    |> cast(attrs, [:name, :origins], empty_values: [[], nil] ++ Ecto.Changeset.empty_values())
    |> validate_required([:name, :origins])
    |> validate_length(:origins, min: 1)
    |> trim_array_values(:origins)
    |> Validators.validate_urls_array(:origins)
    |> unique_constraint(:name, name: "publisher_name_key")
  end

  defp trim_array_values(changeset, field) do
    case get_change(changeset, field, nil) do
      nil ->
        changeset

      _ ->
        update_change(changeset, field, &Enum.map(&1, fn origin -> origin |> String.trim() end))
    end
  end
end
