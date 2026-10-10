defmodule AdminWeb.LandingController do
  use AdminWeb, :controller

  alias AdminWeb.Plugs.Locale

  def index(conn, _params) do
    render(conn, :index, page_title: pgettext("page title", "Home"))
  end

  def about(conn, _params) do
    render(conn, :about, page_title: pgettext("page title", "About"))
  end

  def contact(conn, _params) do
    render(conn, :contact, page_title: pgettext("page title", "Contact"))
  end

  def static_page(conn, _params) do
    page = conn.request_path |> Path.split() |> List.last()
    locale = conn.private.locale

    user_locale = conn.assigns.locale

    page_data =
      Admin.StaticPages.get_static_page!(locale, page)

    user_locale_page_exists = Admin.StaticPages.exists?(user_locale, page)

    if is_nil(page_data) do
      redirect(conn, to: AdminWeb.Marketing.get_path(page, "en"))
    else
      render(conn, :static_page,
        page_title: page_data.title,
        page: page_data,
        locale: locale,
        user_locale: user_locale,
        user_locale_page_exists: user_locale_page_exists
      )
    end
  end

  def locale(conn, _params) do
    session_locale = Locale.get_session_locale(conn)
    http_locale = Locale.get_http_locale(conn)

    render(conn, :locale,
      session_locale: session_locale,
      http_locale: http_locale
    )
  end

  def change_locale(conn, %{"locale" => locale}) do
    referrer = conn |> get_req_header("referer") |> List.first()

    conn
    |> Locale.set_locale(locale)
    |> redirect(to: local_path(referrer))
  end

  # keep only the path and query of the referer so we never redirect off-site,
  # browsers may also omit the header entirely
  defp local_path(referrer) when is_binary(referrer) do
    case URI.parse(referrer) do
      # "//" would be read as a protocol-relative url pointing to another host
      %URI{path: "//" <> _} -> ~p"/"
      %URI{path: "/" <> _ = path, query: query} -> with_query(path, query)
      _ -> ~p"/"
    end
  end

  defp local_path(_referrer), do: ~p"/"

  defp with_query(path, nil), do: path
  defp with_query(path, query), do: path <> "?" <> query

  def remove_locale(conn, _params) do
    conn
    |> Locale.set_locale(nil)
    |> redirect(to: ~p"/locale")
  end
end
