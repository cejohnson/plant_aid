defmodule PlantAidWeb.LocationLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Locations
  alias PlantAid.Locations.Location

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage location records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="location-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.button
          id="get-position"
          class="bg-stone-500"
          type="button"
          phx-hook="GetCurrentPosition"
          phx-target={@myself}
        >
          Populate Current Position
        </.button>

        <.input field={@form[:latitude]} type="text" inputmode="decimal" label="Latitude" />
        <.input field={@form[:longitude]} type="text" inputmode="decimal" label="Longitude" />

        <%!-- <div
          id="location-form-map"
          phx-hook="MapBoxPointData"
          phx-update="ignore"
          style="height: 200px;"
        >
        </div> --%>

        <:actions>
          <.button phx-disable-with="Saving...">Save Location</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{location: location} = assigns, socket) do
    changeset = Locations.change_location(location)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"location" => location_params}, socket) do
    changeset =
      socket.assigns.location
      |> Locations.change_location(location_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"location" => location_params}, socket) do
    save_location(socket, socket.assigns.action, location_params)
  end

  def handle_event(
        "current_position",
        position,
        socket
      ) do
    changeset =
      socket.assigns.form.source
      |> Location.put_coordinates(position)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)}
  end

  defp save_location(socket, :edit, location_params) do
    case Locations.update_location(socket.assigns.location, location_params) do
      {:ok, location} ->
        notify_parent({:saved, location})

        {:noreply,
         socket
         |> put_flash(:info, "Location updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_location(socket, :new, location_params) do
    case Locations.create_location(socket.assigns.current_user, location_params) do
      {:ok, location} ->
        IO.puts("created")
        notify_parent({:saved, location})

        {:noreply,
         socket
         |> put_flash(:info, "Location created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.puts("error")
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
