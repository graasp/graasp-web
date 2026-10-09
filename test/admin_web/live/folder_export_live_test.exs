defmodule AdminWeb.FolderExportLiveTest do
  use AdminWeb.ConnCase

  import Admin.AccountsFixtures
  import Admin.FolderExportsFixtures
  import Phoenix.LiveViewTest

  alias Admin.FolderExports
  alias Admin.FolderExports.FolderExport
  alias Admin.Repo

  setup do
    scope = user_scope_fixture()
    folder = public_tree(scope, %{name: "My folder"}, [])
    {:ok, export} = FolderExports.request_export(folder.id)
    %{folder: folder, export: export}
  end

  describe "request route" do
    test "redirects a Visitor to the progress page", %{conn: conn, folder: folder} do
      conn = get(conn, ~p"/public/folders/#{folder.id}/export")

      assert %FolderExport{id: id} = FolderExports.get_in_flight(folder.id)
      assert redirected_to(conn) == ~p"/export/#{id}"
    end

    test "joins the export in flight", %{conn: conn, folder: folder, export: export} do
      conn = get(conn, ~p"/public/folders/#{folder.id}/export")
      assert redirected_to(conn) == ~p"/export/#{export.id}"
    end

    test "is a 404 for a folder that is not public", %{conn: conn} do
      scope = user_scope_fixture()
      [{private, _}] = Admin.ItemsFixtures.build_tree(scope, [{%{type: "folder"}, []}])

      conn = get(conn, ~p"/public/folders/#{private.id}/export")
      assert html_response(conn, 404)
    end

    test "is a 404 for a hidden folder", %{conn: conn, folder: folder} do
      set_visibility(folder, :hidden)
      assert get(conn, ~p"/public/folders/#{folder.id}/export") |> html_response(404)
    end

    test "is a 404 for a missing folder", %{conn: conn} do
      assert get(conn, ~p"/public/folders/#{Ecto.UUID.generate()}/export") |> html_response(404)
    end
  end

  describe "progress page" do
    test "shows a pending export", %{conn: conn, export: export} do
      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      assert has_element?(view, "#export-pending")
    end

    test "is a 404 for an unknown export", %{conn: conn} do
      assert_error_sent 404, fn -> live(conn, ~p"/export/#{Ecto.UUID.generate()}") end
      assert_error_sent 404, fn -> live(conn, ~p"/export/nope") end
    end

    test "shows the progress of a running export and follows its updates", %{
      conn: conn,
      export: export
    } do
      export |> FolderExports.mark_running() |> FolderExports.set_total(10)

      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      assert has_element?(view, "#export-running")
      assert has_element?(view, "#export-progress[value='0']")

      FolderExports.get_export(export.id) |> FolderExports.update_progress(5)

      assert render(view) =~ "5 of 10"
      assert has_element?(view, "#export-progress[value='50']")
    end

    test "shows the current progress after a reload", %{conn: conn, export: export} do
      export
      |> FolderExports.mark_running()
      |> FolderExports.set_total(10)
      |> FolderExports.update_progress(7)

      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      assert has_element?(view, "#export-progress[value='70']")
    end

    test "shows the download link once the export is done", %{conn: conn, export: export} do
      export = FolderExports.mark_running(export)
      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      refute has_element?(view, "#export-download-link")

      FolderExports.set_total(export, 1)
      |> FolderExports.mark_done("public-exports/#{export.id}.zip")

      assert has_element?(view, "#export-done")
      assert has_element?(view, "#export-download-link[href*='public-exports/#{export.id}.zip']")
    end

    test "tells the folder is empty", %{conn: conn, export: export} do
      export |> FolderExports.set_total(0) |> FolderExports.mark_done(nil)

      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      assert has_element?(view, "#export-empty")
      refute has_element?(view, "#export-download-link")
    end

    test "shows the error of a failed export and retries with a new export", %{
      conn: conn,
      export: export,
      folder: folder
    } do
      FolderExports.mark_failed(export, "boom")

      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      assert has_element?(view, "#export-failed")

      view |> element("#export-retry") |> render_click()

      %FolderExport{id: new_id} = FolderExports.get_in_flight(folder.id)
      refute new_id == export.id
      assert_redirect(view, ~p"/export/#{new_id}")
    end

    test "shows an expired export as expired", %{conn: conn, export: export} do
      done =
        export |> FolderExports.set_total(1) |> FolderExports.mark_done("public-exports/x.zip")

      past = DateTime.add(DateTime.utc_now(), -60) |> DateTime.truncate(:second)
      done |> Ecto.Changeset.change(expires_at: past) |> Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/export/#{export.id}")
      assert has_element?(view, "#export-expired")
      refute has_element?(view, "#export-download-link")
    end
  end
end
