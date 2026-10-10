defmodule AdminWeb.LocaleTest do
  use AdminWeb.ConnCase, async: true

  test "request with german locale serves page in German", %{conn: conn} do
    conn = conn |> put_req_header("accept-language", "de-DE,de;q=0.9") |> get(~p"/")
    assert html_response(conn, 200) =~ "lang=\"de\""
  end

  test "set locale", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "/")
      |> post(~p"/locale", %{"locale" => "de"})

    assert redirected_to(conn) == ~p"/"

    # get the home page with the updated conn to check the lang has been updated
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "lang=\"de\""
  end

  test "set locale with undefined referer", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "/other")
      |> post(~p"/locale", %{"locale" => "de"})

    assert redirected_to(conn) == "/other"
  end

  test "set locale without referer redirects to home", %{conn: conn} do
    conn = post(conn, ~p"/locale", %{"locale" => "de"})

    assert redirected_to(conn) == ~p"/"
  end

  test "set locale keeps only path and query of an absolute referer", %{conn: conn} do
    conn =
      conn
      |> put_req_header("referer", "https://evil.example/about-us?tab=team")
      |> post(~p"/locale", %{"locale" => "de"})

    assert redirected_to(conn) == "/about-us?tab=team"
  end

  test "get locale page", %{conn: conn} do
    conn = get(conn, ~p"/locale")
    assert html_response(conn, 200) =~ "lang=\"en\""
  end

  test "remove current locale", %{conn: conn} do
    conn = delete(conn, ~p"/locale")
    assert redirected_to(conn) == ~p"/locale"
  end
end
