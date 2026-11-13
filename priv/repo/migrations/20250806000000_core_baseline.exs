defmodule Admin.Repo.Migrations.CoreBaseline do
  @moduledoc """
  Creates core's schema on an empty database (ADR 0002: admin owns the schema).

  The schema is `priv/repo/baseline/core_schema.sql`, cut from a production dump
  by `scripts/generate_core_baseline.sh`. Its version is older than every other
  migration so it runs first on a fresh database: Ecto runs pending migrations in
  version order, older ones included.

  It looks at the database before doing anything:

    * core's drizzle migrations reached 0020: the schema is already there (this
      is production), do nothing;
    * no table besides `schema_migrations`: create the schema;
    * anything else: raise, nothing safe can be done automatically.
  """
  use Ecto.Migration

  # `when` of drizzle migration 0020_remove-extra-item-login in core's
  # meta/_journal.json, stored as `created_at` in drizzle.__drizzle_migrations.
  # Production is at 0020; 0021 is applied by an admin migration.
  @drizzle_0020_created_at 1_768_915_972_957

  def up do
    case database_state() do
      :migrated_by_core -> :ok
      :empty -> Enum.each(statements(), &execute/1)
      :unknown -> raise unknown_state_message()
    end
  end

  def down do
    raise Ecto.MigrationError,
          "the core baseline cannot be rolled back, drop and recreate the database instead"
  end

  defp database_state do
    cond do
      drizzle_reached_0020?() -> :migrated_by_core
      user_tables() == [] -> :empty
      true -> :unknown
    end
  end

  defp drizzle_reached_0020? do
    %{rows: [[exists?]]} =
      repo().query!("SELECT to_regclass('drizzle.__drizzle_migrations') IS NOT NULL", [],
        log: false
      )

    exists? and
      match?(
        %{rows: [[true]]},
        repo().query!(
          "SELECT coalesce(max(created_at) >= $1, false) FROM drizzle.__drizzle_migrations",
          [@drizzle_0020_created_at],
          log: false
        )
      )
  end

  defp user_tables do
    %{rows: rows} =
      repo().query!(
        """
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public' AND tablename <> 'schema_migrations'
        ORDER BY tablename
        """,
        [],
        log: false
      )

    List.flatten(rows)
  end

  defp unknown_state_message do
    """
    The core baseline found tables in this database (#{Enum.join(user_tables(), ", ")}) \
    but no record of core's drizzle migrations reaching 0020.

    - Database built by an older core: migrate it with the last core release that \
    still runs drizzle migrations, then run the admin migrations again.
    - Local database built by admin's migrations before the baseline existed: \
    recreate it with `mix ecto.reset` (`MIX_ENV=test mix ecto.reset` for the test \
    database).
    """
  end

  # The file is pg_dump output. Postgrex prepares each query, which accepts a single
  # statement, so it is split here: a statement ends with a line ending in `;`
  # outside a dollar-quoted function body.
  defp statements do
    :admin
    |> Application.app_dir("priv/repo/baseline/core_schema.sql")
    |> File.read!()
    |> String.split("\n")
    |> Enum.reduce({[], [], nil}, &collect_line/2)
    |> then(fn {statements, [], nil} -> Enum.reverse(statements) end)
  end

  # blank and comment lines between statements
  defp collect_line(line, {statements, [], nil} = acc) do
    if String.trim(line) == "" or String.starts_with?(line, "--"),
      do: acc,
      else: collect_statement_line(line, {statements, [], nil})
  end

  defp collect_line(line, acc), do: collect_statement_line(line, acc)

  defp collect_statement_line(line, {statements, current, dollar_tag}) do
    current = [line | current]
    dollar_tag = toggle_dollar_quotes(line, dollar_tag)

    if is_nil(dollar_tag) and String.ends_with?(line, ";") do
      statement = current |> Enum.reverse() |> Enum.join("\n") |> String.trim()
      {[statement | statements], [], nil}
    else
      {statements, current, dollar_tag}
    end
  end

  defp toggle_dollar_quotes(line, dollar_tag) do
    ~r/\$[A-Za-z_]*\$/
    |> Regex.scan(line)
    |> List.flatten()
    |> Enum.reduce(dollar_tag, fn
      tag, nil -> tag
      tag, tag -> nil
      _other, open -> open
    end)
  end
end
