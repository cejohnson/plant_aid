defmodule PlantAidWeb.ObservationController do
  use PlantAidWeb, :controller

  alias PlantAid.Observations

  def export_csv(conn, params) do
    user = conn.assigns.current_user

    with :ok <- Bodyguard.permit(Observations, :export_observations, user) do
      case Observations.export_observations(user, params) do
        {:ok, csv} ->
          send_download(conn, {:binary, csv},
            filename: "PlantAid Observations #{Date.utc_today()}.csv",
            encode: false
          )

        {:error, _meta} ->
          put_flash(conn, :error, "Something went wrong")
      end
    end
  end
end
