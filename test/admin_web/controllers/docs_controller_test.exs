defmodule AdminWeb.DocsControllerTest do
  use AdminWeb.ConnCase, async: true

  test "get documentation page", %{conn: conn} do
    conn = get(conn, ~p"/docs")
    assert html_response(conn, 200) =~ "Documentation"
  end

  test "search documentation with tag", %{conn: conn} do
    conn = get(conn, ~p"/docs/?tag=builder")
    assert html_response(conn, 200) =~ "Getting Started"
  end

  test "get getting started page", %{conn: conn} do
    conn = get(conn, ~p"/docs/getting-started")
    assert html_response(conn, 200) =~ "Getting Started"
  end

  test "get doc page that does not exist", %{conn: conn} do
    assert_raise AdminWeb.NotFoundError, fn ->
      get(conn, ~p"/docs/does-not-exist")
    end
  end
end
