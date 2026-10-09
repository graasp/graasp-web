defmodule Admin.FolderExports.PlanEntry do
  @moduledoc """
  An entry of the zip, as planned by `Admin.FolderExports.Plan`.

  `data` is `:dir`, a binary or `{:s3, bucket, key}`. `item?` tells whether the
  entry is an item that counts for the progress (a description file or a
  directory does not).
  """
  defstruct [:path, :data, item?: false]

  @type t :: %__MODULE__{}
end
