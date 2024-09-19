# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :plant_aid,
  ecto_repos: [PlantAid.Repo]

config :plant_aid, PlantAid.Repo, types: PlantAid.PostgresTypes

# Configures the endpoint
config :plant_aid, PlantAidWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PlantAidWeb.ErrorHTML, json: PlantAidWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PlantAid.PubSub,
  live_view: [signing_salt: "8x/hdzVe"]

# Configures the job runner
config :plant_aid, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10],
  repo: PlantAid.Repo

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :plant_aid, PlantAid.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :error_tracker,
  repo: PlantAid.Repo,
  otp_app: :plant_aid

config :geo_postgis,
  json_library: Jason

config :flop, repo: PlantAid.Repo, default_limit: 25

config :flop_phoenix,
  pagination: [opts: {PlantAidWeb.Helpers, :pagination_opts}],
  table: [opts: {PlantAidWeb.Helpers, :table_opts}]

config :ex_aws,
  json_codec: Jason,
  http_client: PlantAid.ExAwsHttpClient

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
