defmodule PlantAid.Mapping do
  @behaviour Bodyguard.Policy

  import Ecto.Query

  alias PlantAid.Repo
  alias PlantAid.Accounts.User
  alias PlantAid.Geography.SecondarySubdivision
  alias PlantAid.Observations.Observation

  def authorize(:list_observations, %User{}, _), do: :ok

  def group_observations_by_secondary_subdivision do
    group_observations_by_secondary_subdivision(%Flop{})
  end

  def group_observations_by_secondary_subdivision(%Flop{} = flop) do
    opts = [for: Observation]

    counts =
      from(
        o in Observation,
        inner_join: ssd in assoc(o, :secondary_subdivision),
        left_join: s in assoc(o, :sample),
        as: :sample,
        left_join: p in assoc(s, :pathology),
        left_join: g in assoc(s, :genotype),
        group_by: [ssd.id, p.common_name, g.name],
        select: %{
          secondary_subdivision_id: ssd.id,
          pathology: p.common_name,
          genotype: g.name,
          count: count(o.id)
        }
      )
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.filter(flop, opts)
      |> Repo.all()
      |> Enum.group_by(fn %{secondary_subdivision_id: id} -> id end)
      |> Enum.map(fn {secondary_subdivision_id, counts} ->
        {secondary_subdivision_id,
         Enum.group_by(counts, fn %{pathology: pathology} -> pathology end)
         |> Enum.map(fn {pathology, counts} ->
           %{
             name: pathology || "Unknown",
             count:
               Enum.reduce(counts, 0, fn %{count: count}, total ->
                 total + count
               end),
             genotypes:
               Enum.map(counts, fn %{count: count, genotype: genotype} ->
                 %{name: genotype || "Not Genotyped", count: count}
               end)
               |> Enum.sort_by(fn %{count: count} -> count end, :desc)
           }
         end)
         |> Enum.sort_by(fn %{count: count} -> count end, :desc)}
      end)
      |> Map.new()

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
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.filter(flop, opts)
      |> Repo.all()
      # from(
      #   s in SecondarySubdivision,
      #   inner_join: o in assoc(s, :observations)
      # )
      # |> Flop.filter(flop)
      # |> Repo.all()
      |> Repo.preload(primary_subdivision: :country)

    # secondary_subdivisions =
    #   from(
    #     o in Observation,
    #     left_join: s in assoc(o, :sample),
    #     inner_join: ssd in assoc(o, :secondary_subdivision),
    #     group_by: [ssd.id, s.pathology_id, s.genotype_id],
    #     select: %{
    #       ssd
    #       | observation_count: count(o.id)
    #     }
    #   )
    #   |> Flop.filter(flop)
    #   |> Repo.all()
    #   |> Repo.preload(primary_subdivision: :country)

    bounds =
      from(
        o in Observation,
        inner_join: s in assoc(o, :secondary_subdivision),
        select: fragment("ST_Envelope(ST_Collect(?::geometry))", s.geog)
      )
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.filter(flop, opts)
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
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.count(flop, opts)

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
          # count_breakdown = Map.get(counts, s.id)
          # partial_counts =
          #   Map.get(counts, s.id, [])
          #   |> Enum.group_by(fn %{pathology: p} -> p end)
          #   |> Enum.map(fn {pathology, data} ->
          #     {pathology, %{data[:genotype] => data[:count]}}
          #   end)
          #   |> Map.new()

          %{
            type: "Feature",
            properties: %{
              name: s.name,
              category: s.category,
              primary_subdivision:
                String.split(s.primary_subdivision.iso3166_2, "-") |> List.last(),
              country: s.primary_subdivision.country.iso3166_1_alpha2,
              observation_count: s.observation_count,
              counts: Map.get(counts, s.id)
              # pathologies: partial_counts
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

  def list_observations(%User{} = user) do
    list_observations(user, %Flop{})
  end

  def list_observations(%User{} = user, %Flop{} = flop) do
    opts = [for: Observation]

    query =
      from(
        o in Observation,
        where: not is_nil(o.position),
        select: [
          :id,
          :user_id,
          :observation_date,
          :host_id,
          :host_other,
          :suspected_pathology_id,
          :position,
          :country_id,
          :primary_subdivision_id,
          :secondary_subdivision_id
        ],
        preload: [
          :user,
          :host,
          :suspected_pathology,
          :country,
          :primary_subdivision,
          secondary_subdivision: ^from(s in SecondarySubdivision, select: %{s | geog: nil}),
          sample: [:pathology]
        ]
      )
      |> scope(user)
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.filter(flop, opts)

    observations =
      query
      |> Repo.all()
      |> Enum.map(&maybe_populate_location/1)

    meta = Flop.meta(query, flop, opts)

    bounds =
      from(
        o in Observation,
        select: fragment("ST_Envelope(ST_Collect(?::geometry))", o.position)
      )
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.filter(flop, opts)
      |> Repo.one()
      |> (fn geom ->
            case geom do
              nil ->
                [[-180, -70], [180, 70]]

              %Geo.Point{coordinates: {long, lat}} ->
                # Single point, arbitrarily bound it 0.1 degrees in all directions
                [[long - 0.1, lat - 0.1], [long + 0.1, lat + 0.1]]

              geom ->
                coordinates = List.first(geom.coordinates)
                southwest_point = Enum.at(coordinates, 0)
                northeast_point = Enum.at(coordinates, 2)

                [Tuple.to_list(southwest_point), Tuple.to_list(northeast_point)]
            end
          end).()

    data = %{
      type: "FeatureCollection",
      features:
        observations
        |> Enum.map(fn o ->
          %{
            type: "Feature",
            properties: %{
              id: o.id,
              d: o.observation_date,
              h: (o.host && o.host.common_name) || o.host_other || "Unknown",
              p: (o.suspected_pathology && o.suspected_pathology.common_name) || "Unknown",
              l: o.location
            },
            geometry: o.position
          }
        end)
    }

    {%{data: data, bounds: bounds}, meta}
  end

  def list_observations(%User{} = user, %{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, list_observations(user, flop)}
    end
  end

  # TODO: figure out how to refactor this
  defp scope(query, %User{} = user) do
    case User.has_role?(user, [:superuser, :admin, :researcher]) do
      true ->
        query

      _ ->
        where(query, user_id: ^user.id)
    end
  end

  defp join_observation_assocs(query, :user) do
    from(
      o in query,
      left_join: u in assoc(o, :user),
      as: :user
    )
  end

  defp join_observation_assocs(query, :sample) do
    from(
      o in query,
      left_join: s in assoc(o, :sample),
      as: :sample
    )
  end

  defp maybe_populate_location(
         %Observation{country: nil, primary_subdivision: nil, secondary_subdivision: nil} =
           observation
       ) do
    observation
  end

  defp maybe_populate_location(
         %Observation{country: country, primary_subdivision: nil, secondary_subdivision: nil} =
           observation
       ) do
    %{observation | location: country.name}
  end

  defp maybe_populate_location(
         %Observation{
           country: country,
           primary_subdivision: primary_subdivision,
           secondary_subdivision: nil
         } = observation
       ) do
    %{observation | location: "#{primary_subdivision.name}, #{country.iso3166_1_alpha2}"}
  end

  defp maybe_populate_location(
         %Observation{
           country: country,
           primary_subdivision: primary_subdivision,
           secondary_subdivision: secondary_subdivision
         } = observation
       ) do
    [_, psd_abbreviation] = String.split(primary_subdivision.iso3166_2, "-")

    %{
      observation
      | location:
          "#{secondary_subdivision.name} #{secondary_subdivision.category}, #{psd_abbreviation}, #{country.iso3166_1_alpha2}"
    }
  end
end
