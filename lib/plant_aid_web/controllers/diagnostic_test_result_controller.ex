defmodule PlantAidWeb.DiagnosticTestResultController do
  use PlantAidWeb, :controller

  alias PlantAid.DiagnosticTests

  def export_csv(conn, params) do
    user = conn.assigns.current_user

    with :ok <- Bodyguard.permit(DiagnosticTests, :export_test_results, user) do
      case DiagnosticTests.export_test_results(user, params) do
        {:ok, csv} ->
          send_download(conn, {:binary, csv},
            filename: "PlantAid Test Results #{Date.utc_today()}.csv",
            encode: false
          )

        {:error, _meta} ->
          put_flash(conn, :error, "Something went wrong")
      end
    end
  end
end
