defmodule PlantAidWeb.LocationTypeLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.LocationTypes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage location_type records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="location_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Location type</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{location_type: location_type} = assigns, socket) do
    changeset = LocationTypes.change_location_type(location_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"location_type" => location_type_params}, socket) do
    changeset =
      socket.assigns.location_type
      |> LocationTypes.change_location_type(location_type_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset)}
  end

  def handle_event("save", %{"location_type" => location_type_params}, socket) do
    save_location_type(socket, socket.assigns.action, location_type_params)
  end

  defp save_location_type(socket, :edit, location_type_params) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(LocationTypes, :update_location_type, current_user) do
      case LocationTypes.update_location_type(socket.assigns.location_type, location_type_params) do
        {:ok, location_type} ->
          notify_parent({:saved, location_type})

          {:noreply,
           socket
           |> put_flash(:info, "Location type updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    end
  end

  defp save_location_type(socket, :new, location_type_params) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(LocationTypes, :create_location_type, current_user) do
      case LocationTypes.create_location_type(location_type_params) do
        {:ok, location_type} ->
          notify_parent({:saved, location_type})

          {:noreply,
           socket
           |> put_flash(:info, "Location type created successfully")
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
