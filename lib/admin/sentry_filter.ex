defmodule Admin.SentryFilter do
  @moduledoc """
  Sentry filter configuration for the Admin application.

  In this module we define sentry hooks that allow to filter events based on their data.
  """

  @doc """
  Drops events for exceptions rendered as a 404 (missing pages, bots probing urls),
  they are expected and only add noise to Sentry.
  """
  def before_send(%Sentry.Event{original_exception: exception} = event)
      when is_exception(exception) do
    if Plug.Exception.status(exception) == 404, do: nil, else: event
  end

  def before_send(event), do: event
end
