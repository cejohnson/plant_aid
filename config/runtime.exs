import Config
require Logger

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/plant_aid start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :plant_aid, PlantAidWeb.Endpoint, server: true
end

config :plant_aid,
  registration_enabled: String.to_existing_atom(System.get_env("REGISTRATION_ENABLED") || "false")

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :plant_aid, PlantAid.Repo,
    ssl: true,
    ssl_opts: [
      verify: :verify_none
      # cacerts: :public_key.cacerts_get()
    ],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2"),
    socket_options: maybe_ipv6

  # prepare: :unnamed  # required if using PgBouncer

  # Libcluster
  service_name =
    System.get_env("LIBCLUSTER_SERVICE_NAME")

  if service_name do
    config :libcluster,
      topologies: [
        plantaid: [
          strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
          config: [
            service: service_name,
            application_name: "plant_aid"
          ]
        ]
      ]
  else
    Logger.warn(
      "Environment variable LIBCLUSTER_SERVICE_NAME is missing, running without libcluster"
    )
  end

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "plant-aid.org"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :plant_aid, PlantAidWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Object storage
  raise_object_storage_config_error = fn variable ->
    raise """
    environment variable #{variable} is missing.
    Make sure all OBJECT_STORAGE environment variables are present in the environment
    """
  end

  config :plant_aid, PlantAid.ObjectStorage,
    domain:
      System.get_env("OBJECT_STORAGE_DOMAIN") ||
        raise_object_storage_config_error.("OBJECT_STORAGE_DOMAIN"),
    region:
      System.get_env("OBJECT_STORAGE_REGION") ||
        raise_object_storage_config_error.("OBJECT_STORAGE_REGION"),
    bucket:
      System.get_env("OBJECT_STORAGE_BUCKET") ||
        raise_object_storage_config_error.("OBJECT_STORAGE_BUCKET"),
    access_key_id:
      System.get_env("OBJECT_STORAGE_ACCESS_KEY_ID") ||
        raise_object_storage_config_error.("OBJECT_STORAGE_ACCESS_KEY_ID"),
    secret_access_key:
      System.get_env("OBJECT_STORAGE_SECRET_ACCESS_KEY") ||
        raise_object_storage_config_error.("OBJECT_STORAGE_SECRET_ACCESS_KEY")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :plant_aid, PlantAidWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :plant_aid, PlantAidWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :plant_aid, PlantAid.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
  config :plant_aid, PlantAid.Mailer,
    adapter: Swoosh.Adapters.Brevo,
    api_key: System.get_env("EMAIL_BREVO_API_KEY")
end
