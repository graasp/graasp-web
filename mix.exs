defmodule Admin.MixProject do
  use Mix.Project

  def project do
    [
      app: :admin,
      version: "0.10.6",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      test_coverage: [
        tool: ExCoveralls,
        ignore_modules: [
          Admin.Release,
          AdminWeb.Dev,
          AdminWeb.DevLive,
          AdminWeb.AnalyticsLive,
          AdminWeb.Analytics
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Admin.Application, []},
      extra_applications: [:logger, :runtime_tools, :wx, :observer]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      # Mox is a mocking library for Elixir
      {:mox, "~> 1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.0"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},

      # sentry ependencies
      {:sentry, "~> 12.0"},

      # OpenTelemetry core packages
      {:opentelemetry, "~> 1.5"},
      {:opentelemetry_api, "~> 1.4"},
      {:opentelemetry_exporter, "~> 1.0"},
      {:opentelemetry_semantic_conventions, "~> 1.27"},
      # for Phoenix
      {:opentelemetry_phoenix, "~> 2.0"},
      # for Bandit (Phoenix 1.7+)
      {:opentelemetry_bandit, "~> 0.1"},
      # for Ecto
      {:opentelemetry_ecto, "~> 1.2"},

      # other dependencies
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:excoveralls, "~> 0.18", only: :test},
      # sanitize HTML in descriptions
      {:html_sanitize_ex, "~> 1.4"},
      # credo is a static analysis tool similar to eslint in TS
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # dialixir is a static analysis tool that can detect common bugs and code smells
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      # AWS services
      {:ex_aws, "~> 2.6"},
      {:ex_aws_s3, "~> 2.5"},
      {:poison, "~> 6.0"},
      {:hackney, "~> 1.9"},
      # optional dependency to parse XML
      {:sweet_xml, "~> 0.7"},
      # for parsing HTML in tests
      {:floki, "~> 0.38", only: [:dev, :test]},
      # jobs with Oban
      {:oban, "~> 2.19"},
      {:oban_web, "~> 2.11"},

      # html templating for emails
      {:mjml, "~> 5.0"},

      # VegaLite is a JavaScript library for creating interactive visualizations
      {:vega_lite, "~> 0.1.11"},

      # publish documentation via markdown
      {:nimble_publisher, "~> 1.0"},
      {:yaml_elixir, "~> 2.12"},

      # time formatting library
      {:timex, "~> 3.0"},

      # allow to use the ltree type with ecto
      {:ecto_ltree, "~> 0.3.0"},

      # allow to see ecto metrics in live dashboard
      {:ecto_psql_extras, "~> 0.6"},

      # thumbnail generation
      {:image, "~> 0.54"},

      # dependencies for the yolo model (nudenet)
      {:yolo, github: "spaenleh/yolo_elixir", branch: "main"},
      {:ortex, "~> 0.1.10"},
      {:nx, "~> 0.9"},
      {:exla, "~> 0.10"},
      {:evision, "~> 0.2"},
      {:kino, "~> 0.16"},
      {:kino_yolo, github: "poeticoding/kino_yolo", branch: "main"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind admin", "esbuild admin"],
      "assets.deploy": [
        "tailwind admin --minify",
        "esbuild admin --minify",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"],
      # checking code quality
      "check.format": ["format --check-formatted"],
      "check.credo": ["credo --strict"],
      "check.compile": ["compile --warning-as-errors"],
      "check.translations": ["gettext.extract --check-up-to-date"],
      check: ["check.compile", "format", "check.credo", "check.translations"],
      # handling translations
      i18n: [
        # 1. extract translation strings from code
        "gettext.extract",
        # 2. update application translations
        "gettext.merge priv/gettext",
        # 3. update email template translations
        "gettext.merge priv/gettext_email_templates"
      ]
    ]
  end
end
