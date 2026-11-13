defmodule Spike.Native.AncestorOrSelf do
  @moduledoc """
  PROTOTYPE: ltree `@>` as a first-class Ash expression, `ancestor_or_self(ancestor, descendant)`,
  so resources never spell out the fragment.
  """
  use Ash.CustomExpression,
    name: :ancestor_or_self,
    arguments: [[AshPostgres.Ltree, AshPostgres.Ltree]]

  def expression(AshPostgres.DataLayer, [ancestor, descendant]) do
    {:ok, expr(fragment("? @> ?", ^ancestor, ^descendant))}
  end

  def expression(_data_layer, _args), do: :unknown
end
