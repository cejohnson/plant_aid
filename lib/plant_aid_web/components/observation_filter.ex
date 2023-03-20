defmodule PlantAidWeb.ObservationFilter do
  use PlantAidWeb, :live_component

  alias PlantAid.Filters
  alias PlantAid.Observations.Observation

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.filter_form
        id="observation-filter-form"
        meta={@meta}
        target={@myself}
        fields={[
          observation_date: [
            label: "From",
            op: :>=,
            type: "date"
          ],
          observation_date: [
            label: "To",
            op: :<=,
            type: "date"
          ],
          host_id: [
            label: "Host",
            type: "select",
            options: @host_options
          ],
          suspected_pathology_id: [
            label: "Suspected Pathology",
            type: "select",
            options: @pathology_options
          ],
          location_type_id: [
            label: "Location Type",
            type: "select",
            options: @location_type_options
          ],
          organic: [
            label: "Organic",
            type: "select",
            options: [
              {"Any", nil},
              {"Organic", true},
              {"Not Organic", false}
            ]
          ],
          country_id: [
            label: "Country",
            type: "select",
            options: @country_options
          ],
          primary_subdivision_id: [
            label: "Primary Subdivision",
            type: "select",
            options: @primary_subdivision_options
          ],
          secondary_subdivision_id: [
            label: "Secondary Subdivision",
            type: "select",
            options: @secondary_subdivision_options
          ]
        ]}
      />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    host_options = Filters.list_host_options()
    location_type_options = Filters.list_location_type_options()
    pathology_options = Filters.list_pathology_options()
    country_options = Filters.list_country_options()
    primary_subdivision_options = Filters.list_primary_subdivision_options(nil)
    secondary_subdivision_options = Filters.list_secondary_subdivision_options(nil)

    {:ok,
     socket
     |> assign(:host_options, host_options)
     |> assign(:location_type_options, location_type_options)
     |> assign(:pathology_options, pathology_options)
     |> assign(:country_options, country_options)
     |> assign(:primary_subdivision_options, primary_subdivision_options)
     |> assign(:secondary_subdivision_options, secondary_subdivision_options)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> maybe_assign_geographic_subdivision_options(assigns.meta.flop)
     |> assign(:id, assigns.id)
     |> assign(:meta, assigns.meta)}
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    # If a higher level geographic entity changed we need to reset lower levels to avoid a situation like
    # country == "Canada" AND primary_subdivision == "North Carolina"
    params = maybe_reset_geographic_filters(socket, params)
    send(self(), {:updated_filters, params})
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset-filter", params, socket) do
    params = Map.drop(params, ["page", "filters"])
    send(self(), {:updated_filters, params})
    {:noreply, socket}
  end

  defp maybe_reset_geographic_filters(socket, params) do
    current_flop = socket.assigns.meta.flop
    new_flop = Flop.validate!(params, for: Observation)

    fields_to_reset =
      cond do
        filter_changed?(:country_id, current_flop, new_flop) ->
          ["primary_subdivision_id", "secondary_subdivision_id"]

        filter_changed?(:primary_subdivision_id, current_flop, new_flop) ->
          ["secondary_subdivision_id"]

        true ->
          []
      end

    case fields_to_reset do
      [] ->
        params

      fields ->
        filters =
          params
          |> Map.get("filters")
          |> Enum.map(fn {k, v} ->
            if Map.get(v, "field") in fields do
              {k, Map.put(v, "value", "")}
            else
              {k, v}
            end
          end)
          |> Map.new()

        %{
          params
          | "filters" => filters
        }
    end
  end

  defp maybe_assign_geographic_subdivision_options(
         %{assigns: %{meta: %Flop.Meta{flop: current_flop}}} = socket,
         new_flop
       ) do
    cond do
      filter_changed?(:country_id, current_flop, new_flop) ->
        primary_subdivision_options =
          new_flop
          |> get_filter_value(:country_id)
          |> Filters.list_primary_subdivision_options()

        socket
        |> assign(:primary_subdivision_options, primary_subdivision_options)
        |> assign(:secondary_subdivision_options, Filters.list_secondary_subdivision_options(nil))

      filter_changed?(:primary_subdivision_id, current_flop, new_flop) ->
        secondary_subdivision_options =
          new_flop
          |> get_filter_value(:primary_subdivision_id)
          |> Filters.list_secondary_subdivision_options()

        socket
        |> assign(:secondary_subdivision_options, secondary_subdivision_options)

      true ->
        socket
    end
  end

  defp maybe_assign_geographic_subdivision_options(socket, _) do
    socket
  end

  defp filter_changed?(field, flop1, flop2) do
    Flop.Filter.get(flop1.filters, field) != Flop.Filter.get(flop2.filters, field)
  end

  defp get_filter_value(flop, field) do
    filter = Flop.Filter.get(flop.filters, field)
    if filter, do: filter.value, else: nil
  end
end
