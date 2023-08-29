defmodule PlantAidWeb.LocationTypeLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.LocationTypes
  alias PlantAid.LocationTypes.LocationType

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(LocationTypes, :list_location_types, current_user) do
      {:ok, stream(socket, :location_types, LocationTypes.list_location_types())}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Location type")
    |> assign(:location_type, LocationTypes.get_location_type!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Location type")
    |> assign(:location_type, %LocationType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Location types")
    |> assign(:location_type, nil)
  end

  @impl true
  def handle_info({PlantAidWeb.LocationTypeLive.FormComponent, {:saved, location_type}}, socket) do
    {:noreply, stream_insert(socket, :location_types, location_type)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    location_type = LocationTypes.get_location_type!(id)

    with :ok <- Bodyguard.permit(LocationTypes, :delete_location_type, current_user) do
      {:ok, _} = LocationTypes.delete_location_type(location_type)

      {:noreply, stream_delete(socket, :location_types, location_type)}
    end
  end
end
