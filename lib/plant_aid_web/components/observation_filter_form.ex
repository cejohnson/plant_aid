defmodule PlantAidWeb.ObservationFilterForm do
  use PlantAidWeb, :live_component

  alias PlantAid.FormHelpers
  alias PlantAid.Observations.Observation

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-auto bg-stone-300">
      <.filter_form id="observation-filter-form" meta={@meta} target={@myself} fields={@fields} />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    flop = assigns.meta.flop
    organic_options = FormHelpers.list_organic_options(flop) |> prepend_default_option()
    country_options = FormHelpers.list_country_options(flop) |> prepend_default_option()
    host_options = FormHelpers.list_host_options(flop) |> prepend_default_option()

    location_type_options =
      FormHelpers.list_location_type_options(flop) |> prepend_default_option()

    pathology_options = FormHelpers.list_pathology_options(flop) |> prepend_default_option()

    fields = [
      id: [
        label: "ID"
      ],
      source: [
        label: "Data Source",
        type: "select",
        options:
          [
            {"PlantAid", :plant_aid},
            {"USA Blight", :usa_blight},
            {"National Plant Diagnostic Network", :npdn},
            {"Cucurbit Sentinel Network", :cucurbit_sentinel_network}
          ]
          |> prepend_default_option()
      ],
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
        label: "Suspected Disease",
        type: "select",
        options: pathology_options,
        value: Flop.Filter.get_value(flop.filters, :suspected_pathology_id)
      ],
      confirmed_pathology_id: [
        label: "Confirmed Disease",
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
        options: organic_options
      ],
      country_id: [
        label: "Country",
        type: "select",
        options: country_options
      ]
    ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:fields, fields)
     |> maybe_add_user_field(assigns)
     |> maybe_add_genotype_id_field(assigns.meta.flop)
     |> maybe_add_primary_subdivision_id_field(assigns.meta.flop)
     |> maybe_add_secondary_subdivision_id_field(assigns.meta.flop)}
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

  defp maybe_add_genotype_id_field(%{assigns: %{fields: fields}} = socket, %Flop{} = flop) do
    case Flop.Filter.get_value(flop.filters, :confirmed_pathology_id) do
      nil ->
        fields = Keyword.drop(fields, [:genotype_id])
        assign(socket, :fields, fields)

      pathology_id ->
        genotype_options =
          FormHelpers.list_genotype_options(pathology_id)
          |> prepend_default_option()

        index = Enum.find_index(fields, fn {key, _value} -> key == :confirmed_pathology_id end)

        fields =
          List.insert_at(
            fields,
            index + 1,
            {:genotype_id, [label: "Genotype", type: "select", options: genotype_options]}
          )

        assign(socket, :fields, fields)
    end
  end

  defp maybe_add_primary_subdivision_id_field(
         %{assigns: %{fields: fields}} = socket,
         %Flop{} = flop
       ) do
    case Flop.Filter.get_value(flop.filters, :country_id) do
      nil ->
        fields = Keyword.drop(fields, [:primary_subdivision_id])
        assign(socket, :fields, fields)

      country_id ->
        primary_subdivision_options =
          FormHelpers.list_primary_subdivision_options(flop)
          |> prepend_default_option()

        primary_subdivision_label =
          FormHelpers.list_primary_subdivision_categories(country_id)
          |> join_with_or()

        fields =
          Keyword.drop(fields, [:primary_subdivision_id]) ++
            [
              primary_subdivision_id: [
                label: primary_subdivision_label,
                type: "select",
                options: primary_subdivision_options
              ]
            ]

        assign(socket, :fields, fields)
    end
  end

  defp maybe_add_secondary_subdivision_id_field(
         %{assigns: %{fields: fields}} = socket,
         %Flop{} = flop
       ) do
    case Flop.Filter.get_value(flop.filters, :primary_subdivision_id) do
      nil ->
        fields = Keyword.drop(fields, [:secondary_subdivision_id])
        assign(socket, :fields, fields)

      primary_subdivision_id ->
        secondary_subdivision_options =
          FormHelpers.list_secondary_subdivision_options(flop)
          |> prepend_default_option()

        fields =
          case secondary_subdivision_options do
            [{"Any", nil}] ->
              Keyword.drop(fields, [:secondary_subdivision_id])

            _ ->
              secondary_subdivision_label =
                FormHelpers.list_secondary_subdivision_categories(primary_subdivision_id)
                |> join_with_or()

              Keyword.drop(fields, [:secondary_subdivision_id]) ++
                [
                  secondary_subdivision_id: [
                    label: secondary_subdivision_label,
                    type: "select",
                    options: secondary_subdivision_options
                  ]
                ]
          end

        assign(socket, :fields, fields)
    end
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

  defp filter_changed?(field, flop1, flop2) do
    Flop.Filter.get(flop1.filters, field) != Flop.Filter.get(flop2.filters, field)
  end

  defp prepend_default_option(options) do
    [{"Any", nil} | options]
  end

  defp join_with_or([]) do
    "Region"
  end

  defp join_with_or([first | []]) do
    first
  end

  defp join_with_or([first | [last]]) do
    first <> " or " <> last
  end

  defp join_with_or([first | [second | _]]) do
    first <> ", " <> second <> ", or Equivalent"
  end
end
