# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PlantAid.Repo.insert!(%PlantAid.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PlantAid.Geography.County

counties =
  with {:ok, body} <- Path.expand("priv/repo/data/us_lower_48_counties.geojson") |> File.read(),
       {:ok, json} <- Jason.decode(body) do
    Enum.map(json["features"], fn feature ->
      %{
        name: feature["properties"]["NAME"],
        state: feature["properties"]["STATE_NAME"],
        sqmi: feature["properties"]["SQMI"],
        geometry: Geo.JSON.decode!(feature["geometry"])
      }
    end)
  end

PlantAid.Repo.insert_all(County, counties)
