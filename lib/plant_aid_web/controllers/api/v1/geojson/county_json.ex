defmodule PlantAidWeb.Api.V1.GeoJSON.CountyJSON do
  alias PlantAid.Geography.County

  def index(%{counties: counties}) do
    %{
      type: "FeatureCollection",
      features: for(county <- counties, do: data(county))
    }
  end

  defp data(%County{} = county) do
    %{
      type: "Feature",
      properties: %{
        id: county.id,
        name: county.name,
        state: county.state
      },
      geometry: county.geometry
    }
  end
end
