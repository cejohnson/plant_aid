defmodule PlantAidWeb.PathologyLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Pathologies
  alias PlantAid.Pathologies.Pathology

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Pathologies, :list_pathologies, current_user) do
      {:ok, stream(socket, :pathologies, Pathologies.list_pathologies())}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pathology")
    |> assign(:pathology, Pathologies.get_pathology!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pathology")
    |> assign(:pathology, %Pathology{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Pathologies")
    |> assign(:pathology, nil)
  end

  @impl true
  def handle_info({PlantAidWeb.PathologyLive.FormComponent, {:saved, pathology}}, socket) do
    {:noreply, stream_insert(socket, :pathologies, pathology)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    pathology = Pathologies.get_pathology!(id)

    with :ok <- Bodyguard.permit(Pathologies, :delete_pathology, current_user) do
      {:ok, _} = Pathologies.delete_pathology(pathology)

      {:noreply, stream_delete(socket, :pathologies, pathology)}
    end
  end
end
