defmodule PlantAidWeb.AdminLive do
  use PlantAidWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <div class="max-w-5xl">
        <div class="font-semibold text-3xl text-center p-4 text-lime-800">
          <.header>Admin</.header>
        </div>

        <ul class="list">
          <li>
            <.link navigate={~p"/admin/users"} class="text-lime-700 inline-flex hover:opacity-80 ">
              <svg
                class="flex-shrink-0 size-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
              Users
            </.link>
          </li>
          <li>
            <.link
              navigate={~p"/admin/location_types"}
              class="text-lime-700 inline-flex hover:opacity-80 "
            >
              <svg
                class="flex-shrink-0 size-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
              Location Types
            </.link>
          </li>
          <li>
            <.link navigate={~p"/admin/hosts"} class="text-lime-700 inline-flex hover:opacity-80 ">
              <svg
                class="flex-shrink-0 size-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
              Hosts
            </.link>
          </li>
          <li>
            <.link
              navigate={~p"/admin/pathologies"}
              class="text-lime-700 inline-flex hover:opacity-80 "
            >
              <svg
                class="flex-shrink-0 size-4"
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
              Pathologies
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
