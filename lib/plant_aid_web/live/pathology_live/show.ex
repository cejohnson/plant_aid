defmodule PlantAidWeb.PathologyLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Pathologies

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:pathology, Pathologies.get_pathology!(id))}
  end

  defp page_title(:show), do: "Show Pathology"
  defp page_title(:edit), do: "Edit Pathology"
end
