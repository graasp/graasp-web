defmodule AdminWeb.FolderExportLive.IndexTest do
  use AdminWeb.ConnCase

  import Admin.AccountsFixtures
  import Admin.FolderExportsFixtures
  import Mox
  import Phoenix.LiveViewTest

  alias Admin.FolderExports
  alias Admin.FolderExports.FolderExport
  alias Admin.Repo

  setup :verify_on_exit!
  setup :set_mox_global
  setup :register_and_log_in_user

  defp export_for(name) do
    folder = public_tree(user_scope_fixture(), %{name: name}, [])
    {:ok, export} = FolderExports.request_export(folder.id)
    export
  end

  defp set(export, changes), do: export |> Ecto.Changeset.change(changes) |> Repo.update!()

  test "lists the exports with their folder", %{conn: conn} do
    export = export_for("Alpha folder")

    {:ok, view, _html} = live(conn, ~p"/admin/folder-exports")

    assert has_element?(view, "#folder-exports-#{export.id}", "Alpha folder")
    assert has_element?(view, "#folder-exports-#{export.id} [data-role=status]", "pending")
  end

  test "shows the error of a failed export", %{conn: conn} do
    export = export_for("Broken") |> set(status: "failed", error: "boom")

    {:ok, view, _html} = live(conn, ~p"/admin/folder-exports")

    assert has_element?(view, "#folder-exports-#{export.id}", "boom")
  end

  test "filters by status", %{conn: conn} do
    pending = export_for("Pending one")
    failed = export_for("Failed one") |> set(status: "failed")

    {:ok, view, _html} = live(conn, ~p"/admin/folder-exports")

    view |> form("#status-filter", %{status: "failed"}) |> render_change()

    assert has_element?(view, "#folder-exports-#{failed.id}")
    refute has_element?(view, "#folder-exports-#{pending.id}")

    view |> form("#status-filter", %{status: ""}) |> render_change()

    assert has_element?(view, "#folder-exports-#{pending.id}")
  end

  test "updates a row when its export progresses", %{conn: conn} do
    export = export_for("Moving")

    {:ok, view, _html} = live(conn, ~p"/admin/folder-exports")
    FolderExports.mark_running(export)

    assert render(view) =~ "running"
    assert has_element?(view, "#folder-exports-#{export.id} [data-role=status]", "running")
  end

  test "runs the cleanup and reports the result", %{conn: conn} do
    stub_s3()
    expired = export_for("Old")
    past = DateTime.add(DateTime.utc_now(), -8 * 24 * 3600) |> DateTime.truncate(:second)
    set(expired, expires_at: past)
    recent = export_for("Recent")

    {:ok, view, _html} = live(conn, ~p"/admin/folder-exports")
    assert has_element?(view, "#folder-exports-#{expired.id}")

    view |> element("#run-cleanup") |> render_click()

    refute has_element?(view, "#folder-exports-#{expired.id}")
    assert has_element?(view, "#folder-exports-#{recent.id}")
    assert Repo.get(FolderExport, expired.id) == nil
    assert render(view) =~ "Cleanup done"
  end

  test "requires a logged in user" do
    conn = build_conn()
    assert {:error, {:redirect, _}} = live(conn, ~p"/admin/folder-exports")
  end
end
