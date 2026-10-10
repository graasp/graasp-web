defmodule Admin.DeveloperDocsTest do
  use ExUnit.Case, async: true

  alias Admin.DeveloperDocs

  test "page ids are unique" do
    ids = Enum.map(DeveloperDocs.all_pages(), & &1.id)

    assert ids -- Enum.uniq(ids) == []
  end

  test "only .md files are published, so no .mdx page is left behind" do
    assert Path.wildcard("priv/developer_docs/**/*.mdx") == []
  end

  test "relative links point to existing pages" do
    ids = MapSet.new(DeveloperDocs.all_pages(), & &1.id)

    broken =
      for page <- DeveloperDocs.all_pages(),
          [_, href] <- Regex.scan(~r/href="([^"]+)"/, page.body),
          not String.match?(href, ~r/^([a-z]+:|\/|#)/),
          target =
            href |> String.split("#") |> hd() |> String.trim_leading("./") |> String.downcase(),
          not MapSet.member?(ids, target) do
        {page.id, href}
      end

    assert broken == []
  end
end
