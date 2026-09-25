defmodule Admin.Chatbot.Scope do
  @moduledoc """
  Who is using a chatbot item: the item, the verified account (from the app
  token, see `Admin.Apps.Token`) and whether they are the item's Teacher.

  A Teacher is a member with admin permission on the item, viewing it in the
  builder — mirroring the React app, where `App.tsx` routes the "builder"
  context to `BuilderView`, which only shows the teacher view for
  `PermissionLevel.Admin`. Everyone else (player context, or builder with
  write/read permission) is a student.
  """

  @enforce_keys [:item_id, :account_id]
  defstruct [:item_id, :account_id, teacher?: false]

  @type t :: %__MODULE__{item_id: String.t(), account_id: String.t(), teacher?: boolean()}

  @doc """
  Builds the scope from the verified ids and the local context the Graasp
  platform sent through the postMessage handshake (`"context"` is
  `"builder"`/`"player"`/..., `"permission"` is the member's permission).
  """
  @spec new(String.t(), String.t(), map()) :: t()
  def new(item_id, account_id, graasp_context) when is_map(graasp_context) do
    %__MODULE__{
      item_id: item_id,
      account_id: account_id,
      teacher?:
        Map.get(graasp_context, "context") == "builder" and
          Map.get(graasp_context, "permission") == "admin"
    }
  end
end
