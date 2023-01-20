defmodule PlantAidWeb.HomeLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Observations

  @impl true
  def mount(_params, _session, socket) do
    # IO.puts("calling mount")
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # IO.puts("calling handle_params")

    if connected?(socket) do
      # counties = Observations.get_county_aggregates()
      # secondary_subdivisions = PlantAid.Geography.list_secondary_subdivisions()
      # bounds = Observations.bounding_box()
      # counties = Observations.get_county_aggregates()

      # {counties, bounds} = Observations.get_county_aggregates_with_bounds()

      secondary_subdivisions = Observations.aggregate_observations(params)
      # IO.inspect(observations, label: "observations")
      # {:noreply, socket}

      # case Observations.aggregate_observations(params) do
      #   {:ok, {observations, meta}} ->
      #     IO.inspect(observations, label: observations)
      #     {:noreply, socket}

      #   _ ->
      #     {:noreply, socket}
      # end

      {:noreply,
       push_event(
         socket,
         "map-data",
         %{
           type: "FeatureCollection",
           features:
             secondary_subdivisions
             |> Enum.map(fn ssd ->
               %{
                 type: "Feature",
                 properties: %{
                   name: ssd.name,
                   category: ssd.category,
                   parent: String.split(ssd.primary_subdivision.iso3166_2, "-") |> List.last(),
                   #  state: county.state,
                   observation_count: ssd.observation_count
                   #  density: county.density
                 },
                 geometry: ssd.geog
               }
             end)
         }
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update-filter", %{"filter" => params}, socket) do
    IO.inspect(params, label: "update-filter")
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset-filter", _, %{assigns: assigns} = socket) do
    IO.inspect(assigns, label: "reset-filter")
    {:noreply, socket}
  end
end
