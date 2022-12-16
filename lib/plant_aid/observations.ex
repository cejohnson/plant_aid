defmodule PlantAid.Observations do
  @moduledoc """
  The Observations context.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS
  alias PlantAid.Repo

  alias PlantAid.Geography.County
  alias PlantAid.Observations.Observation

  @doc """
  Returns the list of observations.

  ## Examples

      iex> list_observations()
      [%Observation{}, ...]

  """
  def list_observations do
    Repo.all(Observation)
  end

  @doc """
  Gets a single observation.

  Raises `Ecto.NoResultsError` if the Observation does not exist.

  ## Examples

      iex> get_observation!(123)
      %Observation{}

      iex> get_observation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_observation!(id), do: Repo.get!(Observation, id)

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

  @doc """
  select c.id, c.name, c.state, o.suspected_pathology_id, count(o.id) as ObservationCount from counties c inner join observations o on st_contains(c.geom, o.coordinates) group by c.id, o.suspected_pathology_id;
  """
  def get_county_aggregates() do
    # IO.puts("calling get_county_aggregates")

    from(c in County,
      inner_join: o in Observation,
      on: st_covers(c.geometry, o.position),
      select: {c, count(o.id), count(o.id) / c.sqmi},
      group_by: [c.id],
      order_by: [desc: count(o.id) / c.sqmi]
    )
    |> Repo.all()
    |> Enum.map(fn {county, count, density} ->
      Map.merge(county, %{observation_count: count, density: density})
    end)
  end

  def get_county_aggregates_with_bounds() do
    # IO.puts("calling get_county_aggregates_with_bounds")

    results =
      from(c in County,
        inner_join: o in Observation,
        on: st_covers(c.geometry, o.position),
        select:
          {c, count(o.id), count(o.id) / c.sqmi,
           fragment("ST_Extent(?::geometry) OVER()::geometry AS bounds", c.geometry)},
        group_by: [c.id],
        order_by: [desc: count(o.id) / c.sqmi]
      )
      |> Repo.all()

    {_, _, _,
     %Geo.Polygon{
       coordinates: [bounds_list]
     }} = List.first(results)

    {longitudes, latitudes} = Enum.unzip(bounds_list)

    bounds = %{
      min_lon: Enum.min(longitudes),
      min_lat: Enum.min(latitudes),
      max_lon: Enum.max(longitudes),
      max_lat: Enum.max(latitudes)
    }

    lon_padding = abs(bounds.max_lon - bounds.min_lon) * 0.025
    lat_padding = abs(bounds.max_lat - bounds.min_lat) * 0.025

    padded_bounds = %{
      min_lon: bounds.min_lon - lon_padding,
      min_lat: bounds.min_lat - lat_padding,
      max_lon: bounds.max_lon + lon_padding,
      max_lat: bounds.max_lat + lat_padding
    }

    counties =
      results
      |> Enum.map(fn {county, count, density, _} ->
        Map.merge(county, %{observation_count: count, density: density})
      end)

    {counties, padded_bounds}
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
