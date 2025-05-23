defmodule PlantAid.MixProject do
  use Mix.Project

  def project do
    [
      app: :plant_aid,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PlantAid.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
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
      # Phoenix defaults
      {:argon2_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18"},
      {:heroicons, "~> 0.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.5"},
      # General additional dependencies
      {:bodyguard, "~> 2.4"},
      {:ecto_psql_extras, "~> 0.6"},
      {:error_tracker, "~> 0.2"},
      {:libcluster, "~> 3.3"},
      {:oban, "~> 2.17"},
      {:tz, "~> 0.28"},
      {:tz_extra, "~> 0.45"},
      {:kday, "~> 1.1"},
      # Specific project dependencies
      {:geo_postgis, "~> 3.4"},
      {:nimble_csv, "~> 1.2"},
      {:flop, "~> 0.25.0"},
      {:flop_phoenix, "~> 0.22.9"},
      {:qr_code, "~> 3.0.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"}
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
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup", "run priv/repo/seeds/users.exs"],
      "ecto.import": [&import_data/1],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end

  defp import_data(path) do
    IO.inspect(path, label: "Importing data from")

    Mix.Task.run(
      :run,
      ["scripts/import/usa_blight_import.exs", Path.join(path, "usa_blight")]
    )

    Mix.Task.run(
      :run,
      ["scripts/import/npdn_import.exs", Path.join(path, "NPDNLBDataDump")]
    )

    Mix.Task.run(
      :run,
      ["scripts/import/cucurbit_import.exs", Path.join(path, "cucurbit_downy_mildew")]
    )
  end
end
