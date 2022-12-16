defmodule PlantAidWeb.HomeLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Observations

  @impl true
  def mount(_params, _session, socket) do
    # IO.puts("calling mount")
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    # IO.puts("calling handle_params")

    if connected?(socket) do
      # counties = Observations.get_county_aggregates()
      # bounds = Observations.bounding_box()

      {counties, bounds} = Observations.get_county_aggregates_with_bounds()

      {:noreply,
       push_event(
         socket,
         "map-data",
         %{
           bounds: bounds,
           data: %{
             type: "FeatureCollection",
             features:
               counties
               |> Enum.map(fn county ->
                 %{
                   type: "Feature",
                   properties: %{
                     name: county.name,
                     state: county.state,
                     observation_count: county.observation_count,
                     density: county.density
                   },
                   geometry: county.geometry
                 }
               end)
           }
         }
       )}
    else
      {:noreply, socket}
    end
  end
end
