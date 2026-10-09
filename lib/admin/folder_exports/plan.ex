defmodule Admin.FolderExports.Plan do
  @moduledoc """
  Turns the visible items of a folder into the entries of the zip.

  The layout matches the Node backend's raw export (`itemExport.service.ts`
  and `utils.ts`):

    * folders become directories, empty ones are kept as empty directories
    * files are the original binaries, H5P items the `.h5p` package
    * documents are `<name>.html`
    * embedded links are `<name>.url`, apps `<name>.app` (internet shortcut files)
    * a description is saved next to the item as `<name>.description.html`

  Differences with Node: etherpad items are replaced by a note, names are
  sanitized so that they cannot escape the archive, and a file without any
  extension keeps its name as is.
  """
  alias Admin.Items.Item

  @description_extension ".description.html"

  defmodule Entry do
    @moduledoc false
    # `data` is `:dir`, a binary or `{:s3, bucket, key}`.
    # `item?` tells whether the entry is an item that counts for the progress
    # (a description file or a directory does not).
    defstruct [:path, :data, item?: false]
  end

  @type entry :: %Entry{}

  @doc """
  Builds the entries for a visible tree (as returned by
  `Admin.FolderExports.Visibility.list_visible_tree/1`), root first.
  """
  @spec build([Item.t()], keyword()) :: [entry()]
  def build([root | _] = items, opts \\ []) do
    by_parent = Enum.group_by(items, &parent_labels/1)
    opts = Keyword.merge(default_opts(), opts)
    item_entries(root, "", by_parent, opts)
  end

  @doc "The number of items to process, used for the progress."
  @spec count_items([entry()]) :: non_neg_integer()
  def count_items(entries), do: Enum.count(entries, & &1.item?)

  defp default_opts do
    [
      file_bucket: Admin.ItemFiles.bucket(),
      h5p_bucket: Application.get_env(:admin, :h5p_bucket, "h5p-items")
    ]
  end

  defp item_entries(%Item{type: "folder"} = folder, dir, by_parent, opts) do
    path = join(dir, sanitize(folder.name))
    children = Map.get(by_parent, folder.path.labels, [])

    child_entries =
      case children do
        [] -> [%Entry{path: path, data: :dir}]
        _ -> Enum.flat_map(children, &item_entries(&1, path, by_parent, opts))
      end

    description_entries(folder, dir) ++ child_entries
  end

  defp item_entries(%Item{} = item, dir, _by_parent, opts) do
    description_entries(item, dir) ++ leaf_entries(item, dir, opts)
  end

  defp leaf_entries(%Item{type: "file"} = item, dir, opts) do
    case get_in(item.extra, ["file", "path"]) || get_in(item.extra, ["file", "key"]) do
      nil -> []
      key -> [item_entry(dir, file_name(item), {:s3, opts[:file_bucket], key})]
    end
  end

  defp leaf_entries(%Item{type: "h5p"} = item, dir, opts) do
    case get_in(item.extra, ["h5p", "h5pFilePath"]) do
      nil ->
        []

      file_path ->
        [
          item_entry(
            dir,
            with_extension(item.name, "h5p"),
            {:s3, opts[:h5p_bucket], "h5p-content/" <> file_path}
          )
        ]
    end
  end

  defp leaf_entries(%Item{type: "document"} = item, dir, _opts) do
    content = get_in(item.extra, ["document", "content"]) || ""
    [item_entry(dir, with_extension(item.name, "html"), content)]
  end

  defp leaf_entries(%Item{type: "embeddedLink"} = item, dir, _opts) do
    url = get_in(item.extra, ["embeddedLink", "url"]) || ""
    [item_entry(dir, with_extension(item.name, "url"), "[InternetShortcut]\nURL=#{url}\n")]
  end

  defp leaf_entries(%Item{type: "app"} = item, dir, _opts) do
    url = get_in(item.extra, ["app", "url"]) || ""

    [
      item_entry(
        dir,
        with_extension(item.name, "app"),
        "[InternetShortcut]\nURL=#{url}\nAppURL=1\n"
      )
    ]
  end

  defp leaf_entries(%Item{type: "etherpad"} = item, dir, _opts) do
    note =
      "The etherpad \"#{item.name}\" is not included in this export, " <>
        "etherpad items cannot be exported yet.\n"

    [item_entry(dir, with_extension(item.name, "skipped.txt"), note)]
  end

  # unknown types have nothing to export
  defp leaf_entries(_item, _dir, _opts), do: []

  defp description_entries(%Item{description: description} = item, dir)
       when is_binary(description) and description != "" do
    [%Entry{path: join(dir, sanitize(item.name) <> @description_extension), data: description}]
  end

  defp description_entries(_item, _dir), do: []

  defp item_entry(dir, name, data), do: %Entry{path: join(dir, name), data: data, item?: true}

  defp parent_labels(%Item{path: %{labels: labels}}), do: Enum.drop(labels, -1)

  defp file_name(%Item{} = item) do
    name = sanitize(item.name)

    case Path.extname(name) |> String.trim_leading(".") do
      "" ->
        mimetype = get_in(item.extra, ["file", "mimetype"])

        case mimetype && extension_for(mimetype) do
          ext when is_binary(ext) -> with_extension(name, ext)
          _ -> name
        end

      ext ->
        with_extension(name, ext)
    end
  end

  # the extension Node's `mime` package picks for a mimetype
  defp extension_for("image/jpeg"), do: "jpeg"

  defp extension_for(mimetype) do
    case MIME.extensions(mimetype) do
      [ext | _] -> ext
      [] -> nil
    end
  end

  # `Path.basename(name, ".ext") <> ".ext"`: the extension is not doubled
  defp with_extension(name, ext) do
    name = sanitize(name)
    dot_ext = "." <> ext
    Path.basename(name, dot_ext) <> dot_ext
  end

  defp join("", name), do: name
  defp join(dir, name), do: dir <> "/" <> name

  # an item name must stay a single path segment inside the archive
  defp sanitize(name) do
    name
    |> String.replace(["/", "\\", <<0>>], "_")
    |> case do
      n when n in ["", ".", ".."] -> "_"
      n -> n
    end
  end
end
