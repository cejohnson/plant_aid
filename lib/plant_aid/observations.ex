defmodule PlantAid.Observations do
  @moduledoc """
  The Observations context.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS
  alias PlantAid.Geography.SecondarySubdivision
  alias PlantAid.Repo

  alias PlantAid.Geography.County
  alias PlantAid.Geography.County2
  alias PlantAid.Observations.Observation

  alias PlantAid.Geography.{
    Country
  }

  @doc """
  Returns the list of observations.

  ## Examples

      iex> list_observations()
      [%Observation{}, ...]

  """
  def list_observations do
    Repo.all(Observation)
    |> Repo.preload([
      :user,
      :host,
      :host_variety,
      :location_type,
      :suspected_pathology,
      :country,
      :primary_subdivision,
      :secondary_subdivision
    ])
    |> Enum.map(&maybe_populate_lat_long/1)
    |> Enum.map(&maybe_populate_location/1)
  end

  def list_observations(params) do
    flop = Flop.validate(params, for: Observation)
    IO.inspect(flop, label: "flop")

    case Flop.validate_and_run(Observation, params, for: Observation) do
      {:ok, {observations, meta}} ->
        observations =
          observations
          |> Repo.preload([
            :user,
            :host,
            :host_variety,
            :location_type,
            :suspected_pathology,
            :country,
            :primary_subdivision,
            :secondary_subdivision
          ])
          |> Enum.map(&maybe_populate_lat_long/1)
          |> Enum.map(&maybe_populate_location/1)

        {:ok, {observations, meta}}

      error ->
        IO.inspect(error)
        error
    end
  end

  def aggregate_observations(params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      flop = %Flop{filters: flop.filters}

      from(
        o in Observation,
        inner_join: ssd in SecondarySubdivision,
        on: ssd.id == o.secondary_subdivision_id,
        group_by: ssd.id,
        select: {ssd, count(o.id)}
      )
      |> Flop.all(flop)
      |> Enum.map(fn {ssd, count} ->
        Map.merge(ssd, %{observation_count: count})
      end)
      |> Repo.preload(primary_subdivision: [preload: :country])
    end

    # Observation
    # |> aggregate_by(params)
    # |> Flop.validate_and_run(params, for: Observation)
  end

  # defp aggregate_by(query, _params), do
  #   from(o in query,
  #   select:
  #   )
  # end

  @doc """
  Gets a single observation.

  Raises `Ecto.NoResultsError` if the Observation does not exist.

  ## Examples

      iex> get_observation!(123)
      %Observation{}

      iex> get_observation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_observation!(id) do
    Repo.get!(Observation, id)
    |> Repo.preload([
      :user,
      :host,
      :host_variety,
      :location_type,
      :suspected_pathology,
      :country,
      :primary_subdivision,
      :secondary_subdivision
    ])
    |> maybe_populate_lat_long()
    |> maybe_populate_location()
  end

  @doc """
  Creates a observation.

  ## Examples

      iex> create_observation(%{field: value})
      {:ok, %Observation{}}

      iex> create_observation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_observation(attrs \\ %{}) do
    %Observation{}
    |> Observation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a observation.

  ## Examples

      iex> update_observation(observation, %{field: new_value})
      {:ok, %Observation{}}

      iex> update_observation(observation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_observation(%Observation{} = observation, attrs) do
    observation
    |> Observation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a observation.

  ## Examples

      iex> delete_observation(observation)
      {:ok, %Observation{}}

      iex> delete_observation(observation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_observation(%Observation{} = observation) do
    Repo.delete(observation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking observation changes.

  ## Examples

      iex> change_observation(observation)
      %Ecto.Changeset{data: %Observation{}}

  """
  def change_observation(%Observation{} = observation, attrs \\ %{}) do
    Observation.changeset(observation, attrs)
  end

  defp maybe_populate_lat_long(%Observation{position: nil} = observation) do
    observation
  end

  defp maybe_populate_lat_long(%Observation{position: position} = observation) do
    {long, lat} = position.coordinates
    %{observation | latitude: lat, longitude: long}
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

  @doc """
  select c.id, c.name, c.state, o.suspected_pathology_id, count(o.id) as ObservationCount from counties c inner join observations o on st_contains(c.geom, o.coordinates) group by c.id, o.suspected_pathology_id;
  """
  def get_county_aggregates() do
    # IO.puts("calling get_county_aggregates")

    from(c in County2,
      inner_join: o in Observation,
      on: st_covers(c.geom, o.position),
      select: {%{c | id: nil}, count(o.id)},
      group_by: [c.gid],
      order_by: [desc: count(o.id)]
    )
    |> Repo.all()
    |> Enum.map(fn {county, count} ->
      Map.merge(county, %{observation_count: count})
    end)
  end

  def get_county_aggregates_with_bounds() do
    # IO.puts("calling get_county_aggregates_with_bounds")

    # SELECT c0."id", c0."geometry", c0."name", c0."state", c0."sqmi", count(o1."id"), count(o1."id") / c0."sqmi", ST_Extent(c0."geometry"::geometry) OVER()::geometry AS bounds FROM "counties" AS c0 INNER JOIN "observations" AS o1 ON ST_Covers(c0."geometry",o1."position") GROUP BY c0."id" ORDER BY count(o1."id") / c0."sqmi" DESC
    # results =
    #   from(c in County,
    #     inner_join: o in Observation,
    #     on: st_covers(c.geometry, o.position),
    #     select:
    #       {c, count(o.id), count(o.id) / c.sqmi,
    #        fragment("ST_Extent(?::geometry) OVER()::geometry AS bounds", c.geometry)},
    #     group_by: [c.id],
    #     order_by: [desc: count(o.id) / c.sqmi]
    #   )
    #   |> Repo.all()

    # SELECT c1."id", c1."geometry", c1."name", c1."state", c1."sqmi", count(o0."id"), count(o0."id") / c1."sqmi", ST_Extent(c1."geometry"::geometry) OVER()::geometry AS bounds FROM "observations" AS o0 LEFT OUTER JOIN "counties" AS c1 ON ST_Covers(c1."geometry",o0."position") GROUP BY c1."id" ORDER BY count(o0."id") / c1."sqmi" DESC
    # results =
    #   from(o in Observation,
    #     inner_join: c in County,
    #     on: st_covers(c.geometry, o.position),
    #     select:
    #       {c, count(o.id), count(o.id) / c.sqmi,
    #        fragment("ST_Extent(?::geometry) OVER()::geometry AS bounds", c.geometry)},
    #     group_by: [c.id],
    #     order_by: [desc: count(o.id) / c.sqmi]
    #   )
    #   |> Repo.all()

    # results =
    #   from(c in County,
    #     select:
    #       {c, nil, nil, fragment("ST_Extent(?::geometry) OVER()::geometry AS bounds", c.geometry)}
    #   )
    #   |> Repo.all()

    results = from(c in County2, select: {%{c | id: nil}}) |> Repo.all()

    # results =
    #   from(c in County2,
    #     select:
    #       {%{c | id: nil}, nil, nil, fragment("ST_Extent(?) OVER()::geometry AS bounds", c.geom)}
    #   )
    #   |> Repo.all()

    IO.inspect(length(results))
    IO.inspect(List.first(results))

    # {_, _, _,
    #  %Geo.Polygon{
    #    coordinates: [bounds_list]
    #  }} = List.first(results)

    # {longitudes, latitudes} = Enum.unzip(bounds_list)

    # bounds = %{
    #   min_lon: Enum.min(longitudes),
    #   min_lat: Enum.min(latitudes),
    #   max_lon: Enum.max(longitudes),
    #   max_lat: Enum.max(latitudes)
    # }

    # lon_padding = abs(bounds.max_lon - bounds.min_lon) * 0.025
    # lat_padding = abs(bounds.max_lat - bounds.min_lat) * 0.025

    # padded_bounds = %{
    #   min_lon: bounds.min_lon - lon_padding,
    #   min_lat: bounds.min_lat - lat_padding,
    #   max_lon: bounds.max_lon + lon_padding,
    #   max_lat: bounds.max_lat + lat_padding
    # }

    # counties =
    #   results
    #   |> Enum.map(fn {county, count, density, _} ->
    #     Map.merge(county, %{observation_count: count, density: density})
    #   end)

    counties =
      results
      |> Enum.map(fn {county} ->
        county
      end)

    # {counties, padded_bounds}
    {counties,
     %{
       min_lon: -179.231086,
       min_lat: -14.601813,
       max_lon: 179.859681,
       max_lat: 71.439786
     }}
  end

  def bounding_box() do
    IO.puts("calling bounding_box")

    # bb =
    #   from(c in County,
    #     inner_join: o in Observation,
    #     on: st_covers(c.geometry, o.position),
    #     select: {fragment("ST_Extent(?::geometry)::geometry", c.geometry)}
    #   )
    #   |> Repo.all()

    # IO.inspect(bb, label: "bb")
    # bb

    [{%Geo.Polygon{coordinates: [coordinate_list]}}] =
      from(c in County,
        inner_join: o in Observation,
        on: st_covers(c.geometry, o.position),
        select: {fragment("ST_Extent(?::geometry)::geometry", c.geometry)}
      )
      |> Repo.all()

    {longitudes, latitudes} = Enum.unzip(coordinate_list)

    %{
      min_lon: Enum.min(longitudes),
      min_lat: Enum.min(latitudes),
      max_lon: Enum.max(longitudes),
      max_lat: Enum.max(latitudes)
    }
  end
end
