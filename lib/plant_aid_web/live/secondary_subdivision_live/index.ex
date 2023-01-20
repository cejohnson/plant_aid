defmodule PlantAidWeb.SecondarySubdivisionLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Geography

  @impl true
  def mount(_params, _session, socket) do
    countries = Geography.list_countries_for_filtering()

    country_options = Enum.map(countries, fn c -> {c.name, c.id} end)

    {:ok,
     socket
     |> assign(:countries, countries)
     |> assign(:country_options, [{"Select", nil} | country_options])
     |> assign(:primary_subdivision_options, [{"Select a country first", nil}])
     |> assign(:secondary_subdivision_options, [{"Select a primary subdivision first", nil}])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    IO.inspect(params, label: "params")

    socket =
      case Geography.list_secondary_subdivisions(params) do
        {:ok, {secondary_subdivisions, meta}} ->
          IO.inspect(meta, label: "new meta")

          country_id =
            Enum.find_value(meta.flop.filters, "", fn f ->
              if f.field == :country_id, do: f.value || ""
            end)

          IO.inspect(country_id, label: "country_id")

          primary_subdivision_id =
            Enum.find_value(meta.flop.filters, "", fn f ->
              if f.field == :primary_subdivision_id, do: f.value || ""
            end)

          IO.inspect(primary_subdivision_id, label: "primary_subdivision_id")

          socket
          |> set_primary_subdivision_options(country_id)
          |> set_secondary_subdivision_options(country_id, primary_subdivision_id)
          |> assign(%{
            page_title: "Listing Secondary Subdivisions",
            secondary_subdivisions: secondary_subdivisions,
            meta: meta
          })

        error ->
          IO.inspect(error, label: "error")
          socket
      end

    if connected?(socket) do
      IO.inspect("rerunning map query")
      # secondary_subdivisions = Geography.list_secondary_subdivisions(params, paginate: false)
      # IO.inspect(length(secondary_subdivisions), label: "map items")

      # socket
      # |> push_event("map-data", %{
      #   type: "FeatureCollection",
      #   features:
      #     secondary_subdivisions
      #     |> Enum.map(fn ssd ->
      #       %{
      #         type: "Feature",
      #         properties: %{
      #           name: ssd.name,
      #           category: ssd.category,
      #           primary_subdivision:
      #             String.split(ssd.primary_subdivision.iso3166_2, "-") |> List.last(),
      #           observation_count: ssd.observation_count
      #         },
      #         geometry: ssd.geog
      #       }
      #     end)
      # })

      case Geography.list_secondary_subdivisions(params, paginate: false) do
        {secondary_subdivisions, _meta} ->
          IO.inspect(length(secondary_subdivisions), label: "map items")

          socket
          |> push_event("map-data", %{
            type: "FeatureCollection",
            features:
              secondary_subdivisions
              |> Enum.map(fn ssd ->
                %{
                  type: "Feature",
                  properties: %{
                    name: ssd.name,
                    category: ssd.category,
                    primary_subdivision:
                      String.split(ssd.primary_subdivision.iso3166_2, "-") |> List.last(),
                    observation_count: ssd.observation_count
                  },
                  geometry: ssd.geog
                }
              end)
          })

        error ->
          # IO.inspect(error, label: "error")
          IO.puts("map error")
          socket
      end
    else
      socket
    end
  end

  @impl true
  def handle_event("reset-filter", _, %{assigns: assigns} = socket) do
    # flop = assigns.meta.flop |> Flop.set_page(1) |> Flop.reset_filters()

    # path =
    # Flop.Phoenix.build_path(~p"/secondary_subdivisions", flop, backend: assigns.meta.backend)

    {:noreply, push_patch(socket, to: ~p"/secondary_subdivisions")}
  end

  @impl true
  def handle_event("submit-filter", %{"filter" => params}, socket) do
    IO.inspect(params, label: "submit-filter")
    # {:noreply, socket}
    {:noreply, push_patch(socket, to: ~p"/secondary_subdivisions?#{params}")}
  end

  @impl true
  def handle_event("update-filter", %{"filter" => params}, socket) do
    IO.inspect(params, label: "update-filter")
    IO.inspect(socket.assigns.meta, label: "assings")
    IO.inspect(params, label: "start-params")
    filters = params["filters"]

    IO.inspect(filters, label: "filters")

    # Clear the primary_subdivision_id if the country changed
    current_country_id =
      Enum.find_value(socket.assigns.meta.flop.filters, "", fn f ->
        if f.field == :country_id, do: f.value
      end)

    new_country_id =
      Enum.find_value(filters, fn {_, f} ->
        if f["field"] == "country_id", do: f["value"]
      end)

    filters =
      if current_country_id != new_country_id do
        Enum.map(filters, fn {k, v} ->
          if v["field"] == "primary_subdivision_id" do
            {k, Map.replace(v, "value", "")}
          else
            {k, v}
          end
        end)
        |> Map.new()
      else
        filters
      end

    IO.inspect(filters, label: "post psd clear")

    # Clear the (secondary_subdivision) id if the primary_subdivision_id changed
    current_primary_subdivision_id =
      Enum.find_value(socket.assigns.meta.flop.filters, "", fn f ->
        if f.field == :primary_subdivision_id, do: f.value
      end)

    new_primary_subdivision_id =
      Enum.find_value(filters, fn {_, f} ->
        if f["field"] == "primary_subdivision_id", do: f["value"]
      end)

    filters =
      if current_primary_subdivision_id != new_primary_subdivision_id do
        Enum.map(filters, fn {k, v} ->
          if v["field"] == "id" do
            {k, Map.replace(v, "value", "")}
          else
            {k, v}
          end
        end)
        |> Map.new()
      else
        filters
      end

    IO.inspect(filters, label: "post ssd clear")

    params = %{"filters" => filters}

    IO.inspect(params, label: "final-params")

    {:noreply, push_patch(socket, to: ~p"/secondary_subdivisions?#{params}")}
  end

  defp set_primary_subdivision_options(socket, "") do
    socket
    |> assign(:primary_subdivision_options, [{"Select a country first", nil}])
  end

  defp set_primary_subdivision_options(socket, country_id) do
    options =
      socket.assigns.countries
      |> Enum.find(fn c -> c.id == String.to_integer(country_id) end)
      |> Map.get(:primary_subdivisions)
      |> Enum.map(&{&1.name, &1.id})

    socket
    |> assign(:primary_subdivision_options, [{"Select", ""} | options])
  end

  defp set_secondary_subdivision_options(socket, "", _) do
    IO.puts("ssdo1")

    socket
    |> assign(:secondary_subdivision_options, [{"Select a primary subdivision first", nil}])
  end

  defp set_secondary_subdivision_options(socket, _, "") do
    IO.puts("ssdo2")

    socket
    |> assign(:secondary_subdivision_options, [{"Select a primary subdivision first", nil}])
  end

  defp set_secondary_subdivision_options(socket, country_id, primary_subdivision_id) do
    IO.puts("ssdo3")

    options =
      socket.assigns.countries
      |> Enum.find(fn c -> c.id == String.to_integer(country_id) end)
      |> Map.get(:primary_subdivisions)
      |> Enum.find(fn psd -> psd.id == String.to_integer(primary_subdivision_id) end)
      |> Map.get(:secondary_subdivisions)
      |> Enum.map(fn ssd ->
        {ssd.name, ssd.id}
      end)

    socket
    |> assign(:secondary_subdivision_options, [{"Select", ""} | options])
  end
end
