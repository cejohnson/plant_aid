defmodule PlantAidWeb.HostLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Hosts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage host records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="host-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :common_name}} type="text" label="common_name" />
        <.input field={{f, :scientific_name}} type="text" label="scientific_name" />

        <%= for {fp, i} <- Phoenix.HTML.Form.inputs_for(f, :varieties) |> Enum.with_index() do %>
          <%= Phoenix.HTML.Form.hidden_inputs_for(fp) %>
          <.input field={{fp, :name}} type="text" />
          <%= cond do %>
            <% fp.data.id -> %>
              <.input field={{fp, :delete}} type="checkbox" label="delete" />
            <% true -> %>
              <.button form phx-target={@myself} phx-click="remove-variety" value={i}>
                Delete
              </.button>
          <% end %>
        <% end %>
        <.button phx-click="add-variety" form phx-target={@myself}>Add Variety</.button>

        <:actions>
          <.button phx-disable-with="Saving...">Save Host</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{host: host} = assigns, socket) do
    changeset = Hosts.change_host(host)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"host" => host_params}, socket) do
    changeset =
      socket.assigns.host
      |> Hosts.change_host(host_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"host" => host_params}, socket) do
    save_host(socket, socket.assigns.action, host_params)
  end

  def handle_event("add-variety", _, socket) do
    varieties =
      Map.get(socket.assigns.changeset.changes, :varieties, socket.assigns.host.varieties)

    varieties = varieties ++ [Hosts.change_host_variety(%PlantAid.Hosts.HostVariety{})]

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:varieties, varieties)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("remove-variety", %{"value" => i}, socket) do
    IO.inspect(i, label: "params")
    index = String.to_integer(i)

    {removed, varieties} =
      Map.get(socket.assigns.changeset.changes, :varieties, socket.assigns.host.varieties)
      |> List.pop_at(index)

    # variety = Enum.at(varieties, index)

    IO.inspect(removed, label: "removed")

    changeset = socket.assigns.changeset |> Ecto.Changeset.put_assoc(:varieties, varieties)

    {:noreply, assign(socket, changeset: changeset)}
  end

  defp save_host(socket, :edit, host_params) do
    case Hosts.update_host(socket.assigns.host, host_params) do
      {:ok, _host} ->
        {:noreply,
         socket
         |> put_flash(:info, "Host updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_host(socket, :new, host_params) do
    case Hosts.create_host(host_params) do
      {:ok, _host} ->
        {:noreply,
         socket
         |> put_flash(:info, "Host created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
