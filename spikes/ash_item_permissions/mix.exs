# PROTOTYPE — throwaway Ash spike for graasp-web#318. Never merge.
defmodule AshItemPermissions.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_item_permissions,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: false,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Spike.Application, []}]
  end

  defp deps do
    [
      {:ash, "== 3.37.4"},
      {:ash_postgres, "== 2.15.2"},
      # policies need a SAT solver (NIF)
      {:picosat_elixir, "~> 0.2"},
      # same ltree type admin uses, for the plain-Ecto side of the comparison
      {:ecto_ltree, "~> 0.3"}
    ]
  end
end
