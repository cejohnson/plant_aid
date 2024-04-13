defmodule PlantAidWeb.LocationLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Locations
  alias PlantAid.Locations.Location

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Locations, :list_locations, user) do
      {:ok, stream(socket, :locations, Locations.list_locations(user))}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = socket.assigns.current_user
    location = Locations.get_location!(id)

    with :ok <- Bodyguard.permit(Locations, :update_location, user, location) do
      socket
      |> assign(:page_title, "Edit Location")
      |> assign(:location, location)
    end
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Locations, :update_location, user) do
      socket
      |> assign(:page_title, "New Location")
      |> assign(:location, %Location{})
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Locations")
    |> assign(:location, nil)
  end

  @impl true
  def handle_info({PlantAidWeb.LocationLive.FormComponent, {:saved, location}}, socket) do
    {:noreply, stream_insert(socket, :locations, location)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    location = Locations.get_location!(id)
    {:ok, _} = Locations.delete_location(location)

    {:noreply, stream_delete(socket, :locations, location)}
  end
end
