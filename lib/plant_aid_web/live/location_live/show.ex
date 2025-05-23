defmodule PlantAidWeb.LocationLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Locations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    location = Locations.get_location!(id)

    with :ok <- Bodyguard.permit(Locations, :get_location, user, location) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:location, location)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/locations")}
    end
  end

  defp page_title(:show), do: "Show Location"
  defp page_title(:edit), do: "Edit Location"
end
