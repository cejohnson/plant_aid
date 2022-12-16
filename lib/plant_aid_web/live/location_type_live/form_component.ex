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
        :let={f}
        for={@changeset}
        id="location_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} type="text" label="name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Location type</.button>
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
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"location_type" => location_type_params}, socket) do
    changeset =
      socket.assigns.location_type
      |> LocationTypes.change_location_type(location_type_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"location_type" => location_type_params}, socket) do
    save_location_type(socket, socket.assigns.action, location_type_params)
  end

  defp save_location_type(socket, :edit, location_type_params) do
    case LocationTypes.update_location_type(socket.assigns.location_type, location_type_params) do
      {:ok, _location_type} ->
        {:noreply,
         socket
         |> put_flash(:info, "Location type updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_location_type(socket, :new, location_type_params) do
    case LocationTypes.create_location_type(location_type_params) do
      {:ok, _location_type} ->
        {:noreply,
         socket
         |> put_flash(:info, "Location type created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
