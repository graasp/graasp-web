defmodule Admin.Docs do
  @moduledoc """
  Module for publishing documentation pages.
  """

  alias Admin.Docs.Page

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:admin, "priv/docs/**/*.md"),
    as: :pages

  use Admin.Docs.Sections, path: "priv/docs/en"

  @pages Enum.sort_by(@pages, &(&1.order || 1000), :asc)

  def all_pages, do: @pages

  def all_ids,
    do: for_locale("en") |> Enum.map(& &1.id) |> Enum.uniq()

  def for_locale("en"), do: all_pages() |> Enum.filter(&(&1.locale == "en"))

  def for_locale(locale) do
    for_locale("en")
    |> Enum.map(fn page ->
      Enum.find(all_pages(), &(&1.id == page.id and &1.locale == locale)) || page
    end)
  end

  def for_locale_by_sections(locale) do
    all = for_locale(locale) |> Enum.group_by(& &1.section)
    {intro, rest} = Enum.split_with(all, fn {section_name, _} -> section_name == "intro" end)

    {developer, rest} =
      Enum.split_with(rest, fn {section_name, _} -> section_name == "developer" end)

    intro ++ rest ++ developer
  end

  def with_tag(tag, locale),
    do: for_locale(locale) |> Enum.filter(&(tag in &1.tags))

  def all_topics do
    all_pages() |> Enum.map(& &1.section) |> Enum.uniq()
  end

  def all_sections do
    all_pages()
    |> Enum.group_by(fn page -> page.section end)
  end

  def get_page_by_id!(id) do
    Enum.find(all_pages(), fn post -> post.id == id end) ||
      raise AdminWeb.NotFoundError, "page with id=#{id} not found"
  end
end
