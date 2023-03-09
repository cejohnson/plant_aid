defmodule PlantAidWeb.ObservationLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.{
    Hosts,
    LocationTypes,
    Observations,
    Pathologies
  }

  alias PlantAid.Observations.Observation

  @impl true
  def mount(_params, _session, socket) do
    hosts = Hosts.list_hosts()
    location_types = LocationTypes.list_location_types()

    host_options = Enum.map(hosts, fn h -> {h.common_name, h.id} end)
    location_type_options = Enum.map(location_types, fn lt -> {lt.name, lt.id} end)

    {:ok,
     socket
     |> assign(:host_options, [{"Select", nil} | host_options])
     |> assign(:location_type_options, [{"Select", nil} | location_type_options])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Observation")
    |> assign(:observation, Observations.get_observation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Observation")
    |> assign(:observation, %Observation{})
  end

  defp apply_action(socket, :index, params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      case Observations.paginate_observations(flop) do
        {observations, meta} ->
          assign(socket, %{
            page_title: "Listing Observations",
            observation: nil,
            observations: observations,
            meta: meta
          })

        error ->
          IO.inspect(error, label: "list observations error")
          socket
      end
    end

    # case Observations.list_observations(params) do
    #   {:ok, {observations, meta}} ->
    #     IO.inspect(meta, label: "meta")

    #     assign(socket, %{
    #       page_title: "Listing Observations",
    #       observation: nil,
    #       observations: observations,
    #       meta: meta
    #     })

    #   _ ->
    #     socket
    #     # push_navigate(socket, to: ~p"/observations")
    # end

    # socket
    # |> assign(:page_title, "Listing Observations")
    # |> assign(:observation, nil)
  end

  @impl true
  def handle_event("update-filter", %{"filter" => params}, socket) do
    IO.inspect(params, label: "update-filter")
    {:noreply, push_patch(socket, to: ~p"/observations?#{params}")}
  end

  @impl true
  def handle_event("reset-filter", _, %{assigns: assigns} = socket) do
    {:noreply, push_patch(socket, to: ~p"/observations")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    observation = Observations.get_observation!(id)
    {:ok, _} = Observations.delete_observation(observation)

    {:noreply, assign(socket, :observations, list_observations())}
  end

  defp list_observations do
    Observations.list_observations()
  end
end
