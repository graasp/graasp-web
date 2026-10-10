defmodule Admin.SentryFilterTest do
  use ExUnit.Case, async: true

  alias Admin.SentryFilter

  defp event_for(exception), do: Sentry.Event.transform_exception(exception, [])

  test "drops exceptions rendered as 404" do
    event = event_for(%AdminWeb.NotFoundError{message: "page with id=missing not found"})

    assert SentryFilter.before_send(event) == nil
  end

  test "keeps other client errors" do
    event = event_for(%Plug.CSRFProtection.InvalidCSRFTokenError{})

    assert SentryFilter.before_send(event) == event
  end

  test "keeps server errors" do
    event = event_for(%RuntimeError{message: "boom"})

    assert SentryFilter.before_send(event) == event
  end

  test "keeps events without an exception" do
    event = Sentry.Event.create_event(message: "hello")

    assert SentryFilter.before_send(event) == event
  end
end
