defmodule PlantAidWeb.SampleController do
  use PlantAidWeb, :controller

  alias PlantAid.Observations

  def print(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    observation = Observations.get_observation!(id)

    with :ok <- Bodyguard.permit(Observations, :get_observation, current_user, observation) do
      url = url(~p"/observations/#{id}")

      {:ok, qr_code} =
        url |> QRCode.create(:low) |> QRCode.render(:svg, %QRCode.Render.SvgSettings{scale: 5})

      render(conn, :print,
        layout: false,
        page_title: "Sample Information",
        observation: observation,
        qr_code: qr_code
      )
    end
  end
end
