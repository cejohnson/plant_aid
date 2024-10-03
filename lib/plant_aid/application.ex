defmodule PlantAid.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Oban.Telemetry.attach_default_logger()

    children = [
      # Start the Telemetry supervisor
      PlantAidWeb.Telemetry,
      # Start the Ecto repository
      PlantAid.Repo,
      # Start Oban
      {Oban, Application.fetch_env!(:plant_aid, Oban)},
      # Start the PubSub system
      {Phoenix.PubSub, name: PlantAid.PubSub},
      PlantAid.ConnectionMonitor,
      # Start Finch
      {Finch, name: PlantAid.Finch},
      {Task.Supervisor, name: PlantAid.TaskSupervisor},
      # Start the Endpoint (http/https)
      PlantAidWeb.Endpoint
      # TODO: add tz/tzextra updater once this issue is resolved
      # https://github.com/mathieuprog/tz/issues/32
      # Start a worker by calling: PlantAid.Worker.start_link(arg)
      # {PlantAid.Worker, arg}
    ]

    topologies = Application.get_env(:libcluster, :topologies)

    children =
      if topologies do
        # Start libcluster
        [{Cluster.Supervisor, [topologies]} | children]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PlantAid.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PlantAidWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
