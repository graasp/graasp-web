defmodule Admin.FolderExportsTest do
  use Admin.DataCase
  use Oban.Testing, repo: Admin.Repo

  import Admin.AccountsFixtures
  import Admin.FolderExportsFixtures
  import Mox

  alias Admin.FolderExports
  alias Admin.FolderExports.FolderExport
  alias Admin.FolderExports.Worker

  setup :verify_on_exit!
  setup :set_mox_global

  setup do
    {:ok, scope: user_scope_fixture()}
  end

  defp file_attrs(name, key, extra \\ %{}) do
    %{
      name: name,
      type: "file",
      extra: %{"file" => Map.merge(%{"path" => key, "mimetype" => "text/plain"}, extra)}
    }
  end

  defp run_export(folder) do
    {:ok, export} = FolderExports.request_export(folder.id)
    assert :ok = perform_job(Worker, %{export_id: export.id})
    Repo.get!(FolderExport, export.id)
  end

  defp uploaded_zip do
    assert_received {:uploaded, "file-items", "public-exports/" <> _, bytes}
    unzip(bytes)
  end

  describe "request_export/1" do
    test "creates a pending export and enqueues the job", %{scope: scope} do
      folder = public_tree(scope, [])

      assert {:ok, export} = FolderExports.request_export(folder.id)
      assert export.status == "pending"
      assert export.item_id == folder.id
      assert_enqueued(worker: Worker, args: %{export_id: export.id}, queue: "exports")
    end

    test "expires in 24 hours", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)

      assert_in_delta DateTime.diff(export.expires_at, DateTime.utc_now()), 86_400, 5
    end

    test "is not found for a folder that is not public", %{scope: scope} do
      [{folder, _}] = Admin.ItemsFixtures.build_tree(scope, [{%{type: "folder"}, []}])
      assert {:error, :not_found} = FolderExports.request_export(folder.id)
    end

    test "is not found for something that is not a folder", %{scope: scope} do
      item =
        Admin.ItemsFixtures.item_fixture(scope, %{type: "document"}) |> set_visibility(:public)

      assert {:error, :not_found} = FolderExports.request_export(item.id)
    end

    test "is not found for a hidden folder", %{scope: scope} do
      folder = public_tree(scope, [])
      set_visibility(folder, :hidden)
      assert {:error, :not_found} = FolderExports.request_export(folder.id)
    end

    test "is not found for a recycled folder", %{scope: scope} do
      folder = public_tree(scope, [])
      Admin.RecycledItems.trash(%{item_path: folder.path, creator_id: folder.creator_id})
      assert {:error, :not_found} = FolderExports.request_export(folder.id)
    end

    test "is not found for an unknown or invalid id" do
      assert {:error, :not_found} = FolderExports.request_export(Ecto.UUID.generate())
      assert {:error, :not_found} = FolderExports.request_export("nope")
    end

    test "works on a subfolder of a public folder", %{scope: scope} do
      root = public_tree(scope, [{%{name: "Sub", type: "folder"}, []}])
      [sub] = Admin.Items.get_descendants(root.path) |> Enum.filter(&(&1.name == "Sub"))

      assert {:ok, export} = FolderExports.request_export(sub.id)
      assert export.item_id == sub.id
    end

    test "a hidden subfolder is not found", %{scope: scope} do
      root =
        public_tree(scope, [
          {%{name: "Sub", type: "folder"}, [{%{name: "Deep", type: "folder"}, []}]}
        ])

      [sub] = Admin.Items.get_descendants(root.path) |> Enum.filter(&(&1.name == "Sub"))
      [deep] = Admin.Items.get_descendants(root.path) |> Enum.filter(&(&1.name == "Deep"))
      set_visibility(sub, :hidden)

      assert {:error, :not_found} = FolderExports.request_export(sub.id)
      assert {:error, :not_found} = FolderExports.request_export(deep.id)
    end

    test "joins the export that is already in flight", %{scope: scope} do
      folder = public_tree(scope, [])

      {:ok, first} = FolderExports.request_export(folder.id)
      {:ok, second} = FolderExports.request_export(folder.id)

      assert first.id == second.id
      assert [_] = all_enqueued(worker: Worker)
    end

    test "joins a running export too", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, first} = FolderExports.request_export(folder.id)
      FolderExports.mark_running(first)

      assert {:ok, second} = FolderExports.request_export(folder.id)
      assert second.id == first.id
    end

    test "creates a new export once the previous one is over", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, first} = FolderExports.request_export(folder.id)
      FolderExports.mark_failed(first, "boom")

      assert {:ok, second} = FolderExports.request_export(folder.id)
      refute second.id == first.id
    end

    test "does not join an export that has not moved for hours", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, first} = FolderExports.request_export(folder.id)
      long_ago = DateTime.add(DateTime.utc_now(), -4 * 3600) |> DateTime.truncate(:second)
      Repo.update_all(FolderExport, set: [updated_at: long_ago])

      assert {:ok, second} = FolderExports.request_export(folder.id)
      refute second.id == first.id
      assert Repo.get!(FolderExport, first.id).status == "failed"
    end

    test "retry creates a new export for the same folder", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, first} = FolderExports.request_export(folder.id)
      failed = FolderExports.mark_failed(first, "boom")

      assert {:ok, second} = FolderExports.retry(failed)
      assert second.item_id == folder.id
      refute second.id == first.id
    end
  end

  describe "get_export/1" do
    test "returns the export with its folder", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)

      assert %FolderExport{id: id, item: %{id: item_id}} = FolderExports.get_export(export.id)
      assert id == export.id
      assert item_id == folder.id
    end

    test "returns nil when unknown" do
      assert FolderExports.get_export(Ecto.UUID.generate()) == nil
      assert FolderExports.get_export("nope") == nil
    end
  end

  describe "building a flat folder" do
    test "zips the original files", %{scope: scope} do
      folder =
        public_tree(scope, [
          {file_attrs("a.txt", "files/a"), []},
          {file_attrs("b.txt", "files/b"), []}
        ])

      stub_s3(%{"files/a" => "content of a", "files/b" => "content of b"})

      export = run_export(folder)

      assert export.status == "done"
      assert export.total_count == 2
      assert export.processed_count == 2
      assert export.s3_key == "public-exports/#{export.id}.zip"

      assert %{"Root/a.txt" => "content of a", "Root/b.txt" => "content of b"} = uploaded_zip()
    end

    test "gives the done export a download link valid 24 hours", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])
      stub_s3(%{"files/a" => "a"})

      export = run_export(folder) |> Repo.preload(:item)
      url = FolderExports.download_url(export)

      assert url =~ "public-exports/#{export.id}.zip"
      assert %{"X-Amz-Expires" => expires} = URI.parse(url).query |> URI.decode_query()
      assert_in_delta String.to_integer(expires), 86_400, 5
      assert_in_delta DateTime.diff(export.expires_at, DateTime.utc_now()), 86_400, 5
    end

    test "has no download link when it is not done or has expired", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)
      assert FolderExports.download_url(export) == nil

      done = %{export | status: "done", s3_key: "public-exports/x.zip"}
      assert FolderExports.download_url(done) =~ "public-exports/x.zip"

      past = DateTime.add(DateTime.utc_now(), -10)
      assert FolderExports.download_url(%{done | expires_at: past}) == nil
    end

    test "an empty folder is done without a zip", %{scope: scope} do
      folder = public_tree(scope, [])
      stub_s3()

      export = run_export(folder)

      assert export.status == "done"
      assert export.s3_key == nil
      assert export.total_count == 0
      refute_received {:uploaded, _, _, _}
    end

    test "fails when the upload fails", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])

      stub(ExAwsMock, :request, fn
        %ExAws.Operation.S3{http_method: :get} ->
          {:ok, %{status_code: 200, body: "a"}}

        %ExAws.S3.Upload{} = upload ->
          Enum.into(upload.src, <<>>)
          {:error, {:http_error, 500, %{}}}
      end)

      export = run_export(folder)

      assert export.status == "failed"
      assert export.error
      assert export.s3_key == nil
    end

    test "fails when a file can not be read", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])
      stub_s3(%{})

      assert run_export(folder).status == "failed"
    end

    test "fails when the folder stopped being public", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])
      stub_s3(%{"files/a" => "a"})
      {:ok, export} = FolderExports.request_export(folder.id)
      set_visibility(folder, :hidden)

      assert :ok = perform_job(Worker, %{export_id: export.id})
      assert Repo.get!(FolderExport, export.id).status == "failed"
    end

    test "does nothing for an export that is already over", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)
      FolderExports.mark_failed(export, "boom")

      assert :ok = perform_job(Worker, %{export_id: export.id})
      assert Repo.get!(FolderExport, export.id).status == "failed"
    end
  end

  describe "building a tree" do
    test "mirrors the folder structure with every item type", %{scope: scope} do
      folder =
        public_tree(scope, %{description: "<p>root description</p>"}, [
          {file_attrs("photo", "files/photo", %{"mimetype" => "image/jpeg"}), []},
          {%{
             name: "notes",
             type: "document",
             extra: %{"document" => %{"content" => "<p>hi</p>"}},
             description: "about notes"
           }, []},
          {%{
             name: "site",
             type: "embeddedLink",
             extra: %{"embeddedLink" => %{"url" => "https://graasp.org"}}
           }, []},
          {%{
             name: "quiz",
             type: "app",
             extra: %{"app" => %{"url" => "https://app.example/quiz"}}
           }, []},
          {%{
             name: "interactive",
             type: "h5p",
             extra: %{"h5p" => %{"h5pFilePath" => "abc/interactive.h5p"}}
           }, []},
          {%{name: "Sub", type: "folder"},
           [
             {file_attrs("deep.txt", "files/deep"), []},
             {%{name: "Nothing", type: "folder"}, []}
           ]}
        ])

      stub_s3(%{
        "files/photo" => "jpeg",
        "files/deep" => "deep",
        "h5p-content/abc/interactive.h5p" => "h5p"
      })

      export = run_export(folder)
      assert export.status == "done"
      # the 6 non-folder items
      assert export.total_count == 6

      assert %{
               "Root.description.html" => "<p>root description</p>",
               "Root/photo.jpeg" => "jpeg",
               "Root/notes.html" => "<p>hi</p>",
               "Root/notes.description.html" => "about notes",
               "Root/site.url" => "[InternetShortcut]\nURL=https://graasp.org\n",
               "Root/quiz.app" => "[InternetShortcut]\nURL=https://app.example/quiz\nAppURL=1\n",
               "Root/interactive.h5p" => "h5p",
               "Root/Sub/deep.txt" => "deep",
               "Root/Sub/Nothing/" => nil
             } = uploaded_zip()
    end

    test "keeps the extension of the name when it has one", %{scope: scope} do
      folder =
        public_tree(scope, [
          {file_attrs("report.pdf", "files/r", %{"mimetype" => "application/pdf"}), []}
        ])

      stub_s3(%{"files/r" => "pdf"})

      run_export(folder)
      assert %{"Root/report.pdf" => "pdf"} = uploaded_zip()
    end

    test "leaves out hidden, recycled and shortcut items", %{scope: scope} do
      folder =
        public_tree(scope, [
          {file_attrs("kept.txt", "files/kept"), []},
          {file_attrs("hidden.txt", "files/hidden"), []},
          {file_attrs("recycled.txt", "files/recycled"), []},
          {%{
             name: "shortcut",
             type: "shortcut",
             extra: %{"shortcut" => %{"target" => Ecto.UUID.generate()}}
           }, []},
          {%{name: "Hidden folder", type: "folder"},
           [{file_attrs("child.txt", "files/child"), []}]},
          {%{name: "Recycled folder", type: "folder"},
           [{file_attrs("child2.txt", "files/child2"), []}]}
        ])

      descendants = Admin.Items.get_descendants(folder.path)
      by_name = Map.new(descendants, &{&1.name, &1})
      set_visibility(by_name["hidden.txt"], :hidden)
      set_visibility(by_name["Hidden folder"], :hidden)

      for name <- ["recycled.txt", "Recycled folder"] do
        item = by_name[name]
        Admin.RecycledItems.trash(%{item_path: item.path, creator_id: item.creator_id})
      end

      stub_s3(%{"files/kept" => "kept"})

      export = run_export(folder)
      assert export.status == "done"
      assert export.total_count == 1
      assert uploaded_zip() == %{"Root/kept.txt" => "kept"}
    end

    test "replaces etherpad items with a note", %{scope: scope} do
      folder =
        public_tree(scope, [
          {file_attrs("a.txt", "files/a"), []},
          {%{name: "Pad", type: "etherpad", extra: %{"etherpad" => %{}}}, []}
        ])

      stub_s3(%{"files/a" => "a"})
      run_export(folder)

      zip = uploaded_zip()
      assert zip["Root/a.txt"] == "a"
      assert zip["Root/Pad.skipped.txt"] =~ "Pad"
    end

    test "exports a subfolder on its own", %{scope: scope} do
      root =
        public_tree(scope, [
          {file_attrs("top.txt", "files/top"), []},
          {%{name: "Sub", type: "folder"}, [{file_attrs("in.txt", "files/in"), []}]}
        ])

      [sub] = Admin.Items.get_descendants(root.path) |> Enum.filter(&(&1.name == "Sub"))
      stub_s3(%{"files/in" => "in"})

      run_export(sub)
      assert uploaded_zip() == %{"Sub/in.txt" => "in"}
    end

    test "item names can not escape the archive", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("../../evil.txt", "files/e"), []}])
      stub_s3(%{"files/e" => "e"})

      run_export(folder)
      assert uploaded_zip() == %{"Root/.._.._evil.txt" => "e"}
    end
  end

  describe "progress" do
    test "is broadcast to subscribers", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])
      stub_s3(%{"files/a" => "a"})
      {:ok, export} = FolderExports.request_export(folder.id)
      FolderExports.subscribe(export.id)

      assert :ok = perform_job(Worker, %{export_id: export.id})

      assert_received {:folder_export_updated, %FolderExport{status: "running"}}
      assert_received {:folder_export_updated, %FolderExport{status: "running", total_count: 1}}
      assert_received {:folder_export_updated, %FolderExport{status: "done", processed_count: 1}}
    end

    test "is throttled to once per second", %{scope: scope} do
      children = for i <- 1..20, do: {file_attrs("f#{i}.txt", "files/f#{i}"), []}
      folder = public_tree(scope, children)
      stub_s3(Map.new(1..20, &{"files/f#{&1}", "x"}))
      {:ok, export} = FolderExports.request_export(folder.id)
      FolderExports.subscribe(export.id)

      assert :ok = perform_job(Worker, %{export_id: export.id})

      # running, total, at most a couple of progress updates, and the last flush + done
      {:messages, messages} = Process.info(self(), :messages)

      progress =
        for {:folder_export_updated, %{status: "running", total_count: 20}} = m <- messages, do: m

      assert length(progress) <= 3
    end

    test "is persisted, so a reload shows the current state", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)

      export
      |> FolderExports.mark_running()
      |> FolderExports.set_total(10)
      |> FolderExports.update_progress(4)

      assert %FolderExport{status: "running", total_count: 10, processed_count: 4} =
               FolderExports.get_export(export.id)
    end
  end

  describe "delete_expired/0" do
    defp expire(export, seconds_ago) do
      past = DateTime.add(DateTime.utc_now(), -seconds_ago) |> DateTime.truncate(:second)
      export |> Ecto.Changeset.change(expires_at: past) |> Repo.update!()
    end

    test "deletes the zip of an expired export and keeps the row for a while", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])
      stub_s3(%{"files/a" => "a"})
      export = run_export(folder) |> expire(60)

      assert %{objects: 1} = FolderExports.delete_expired()

      assert_received {:deleted, "file-items", ["public-exports/" <> _]}
      assert %FolderExport{s3_key: nil} = Repo.get!(FolderExport, export.id)
    end

    test "deletes the rows that expired long ago", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)
      expire(export, 8 * 24 * 3600)

      assert %{rows: 1} = FolderExports.delete_expired()
      assert Repo.get(FolderExport, export.id) == nil
    end

    test "leaves exports that did not expire", %{scope: scope} do
      folder = public_tree(scope, [{file_attrs("a.txt", "files/a"), []}])
      stub_s3(%{"files/a" => "a"})
      export = run_export(folder)

      assert %{objects: 0, rows: 0} = FolderExports.delete_expired()
      refute_received {:deleted, _, _}
      assert %FolderExport{s3_key: key} = Repo.get!(FolderExport, export.id)
      assert key
    end

    test "fails an unfinished export that expired", %{scope: scope} do
      folder = public_tree(scope, [])
      {:ok, export} = FolderExports.request_export(folder.id)
      expire(export, 60)

      FolderExports.delete_expired()
      assert Repo.get!(FolderExport, export.id).status == "failed"
    end

    test "the cleanup job runs it" do
      assert :ok = perform_job(Admin.FolderExports.CleanupWorker, %{})
    end
  end
end
