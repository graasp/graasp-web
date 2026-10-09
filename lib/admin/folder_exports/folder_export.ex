defmodule Admin.FolderExports.FolderExport do
  @moduledoc """
  A zip export of a Public Folder, requested by a Visitor.
  """
  use Admin.Schema

  @type t :: %__MODULE__{}

  schema "folder_exports" do
    field :status, :string, default: "pending"
    field :processed_count, :integer, default: 0
    field :total_count, :integer
    field :s3_key, :string
    field :error, :string
    field :expires_at, :utc_datetime

    belongs_to :item, Admin.Items.Item

    timestamps(type: :utc_datetime)
  end

  @doc "An export is expired once its 24 hours are over."
  def expired?(%__MODULE__{expires_at: expires_at}, now \\ DateTime.utc_now()) do
    DateTime.compare(expires_at, now) != :gt
  end
end
