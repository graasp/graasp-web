defmodule Admin.Chatbot.Settings.StarterSuggestion do
  @moduledoc """
  One Starter Suggestion row of `Admin.Chatbot.Settings`. Stored as a plain
  string in the `"chatbot-prompt"` app_setting; embedded here only so the
  teacher's form can add/remove rows through `inputs_for`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :value, :string
  end

  @doc false
  def changeset(suggestion, attrs) do
    cast(suggestion, attrs, [:value])
  end
end
