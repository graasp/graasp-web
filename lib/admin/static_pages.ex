defmodule Admin.StaticPages do
  @moduledoc """
  Module for managing static pages.
  """

  alias Admin.StaticPages.Page
  alias AdminWeb.NotFoundError

  use NimblePublisher,
    build: Page,
    from: Application.app_dir(:admin, "priv/pages/**/*.md"),
    as: :pages

  def all_pages, do: @pages

  def get_unique_page_ids do
    all_pages() |> Enum.map(& &1.id) |> Enum.uniq()
  end

  def get_static_page!(locale, id) when is_binary(id) do
    page = all_pages() |> Enum.find(&(&1.id == id && &1.locale == locale))

    if is_nil(page) and locale == AdminWeb.Gettext.default_locale(),
      do: raise(NotFoundError, message: "Page not found")

    page
  end

  def exists?(locale, id) when is_binary(id) do
    all_pages() |> Enum.any?(&(&1.id == id && &1.locale == locale))
  end
end
