defmodule PlantAidWeb.ObservationLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Accounts.User
  alias PlantAid.Observations
  alias PlantAid.Observations.Sample

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    observation = Observations.get_observation!(id)

    with :ok <- Bodyguard.permit(Observations, :get_observation, user, observation) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:observation, observation)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> push_navigate(to: ~p"/")}
    end
  end

  defp page_title(:show), do: "Show Observation"
  defp page_title(:print), do: "Submit Sample"
  defp page_title(:add_sample), do: "Add Sample Results"
  defp page_title(:edit_sample), do: "Edit Sample Results"
end
