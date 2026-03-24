defmodule AdminWeb.RestoreLocale do
  @moduledoc """
  A Plug for restoring the locale from the session so it works in live views
  """
  def on_mount(:default, _params, %{"locale" => locale}, socket) do
    socket = Phoenix.Component.assign_new(socket, :locale, fn -> locale end)

    socket =
      Phoenix.Component.assign_new(socket, :locale_form, fn ->
        Phoenix.Component.to_form(%{"locale" => locale})
      end)

    Gettext.put_locale(AdminWeb.Gettext, locale)
    {:cont, socket}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
