defmodule PlantAidWeb.ObservationLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Mapping
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

  defp apply_action(socket, :index, %{"view" => "map"} = params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Mapping, :list_observations, user) do
      case Mapping.list_observations(user, params) do
        {:ok, {data, meta}} ->
          push_event(
            assign(socket, %{
              page_title: "Mapping Observations",
              params: params,
              view: :map,
              observation: nil,
              meta: meta
            }),
            "map-data",
            data
          )

        {:error, _meta} ->
          socket
          |> put_flash(:error, "Something went wrong")
      end
    end
  end

  defp apply_action(socket, :index, params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Observations, :list_observations, user) do
      case Observations.list_observations(user, params) do
        {:ok, {observations, meta}} ->
          assign(socket, %{
            page_title: "Listing Observations",
            params: params,
            view: :list,
            observation: nil,
            observations: observations,
            meta: meta
          })

        {:error, _meta} ->
          socket
          |> put_flash(:error, "Something went wrong")
      end
    end
  end

  @impl true
  def handle_info({:updated_filters, params}, socket) do
    params = Map.put(params, :view, socket.assigns.view)
    {:noreply, push_patch(socket, to: ~p"/observations?#{params}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    observation = Observations.get_observation!(id)

    with :ok <-
           Bodyguard.permit(
             Observations,
             :delete_observation,
             user,
             observation
           ) do
      {:ok, _} = Observations.delete_observation(observation)
      {observations, meta} = Observations.list_observations(user, socket.assigns.meta.flop)

      {:noreply,
       assign(socket, %{
         observations: observations,
         meta: meta
       })}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
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
