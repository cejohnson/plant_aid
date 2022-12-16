defmodule PlantAidWeb.HostLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Hosts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:host, Hosts.get_host!(id))}
  end

  defp page_title(:show), do: "Show Host"
  defp page_title(:edit), do: "Edit Host"
end
