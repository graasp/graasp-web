defmodule AdminWeb.BlogControllerTest do
  use AdminWeb.ConnCase, async: true

  test "get blog page", %{conn: conn} do
    conn = get(conn, ~p"/blog")
    assert html_response(conn, 200) =~ "Recent Posts"
  end

  test "get getting started page", %{conn: conn} do
    conn = get(conn, ~p"/blog/2026-03-10-update")
    assert html_response(conn, 200) =~ "March 10th, Fixes and improvements"
  end

  test "get blog page that does not exist", %{conn: conn} do
    assert_raise AdminWeb.NotFoundError, fn ->
      get(conn, ~p"/blog/does-not-exist")
    end
  end
end
