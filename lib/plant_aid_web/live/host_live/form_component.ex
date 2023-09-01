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
        for={@form}
        id="host-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:common_name]} type="text" label="Common Name" />
        <.input field={@form[:scientific_name]} type="text" label="Scientific Name" />
        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Host</.button>
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
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"host" => host_params}, socket) do
    changeset =
      socket.assigns.host
      |> Hosts.change_host(host_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset)}
  end

  def handle_event("save", %{"host" => host_params}, socket) do
    save_host(socket, socket.assigns.action, host_params)
  end

  defp save_host(socket, :edit, host_params) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Hosts, :update_host, current_user) do
      case Hosts.update_host(socket.assigns.host, host_params) do
        {:ok, host} ->
          notify_parent({:saved, host})

          {:noreply,
           socket
           |> put_flash(:info, "Host updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    end
  end

  defp save_host(socket, :new, host_params) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Hosts, :create_host, current_user) do
      case Hosts.create_host(host_params) do
        {:ok, host} ->
          notify_parent({:saved, host})

          {:noreply,
           socket
           |> put_flash(:info, "Host created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
