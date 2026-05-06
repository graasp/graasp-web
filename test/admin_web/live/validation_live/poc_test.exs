defmodule AdminWeb.ValidationLive.PocTest do
  use AdminWeb.ConnCase

  import Mox
  import Phoenix.LiveViewTest
  import Admin.ItemsFixtures

  alias Admin.Items

  setup :register_and_log_in_user

  describe "mount" do
    test "renders skeleton loaders before files are fetched", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/validation")

      assert html =~ "animate-pulse"
    end

    test "replaces skeletons with files after connection", %{conn: conn, scope: scope} do
      file1 = file_item_fixture(scope, %{name: "test1.jpg"})
      file2 = file_item_fixture(scope, %{name: "test2.png"})

      {:ok, lv, _html} = live(conn, ~p"/admin/validation")

      html = render(lv)
      assert html =~ file1.name
      assert html =~ file2.name
      refute html =~ "animate-pulse"
    end
  end

  describe "delete-item" do
    setup :verify_on_exit!

    test "removes the item from the list", %{conn: conn, scope: scope} do
      stub(ExAwsMock, :request, fn _op -> {:ok, %{status_code: 200}} end)

      file = file_item_fixture(scope, %{name: "to_delete.jpg"})

      {:ok, lv, _html} = live(conn, ~p"/admin/validation")

      assert render(lv) =~ file.name

      lv
      |> render_click("delete-item", %{id: file.id})

      refute render(lv) =~ file.name
    end
  end

  describe "get_recent_files/0" do
    test "only returns items of type file", %{scope: scope} do
      file = file_item_fixture(scope, %{name: "image.jpg"})
      _other = item_fixture(scope, %{name: "a folder"})

      files = Items.get_recent_files()

      assert Enum.any?(files, &(&1.id == file.id))
      refute Enum.any?(files, &(&1.name == "a folder"))
    end

    test "returns at most 10 files", %{scope: scope} do
      Enum.each(1..12, fn i -> file_item_fixture(scope, %{name: "file#{i}.jpg"}) end)

      assert length(Items.get_recent_files()) == 10
    end

    test "populates thumbnails on each file", %{scope: scope} do
      file_item_fixture(scope)

      [file | _] = Items.get_recent_files()

      assert %{small: _, medium: _, large: _} = file.thumbnails
    end
  end
end
