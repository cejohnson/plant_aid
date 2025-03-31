defmodule PlantAid.Workers.CreateAlerts do
  require Logger
  use Oban.Worker

  alias PlantAid.Alerts
  alias PlantAid.DiagnosticTests
  alias PlantAid.Observations

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"observation_id" => id}}) do
    case Observations.get_observation(id) do
      {:ok, observation} ->
        create_alerts(observation)

      _ ->
        :ok
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"diagnostic_test_result_id" => id}}) do
    case DiagnosticTests.get_test_result(id) do
      {:ok, test_result} ->
        create_alerts(test_result)

      _ ->
        :ok
    end
  end

  defp create_alerts(struct) do
    alert_subscriptions = Alerts.find_alert_subscriptions(struct)
    Alerts.create_alerts(struct, alert_subscriptions)
    :ok
  end
end
