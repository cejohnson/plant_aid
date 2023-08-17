defmodule PlantAidWeb.UserFilterForm do
  use PlantAidWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-auto bg-stone-300">
      <.filter_form id="user-filter-form" meta={@meta} target={@myself} fields={@fields} />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    fields = [
      email: [
        label: "Email",
        op: :ilike
      ],
      name: [
        label: "Name",
        op: :ilike
      ],
      roles: [
        label: "Roles",
        op: :contains,
        type: "select",
        options:
          [
            {"Researcher", :researcher},
            {"Admin", :admin},
            {"Superuser", :superuser}
          ]
          |> prepend_default_option()
      ],
      confirmed_at: [
        label: "Confirmed?",
        op: :not_empty,
        type: "select",
        options:
          [
            {"True", true},
            {"False", false}
          ]
          |> prepend_default_option()
      ],
      last_seen: [
        label: "Last Seen Before",
        op: :<=
      ],
      last_seen: [
        label: "Last Seen After",
        op: :>=
      ]
    ]

    {:ok,
     socket
     |> assign(:fields, fields)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    send(self(), {:updated_filters, params})
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset-filter", params, socket) do
    params = Map.drop(params, ["page", "filters"])
    send(self(), {:updated_filters, params})
    {:noreply, socket}
  end

  defp prepend_default_option(options) do
    [{"Any", nil}] ++ options
  end
end
