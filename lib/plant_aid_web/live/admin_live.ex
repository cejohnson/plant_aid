defmodule PlantAidWeb.AdminLive do
  use PlantAidWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>Admin</.header>

      <ul>
        <li><.link navigate={~p"/admin/users"}>Users</.link></li>
        <li><.link navigate={~p"/admin/location_types"}>Location Types</.link></li>
        <li><.link navigate={~p"/admin/hosts"}>Hosts</.link></li>
        <li><.link navigate={~p"/admin/pathologies"}>Pathologies</.link></li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
