defmodule Admin.FolderExportsFixtures do
  @moduledoc """
  Test helpers for the Folder Exports.
  """
  import Mox

  alias Admin.Items.PathUtils

  @doc "Adds a `public` or `hidden` visibility on an item."
  def set_visibility(item, type) when type in [:public, :hidden] do
    Admin.Repo.query!(
      "INSERT INTO item_visibility (type, item_path) VALUES ($1::item_visibility_type, $2::ltree)",
      [Atom.to_string(type), PathUtils.to_string(item.path)]
    )

    item
  end

  @doc """
  Builds a tree of `{attrs, children}` (see `Admin.ItemsFixtures.build_tree/2`)
  whose root is a public folder, and returns the root item. Items have no
  description unless one is given.
  """
  def public_tree(scope, root_attrs \\ %{}, children) do
    [{root, _}] =
      Admin.ItemsFixtures.build_tree(scope, [
        {Map.merge(%{name: "Root", type: "folder"}, root_attrs) |> no_description(),
         Enum.map(children, &no_description_in_tree/1)}
      ])

    set_visibility(root, :public)
  end

  defp no_description(attrs), do: Map.put_new(attrs, :description, nil)

  defp no_description_in_tree({attrs, children}),
    do: {no_description(attrs), Enum.map(children, &no_description_in_tree/1)}

  @doc """
  Stubs the S3 client: reads are served from `objects` (`%{"key" => binary}`),
  uploads are sent to the test process as `{:uploaded, bucket, key, bytes}`.
  """
  def stub_s3(objects \\ %{}) do
    test_pid = self()

    stub(ExAwsMock, :request, fn
      %ExAws.S3.Upload{} = upload ->
        send(test_pid, {:uploaded, upload.bucket, upload.path, Enum.into(upload.src, <<>>)})
        {:ok, %{status_code: 200, body: ""}}

      %ExAws.Operation.S3{http_method: :get, path: path} ->
        case Map.fetch(objects, path) do
          {:ok, body} -> {:ok, %{status_code: 200, body: body}}
          :error -> {:error, {:http_error, 404, %{}}}
        end

      %ExAws.Operation.S3DeleteAllObjects{} = op ->
        send(test_pid, {:deleted, op.bucket, op.objects})
        {:ok, %{status_code: 200, body: ""}}
    end)
  end

  @doc "Unzips the bytes, as a map of `name => content` (directories end with `/`)."
  def unzip(bytes) do
    {:ok, files} = :zip.unzip(bytes, [:memory])
    {:ok, entries} = :zip.list_dir(bytes)

    dirs =
      for {:zip_file, name, info, _, _, _} <- entries,
          elem(info, 2) == :directory,
          into: %{},
          do: {to_string(name), nil}

    for({name, content} <- files, into: %{}, do: {to_string(name), content})
    |> Map.merge(dirs)
  end
end
