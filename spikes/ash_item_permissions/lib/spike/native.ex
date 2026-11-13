defmodule Spike.Native do
  @moduledoc """
  PROTOTYPE: "Ash all the way" for item permissions (graasp-web#318, round 2).
  Same tables, no rank calculation, no error-kind calculation.
  """
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Spike.Native.Item
    resource Spike.Native.Membership
    resource Spike.Native.Visibility
  end
end
