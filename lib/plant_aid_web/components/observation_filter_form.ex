defmodule PlantAidWeb.ObservationFilterForm do
  use PlantAidWeb, :live_component

  alias PlantAid.FormHelpers
  alias PlantAid.Observations.Observation

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.filter_form id="observation-filter-form" meta={@meta} target={@myself} fields={@fields} />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    host_options = FormHelpers.list_host_options() |> prepend_default_option()
    location_type_options = FormHelpers.list_location_type_options() |> prepend_default_option()
    pathology_options = FormHelpers.list_pathology_options() |> prepend_default_option()
    country_options = FormHelpers.list_country_options() |> prepend_default_option()
    primary_subdivision_options = prepend_default_option()
    secondary_subdivision_options = prepend_default_option()

    fields = [
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
        options: host_options
      ],
      suspected_pathology_id: [
        label: "Suspected Pathology",
        type: "select",
        options: pathology_options
      ],
      location_type_id: [
        label: "Location Type",
        type: "select",
        options: location_type_options
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
        options: country_options
      ],
      primary_subdivision_id: [
        label: "Primary Subdivision",
        type: "select",
        options: primary_subdivision_options
      ],
      secondary_subdivision_id: [
        label: "Secondary Subdivision",
        type: "select",
        options: secondary_subdivision_options
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
     |> maybe_add_user_field(assigns)
     |> maybe_assign_geographic_subdivision_options(assigns.meta.flop)
     |> assign(assigns)}
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

  defp maybe_add_user_field(socket, %{filter_users: true}) do
    fields = Keyword.put_new(socket.assigns.fields, :user_email, label: "User", op: :ilike)
    assign(socket, :fields, fields)
  end

  defp maybe_add_user_field(socket, _assigns) do
    socket
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
          |> FormHelpers.list_primary_subdivision_options()
          |> prepend_default_option()

        socket
        |> assign(:primary_subdivision_options, primary_subdivision_options)
        |> assign(:secondary_subdivision_options, prepend_default_option())

      filter_changed?(:primary_subdivision_id, current_flop, new_flop) ->
        secondary_subdivision_options =
          new_flop
          |> get_filter_value(:primary_subdivision_id)
          |> FormHelpers.list_secondary_subdivision_options()
          |> prepend_default_option()

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

  defp prepend_default_option(options \\ []) do
    [{'Any', nil}] ++ options
  end
end
