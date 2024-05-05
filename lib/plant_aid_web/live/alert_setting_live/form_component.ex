defmodule PlantAidWeb.AlertSettingLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Alerts
  alias PlantAid.Locations
  alias PlantAid.Pathologies

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage alert_setting records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="alert_setting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:enabled]} type="checkbox" label="Enabled" />

        <.radio_group field={@form[:pathologies_selector]} label="Send alerts for which pathologies?">
          <:radio value="any">Any</:radio>
          <:radio value="include">ONLY the following</:radio>
          <:radio value="exclude">Any EXCEPT the following</:radio>
        </.radio_group>
        <%= if @show_pathologies_input do %>
          <.input
            field={@form[:pathology_ids]}
            type="select"
            multiple
            label="Pathologies"
            options={@pathology_options}
          />
        <% end %>

        <.radio_group field={@form[:locations_selector]} label="Send alerts for which locations?">
          <:radio value="global">Anywhere</:radio>
          <:radio value="any">
            Any of
            <.link navigate={~p"/locations"} class="text-primary hover:underline">my locations</.link>
          </:radio>
          <:radio value="include">ONLY the following locations</:radio>
          <:radio value="exclude">Any of my locations EXCEPT the following</:radio>
        </.radio_group>
        <%= if @show_locations_input do %>
          <.input
            field={@form[:location_ids]}
            type="select"
            multiple
            label="Locations"
            options={@location_options}
          />
        <% end %>

        <%= if @show_distance_input do %>
          <.input
            field={@form[:distance]}
            type="text"
            inputmode="decimal"
            label="Alert within this range"
            placeholder="100.0"
          />
          <.input field={@form[:distance_unit]} type="select" options={["miles", "kilometers"]} />
        <% end %>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Alert setting</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{alert_setting: alert_setting, current_user: current_user} = assigns, socket) do
    changeset = Alerts.change_alert_setting(alert_setting)

    pathology_options =
      Pathologies.list_pathologies() |> Enum.map(fn p -> {p.common_name, p.id} end)

    location_options =
      Locations.list_locations(current_user)
      |> Enum.map(fn l -> {l.name, l.id} end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:pathology_options, pathology_options)
     |> assign(:location_options, location_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"alert_setting" => alert_setting_params}, socket) do
    changeset =
      socket.assigns.alert_setting
      |> Alerts.change_alert_setting(alert_setting_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"alert_setting" => alert_setting_params}, socket) do
    save_alert_setting(socket, socket.assigns.action, alert_setting_params)
  end

  defp save_alert_setting(socket, :edit, alert_setting_params) do
    alert_setting = socket.assigns.alert_setting
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :update_alert_setting, user, alert_setting) do
      case Alerts.update_alert_setting(socket.assigns.alert_setting, alert_setting_params) do
        {:ok, alert_setting} ->
          notify_parent({:saved, alert_setting})

          {:noreply,
           socket
           |> put_flash(:info, "Alert setting updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  defp save_alert_setting(socket, :new, alert_setting_params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :create_alert_setting, user) do
      case Alerts.create_alert_setting(socket.assigns.current_user, alert_setting_params) do
        {:ok, alert_setting} ->
          notify_parent({:saved, alert_setting})

          {:noreply,
           socket
           |> put_flash(:info, "Alert setting created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    show_pathologies_input =
      Ecto.Changeset.get_field(changeset, :pathologies_selector) in [:include, :exclude]

    show_locations_input =
      Ecto.Changeset.get_field(changeset, :locations_selector) in [:include, :exclude]

    show_distance_input =
      Ecto.Changeset.get_field(changeset, :locations_selector) in [:any, :include, :exclude]

    socket
    |> assign(:show_pathologies_input, show_pathologies_input)
    |> assign(:show_locations_input, show_locations_input)
    |> assign(:show_distance_input, show_distance_input)
    |> assign(:form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
