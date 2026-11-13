defmodule Spike.Items do
  @moduledoc "PROTOTYPE Ash domain over core's existing tables (graasp-web#318)."
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource Spike.Items.Account
    resource Spike.Items.Item
    resource Spike.Items.ItemMembership
    resource Spike.Items.ItemVisibility
  end
end
