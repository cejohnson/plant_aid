defmodule PlantAidWeb.LocationTypeLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.LocationTypes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:location_type, LocationTypes.get_location_type!(id))}
  end

  defp page_title(:show), do: "Show Location type"
  defp page_title(:edit), do: "Edit Location type"
end
