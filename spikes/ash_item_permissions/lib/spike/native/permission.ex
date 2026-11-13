defmodule Spike.Native.Permission do
  @moduledoc "PROTOTYPE: core's native `permission_enum`, declared read < write < admin in Postgres."
  use Ash.Type.Enum, values: [:read, :write, :admin]

  def storage_type, do: :permission_enum
end
