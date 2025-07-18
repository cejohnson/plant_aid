defmodule PlantAidWeb.AlertSubscriptionLive.FormComponent do
  use PlantAidWeb, :live_component

  alias PlantAid.Accounts.User
  alias PlantAid.Alerts
  alias PlantAid.Geography
  alias PlantAid.Locations
  alias PlantAid.Pathologies
  alias PlantAid.Utilities

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          Create or edit an alert subscription. Alerts will be created for events matching the criteria below.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="alert_subscription-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:enabled]} type="checkbox" label="Enabled" />

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Optional, will be automatically populated if left empty."
        />

        <.radio_group
          :if={User.has_role?(@current_user, [:researcher, :admin, :superuser])}
          field={@form[:events_selector]}
          label="Event Type"
        >
          <:radio value="any">Any</:radio>
          <:radio value="disease_reported">
            Disease reported
          </:radio>
          <:radio value="disease_confirmed">
            Disease confirmed
          </:radio>
        </.radio_group>

        <.radio_group field={@form[:pathologies_selector]} label="Pathology Filter">
          <:radio value="any">Any</:radio>
          <:radio value="include">ONLY the following</:radio>
          <:radio value="exclude">Any pathology EXCEPT the following</:radio>
        </.radio_group>
        <.input
          :if={@show_pathologies_input}
          field={@form[:pathology_ids]}
          type="select"
          multiple
          label="Pathologies"
          options={@pathology_options}
        />

        <.radio_group field={@form[:geographical_selector]} label="Geographic Filter">
          <:radio value="any">Anywhere</:radio>
          <:radio value="regions">Regions (country, state, county, etc.)</:radio>
          <:radio value="locations">
            Near
            <.link navigate={~p"/locations"} class="text-primary hover:underline">my locations</.link>
          </:radio>
        </.radio_group>

        <div :if={@show_regions_input}>
          <.label>Regions</.label>
          <div class="text-sm text-zinc-600">
            Select one or more regions; smaller regions always take precedence over larger regions. For example, if you select Canada and the USA, you'll get alerts for both countries. However, if you select Canada and the USA, AND the state of Maine, you will only receive alerts for Maine. If you wanted to receive alerts for both Canada and Maine you would need to create multiple subscriptions.
          </div>
          <.input
            field={@form[:country_ids]}
            type="select"
            multiple
            label="Countries"
            options={@country_options}
          />

          <.input
            :if={@primary_subdivision_options}
            field={@form[:primary_subdivision_ids]}
            type="select"
            multiple
            label={@primary_subdivision_label}
            options={@primary_subdivision_options}
          />

          <.input
            :if={@secondary_subdivision_options}
            field={@form[:secondary_subdivision_ids]}
            type="select"
            multiple
            label={@secondary_subdivision_label}
            options={@secondary_subdivision_options}
          />
        </div>

        <.radio_group
          :if={@show_locations_selector}
          field={@form[:locations_selector]}
          label="Location Filter"
        >
          <:radio value="any">
            Any of
            <.link navigate={~p"/locations"} class="text-primary hover:underline">my locations</.link>
          </:radio>
          <:radio value="include">ONLY the following locations</:radio>
          <:radio value="exclude">Any of my locations EXCEPT the following</:radio>
        </.radio_group>
        <.input
          :if={@show_locations_input}
          field={@form[:location_ids]}
          type="select"
          multiple
          label="Locations"
          options={@location_options}
        />

        <div :if={@show_distance_input}>
          <.input
            field={@form[:distance]}
            type="text"
            inputmode="decimal"
            label="Alert within this range"
            placeholder="100.0"
          />
          <.input field={@form[:distance_unit]} type="select" options={["miles", "kilometers"]} />
        </div>

        <:actions>
          <.button variant="primary" phx-disable-with="Saving...">Save Alert Subscription</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(
        %{alert_subscription: alert_subscription, current_user: current_user} = assigns,
        socket
      ) do
    changeset =
      alert_subscription
      |> Alerts.preload_alert_subscription_fields()
      |> Alerts.change_alert_subscription()

    pathology_options = Pathologies.list_pathologies() |> Enum.map(&{&1.common_name, &1.id})
    location_options = Locations.list_locations(current_user) |> Enum.map(&{&1.name, &1.id})
    country_ids = Enum.map(alert_subscription.countries, & &1.id)
    primary_subdivision_ids = Enum.map(alert_subscription.primary_subdivisions, & &1.id)

    country_options = Geography.list_countries() |> Enum.map(&{&1.name, &1.id})

    {primary_subdivision_label, primary_subdivision_options} =
      get_primary_subdivision_label_and_options(country_ids)

    {secondary_subdivision_label, secondary_subdivision_options} =
      get_secondary_subdivision_label_and_options(primary_subdivision_ids)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:alert_subscription, alert_subscription)
     |> assign(:pathology_options, pathology_options)
     |> assign(:location_options, location_options)
     |> assign(:country_options, country_options)
     |> assign(:primary_subdivision_label, primary_subdivision_label)
     |> assign(:primary_subdivision_options, primary_subdivision_options)
     |> assign(:secondary_subdivision_label, secondary_subdivision_label)
     |> assign(:secondary_subdivision_options, secondary_subdivision_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"alert_subscription" => alert_subscription_params}, socket) do
    alert_subscription_params = maybe_update_geographic_attrs(alert_subscription_params)

    changeset =
      socket.assigns.alert_subscription
      |> Alerts.change_alert_subscription(alert_subscription_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"alert_subscription" => alert_subscription_params}, socket) do
    alert_subscription_params = maybe_update_geographic_attrs(alert_subscription_params)
    save_alert_subscription(socket, socket.assigns.action, alert_subscription_params)
  end

  defp save_alert_subscription(socket, :edit, alert_subscription_params) do
    alert_subscription = socket.assigns.alert_subscription
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :update_alert_subscription, user, alert_subscription) do
      case Alerts.update_alert_subscription(
             socket.assigns.alert_subscription,
             alert_subscription_params
           ) do
        {:ok, alert_subscription} ->
          notify_parent({:saved, alert_subscription})

          {:noreply,
           socket
           |> put_flash(:info, "Alert subscription updated successfully")
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

  defp save_alert_subscription(socket, :new, alert_subscription_params) do
    alert_subscription = socket.assigns.alert_subscription
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :create_alert_subscription, user) do
      case Alerts.create_alert_subscription(
             alert_subscription,
             alert_subscription_params
           ) do
        {:ok, alert_subscription} ->
          notify_parent({:saved, alert_subscription})

          {:noreply,
           socket
           |> put_flash(:info, "Alert subscription created successfully")
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

  defp maybe_update_geographic_attrs(attrs) do
    attrs
    |> Map.put_new("country_ids", [])
    |> Map.put_new("primary_subdivision_ids", [])
    |> Map.put_new("secondary_subdivision_ids", [])
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    show_pathologies_input =
      Ecto.Changeset.get_field(changeset, :pathologies_selector) in [:include, :exclude]

    show_locations_selector =
      Ecto.Changeset.get_field(changeset, :geographical_selector) == :locations

    show_locations_input =
      show_locations_selector &&
        Ecto.Changeset.get_field(changeset, :locations_selector) in [:include, :exclude]

    show_distance_input =
      Ecto.Changeset.get_field(changeset, :geographical_selector) == :locations

    show_regions_input = Ecto.Changeset.get_field(changeset, :geographical_selector) == :regions

    socket
    |> maybe_assign_geographic_options(changeset, socket.assigns[:form])
    |> assign(:show_pathologies_input, show_pathologies_input)
    |> assign(:show_locations_selector, show_locations_selector)
    |> assign(:show_locations_input, show_locations_input)
    |> assign(:show_distance_input, show_distance_input)
    |> assign(:show_regions_input, show_regions_input)
    |> assign(:form, to_form(changeset))
  end

  defp maybe_assign_geographic_options(socket, _new_changeset, nil) do
    socket
  end

  defp maybe_assign_geographic_options(socket, new_changeset, form) do
    old_changeset = form.source

    cond do
      Ecto.Changeset.get_field(new_changeset, :geographical_selector) != :regions ->
        socket
        |> assign(:primary_subdivision_options, nil)
        |> assign(:secondary_subdivision_options, nil)

      field_changed?(new_changeset, old_changeset, :country_ids) ->
        {label, options} =
          Ecto.Changeset.get_field(new_changeset, :country_ids)
          |> get_primary_subdivision_label_and_options()

        socket
        |> assign(:primary_subdivision_label, label)
        |> assign(:primary_subdivision_options, options)
        |> assign(:secondary_subdivision_options, nil)

      field_changed?(new_changeset, old_changeset, :primary_subdivision_ids) ->
        {label, options} =
          Ecto.Changeset.get_field(new_changeset, :primary_subdivision_ids)
          |> get_secondary_subdivision_label_and_options()

        socket
        |> assign(:secondary_subdivision_label, label)
        |> assign(:secondary_subdivision_options, options)

      true ->
        socket
    end
  end

  defp get_primary_subdivision_label_and_options(nil) do
    {nil, nil}
  end

  defp get_primary_subdivision_label_and_options([]) do
    {nil, nil}
  end

  defp get_primary_subdivision_label_and_options(country_ids) do
    with {primary_subdivisions, _meta} <-
           Geography.list_primary_subdivisions(%Flop{
             filters: [%Flop.Filter{field: :country_id, op: :in, value: country_ids}],
             order_by: [:name],
             order_directions: [:asc]
           }) do
      label =
        primary_subdivisions
        |> Enum.map(& &1.category)
        |> Enum.frequencies()
        |> Enum.sort_by(fn {_category, count} -> count end, :desc)
        |> Enum.map(fn {category, _count} -> category end)
        |> Utilities.english_join("or",
          excess_descriptor: "equivalent",
          include_excess_count: false
        )

      options = Enum.map(primary_subdivisions, &{&1.name, &1.id})

      {label, options}
    end
  end

  defp get_secondary_subdivision_label_and_options(nil) do
    {nil, nil}
  end

  defp get_secondary_subdivision_label_and_options([]) do
    {nil, nil}
  end

  defp get_secondary_subdivision_label_and_options(primary_subdivision_ids) do
    with {secondary_subdivisions, _meta} <-
           Geography.list_secondary_subdivisions(%Flop{
             filters: [
               %Flop.Filter{
                 field: :primary_subdivision_id,
                 op: :in,
                 value: primary_subdivision_ids
               }
             ],
             order_by: [:name],
             order_directions: [:asc]
           }) do
      label =
        secondary_subdivisions
        |> Enum.map(& &1.category)
        |> Enum.frequencies()
        |> Enum.sort_by(fn {_category, count} -> count end, :desc)
        |> Enum.map(fn {category, _count} -> category end)
        |> Utilities.english_join("or",
          excess_descriptor: "equivalent",
          include_excess_count: false
        )

      options = Enum.map(secondary_subdivisions, &{&1.name, &1.id})
      {label, options}
    end
  end

  defp field_changed?(changeset1, changeset2, field) do
    Ecto.Changeset.get_field(changeset1, field) != Ecto.Changeset.get_field(changeset2, field)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
