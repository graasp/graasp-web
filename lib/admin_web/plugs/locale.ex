defmodule AdminWeb.Plugs.Locale do
  @moduledoc """
  Module for handling locale-related functionality.
  """

  import Plug.Conn
  alias AdminWeb.Plugs.Locale.Headers

  def init(default), do: default

  def call(conn, _) do
    locale =
      get_session_locale(conn) || get_http_locale(conn) ||
        Application.get_env(:gettext, :default_locale)

    Gettext.put_locale(locale)

    conn
    # |> put_session(:locale, locale)
    |> assign(:locale, locale)
    |> assign(:locale_form, Phoenix.Component.to_form(%{"locale" => locale}))
  end

  def set_locale(conn, locale) do
    conn
    |> put_session(:locale, locale)
  end

  def get_session_locale(conn) do
    conn |> get_session(:locale)
  end

  def get_http_locale(conn) do
    conn
    |> Headers.extract_accept_language()
    |> Enum.find(nil, fn locale -> Headers.supported_locale?(locale) end)
  end
end

defmodule AdminWeb.Plugs.Locale.Headers do
  @moduledoc """
  Provides parsing of Accept-Language headers for locale assignment
  """
  # Manage Accept-Language header parsing
  def extract_accept_language(conn) do
    case Plug.Conn.get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        # order by descending quality
        |> Enum.sort(&(&1.quality > &2.quality))
        # keep only the locale part
        |> Enum.map(& &1.tag)
        |> Enum.reject(&is_nil/1)
        |> ensure_language_fallbacks()

      _ ->
        []
    end
  end

  defp parse_language_option(string) do
    captures = Regex.named_captures(~r/^\s?(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i, string)

    quality =
      case Float.parse(captures["quality"] || "1.0") do
        {val, _} -> val
        _ -> 1.0
      end

    %{tag: captures["tag"], quality: quality}
  end

  defp ensure_language_fallbacks(tags) do
    Enum.flat_map(tags, fn tag ->
      [language | _] = String.split(tag, "-")
      if Enum.member?(tags, language), do: [tag], else: [tag, language]
    end)
  end

  def supported_locale?(locale),
    do: Enum.member?(AdminWeb.Localization.supported_locales(), locale)
end
