defmodule PlantAidWeb.AdminLive do
  use PlantAidWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>Admin</.header>

      <ul class="list-disc">
        <li>
          <.link navigate={~p"/admin/users"} class="text-zinc-900 hover:text-zinc-700">
            Users
          </.link>
        </li>
        <li>
          <.link navigate={~p"/admin/location_types"} class="text-zinc-900 hover:text-zinc-700">
            Location Types
          </.link>
        </li>
        <li>
          <.link navigate={~p"/admin/hosts"} class="text-zinc-900 hover:text-zinc-700">
            Hosts
          </.link>
        </li>
        <li>
          <.link navigate={~p"/admin/pathologies"} class="text-zinc-900 hover:text-zinc-700">
            Pathologies
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
