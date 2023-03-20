defmodule PlantAid.Mapping do
  import Ecto.Query

  alias PlantAid.Repo
  alias PlantAid.Observations.Observation

  def group_observations_by_secondary_subdivision do
    group_observations_by_secondary_subdivision(%Flop{})
  end

  def group_observations_by_secondary_subdivision(%Flop{} = flop) do
    secondary_subdivisions =
      from(
        o in Observation,
        inner_join: ssd in assoc(o, :secondary_subdivision),
        group_by: ssd.id,
        select: %{
          ssd
          | observation_count: count(o.id)
        }
      )
      |> Flop.filter(flop)
      |> Repo.all()
      |> Repo.preload(primary_subdivision: :country)

    bounds =
      from(
        o in Observation,
        inner_join: s in assoc(o, :secondary_subdivision),
        select: fragment("ST_Envelope(ST_Collect(?::geometry))", s.geog)
      )
      |> Flop.filter(flop)
      |> Repo.one()
      |> (fn geom ->
            case geom do
              nil ->
                [[-180, -70], [180, 70]]

              geom ->
                coordinates = List.first(geom.coordinates)
                southwest_point = Enum.at(coordinates, 0)
                northeast_point = Enum.at(coordinates, 2)

                [Tuple.to_list(southwest_point), Tuple.to_list(northeast_point)]
            end
          end).()

    observation_count =
      from(
        o in Observation,
        inner_join: ssd in assoc(o, :secondary_subdivision)
      )
      |> Flop.count(flop)

    meta = %Flop.Meta{
      flop: flop,
      schema: Observation,
      total_count: observation_count
    }

    data = %{
      type: "FeatureCollection",
      features:
        secondary_subdivisions
        |> Enum.map(fn s ->
          %{
            type: "Feature",
            properties: %{
              name: s.name,
              category: s.category,
              primary_subdivision:
                String.split(s.primary_subdivision.iso3166_2, "-") |> List.last(),
              observation_count: s.observation_count
            },
            geometry: s.geog
          }
        end)
    }

    {%{data: data, bounds: bounds}, meta}
  end

  def group_observations_by_secondary_subdivision(%{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, group_observations_by_secondary_subdivision(flop)}
    end
  end
end
