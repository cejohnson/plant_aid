defmodule PlantAidWeb.ObservationLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Observations
  alias PlantAid.Observations.Observation

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
    case Observations.list_observations(params) do
      {:ok, {observations, meta}} ->
        assign(socket, %{
          page_title: "Listing Observations",
          observation: nil,
          observations: observations,
          meta: meta
        })

      _ ->
        socket
        # push_navigate(socket, to: ~p"/observations")
    end

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
  def handle_event("delete", %{"id" => id}, socket) do
    observation = Observations.get_observation!(id)
    {:ok, _} = Observations.delete_observation(observation)

    {:noreply, assign(socket, :observations, list_observations())}
  end

  defp list_observations do
    Observations.list_observations()
  end
end
