defmodule PlantAid.Workers.CreateAlerts do
  require Logger
  use Oban.Worker

  alias PlantAid.Alerts
  alias PlantAid.DiagnosticTests
  alias PlantAid.Observations

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"observation_id" => id}}) do
    Observations.get_observation!(id)
    |> create_alerts()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"diagnostic_test_result_id" => id}}) do
    DiagnosticTests.get_test_result!(id)
    |> create_alerts()
  end

  defp create_alerts(struct) do
    alert_subscriptions = Alerts.find_alert_subscriptions(struct)
    Alerts.create_alerts(struct, alert_subscriptions)
    :ok
  end
end
