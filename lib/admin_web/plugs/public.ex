defmodule AdminWeb.Public do
  @moduledoc """
  A Plug for managing public sessions
  """

  def session(conn, opts) do
    locale = Keyword.get(opts, :locale, "en")
    %{"locale" => conn.assigns.locale || locale}
  end
end
