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

  defp apply_action(socket, :index, %{"all" => "true"} = params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Observations, :list_observations, user) do
      case Observations.list_observations(params) do
        {:ok, {observations, meta}} ->
          assign(socket, %{
            page_title: "Listing Observations",
            params: params,
            observation: nil,
            observations: observations,
            user_observations: false,
            meta: meta
          })

        {:error, _meta} ->
          socket
      end
    else
      _ ->
        params = Map.delete(params, "all")

        socket
        |> put_flash(:error, "Unauthorized")
        |> push_patch(to: ~p"/observations?#{params}")
    end
  end

  defp apply_action(socket, :index, %{} = params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Observations, :list_user_observations, user) do
      case Observations.list_user_observations(user, params) do
        {:ok, {observations, meta}} ->
          assign(socket, %{
            page_title: "Listing Observations",
            params: params,
            observation: nil,
            observations: observations,
            user_observations: true,
            meta: meta
          })

        {:error, _meta} ->
          socket
      end
    end
  end

  @impl true
  def handle_info({:updated_filters, params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/observations?#{params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    observation = Observations.get_observation!(id)
    {:ok, _} = Observations.delete_observation(observation)
    {observations, meta} = Observations.list_observations(socket.assigns.meta.flop)

    {:noreply,
     assign(socket, %{
       observations: observations,
       meta: meta
     })}
  end

  @impl true
  def handle_event("show-all-observations", _, socket) do
    params = Map.put(socket.assigns.params, "all", "true")
    {:noreply, push_patch(socket, to: ~p"/observations?#{params}")}
  end

  @impl true
  def handle_event("show-user-observations", _, socket) do
    params = Map.delete(socket.assigns.params, "all")
    {:noreply, push_patch(socket, to: ~p"/observations?#{params}")}
  end
end
