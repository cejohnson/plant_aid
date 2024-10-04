defmodule PlantAid.Workers.NotifyReporter do
  require Logger
  use Oban.Worker

  use Phoenix.VerifiedRoutes,
    endpoint: PlantAidWeb.Endpoint,
    router: PlantAidWeb.Router,
    statics: PlantAidWeb.static_paths()

  alias PlantAid.DiagnosticTests
  alias PlantAid.Accounts.UserNotifier

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"diagnostic_test_result_id" => id, "event" => event}}) do
    test_result = DiagnosticTests.get_test_result!(id)
    reporter = test_result.observation.user

    # Don't send if the result was created/updated by the reporter (updated_by == created_by for new test results)
    if test_result.updated_by != reporter do
      observation_url = url(~p"/observations/#{test_result.observation.id}")
      test_result_url = url(~p"/test_results/#{test_result.id}")

      UserNotifier.deliver_test_result(reporter, event, observation_url, test_result_url)
    end

    :ok
  end
end
