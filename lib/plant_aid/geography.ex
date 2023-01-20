defmodule PlantAid.Geography do
  @moduledoc """
  The Geography context.
  """

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Geography.{
    County,
    Country,
    PrimarySubdivision,
    SecondarySubdivision
  }

  alias PlantAid.Observations.Observation

  def list_countries do
    Repo.all(Country)
  end

  def list_countries_for_filtering do
    Repo.all(Country)
    |> Repo.preload(
      primary_subdivisions: [
        secondary_subdivisions:
          from(s in SecondarySubdivision,
            select: %SecondarySubdivision{id: s.id, name: s.name, category: s.category}
          )
      ]
    )
  end

  def list_primary_subdivisions do
    Repo.all(PrimarySubdivision)
  end

  def list_secondary_subdivisions do
    from(ssd in SecondarySubdivision,
      left_join: psd in PrimarySubdivision,
      on: ssd.primary_subdivision_id == psd.id,
      left_join: c in Country,
      on: psd.country_id == c.id,
      preload: [primary_subdivision: psd, country: c]
    )
    |> Repo.all()

    # |> Repo.preload([:primary_subdivision])
  end

  def list_secondary_subdivisions(params, opts \\ []) do
    observation_count_query =
      from(
        o in Observation,
        where: parent_as(:secondary_subdivision).id == o.secondary_subdivision_id,
        select: %{count: count(o.id)}
      )

    query =
      from(
        ssd in SecondarySubdivision,
        as: :secondary_subdivision,
        join: psd in assoc(ssd, :primary_subdivision),
        as: :primary_subdivision,
        join: c in assoc(psd, :country),
        as: :country,
        left_lateral_join: o in subquery(observation_count_query),
        as: :observation_count,
        select: %{ssd | observation_count: o.count},
        preload: [primary_subdivision: {psd, country: c}]
      )

    paginate? = Keyword.get(opts, :paginate, true)

    if paginate? do
      Flop.validate_and_run(query, params, for: SecondarySubdivision)
    else
      # flop = %Flop{filters: flop.filters}
      # Flop.validate_and_run(query, params, for: SecondarySubdivision)
      with {:ok, flop} <- Flop.validate(params, for: SecondarySubdivision) do
        IO.inspect(flop, label: "flop")
        # flop = %Flop{filters: flop.filters}
        flop = %{
          flop
          | limit: nil,
            page: nil,
            page_size: nil,
            order_by: nil,
            order_directions: nil
        }

        IO.inspect(flop, label: "flop2")
        Flop.run(query, flop, for: SecondarySubdivision)
        # Flop.all(query, flop)
      end
    end
  end

  @doc """
  Returns the list of counties.

  ## Examples

      iex> list_counties()
      [%County{}, ...]

  """
  def list_counties do
    Repo.all(County)
  end

  @doc """
  Gets a single county.

  Raises `Ecto.NoResultsError` if the County does not exist.

  ## Examples

      iex> get_county!(123)
      %County{}

      iex> get_county!(456)
      ** (Ecto.NoResultsError)

  """
  def get_county!(id), do: Repo.get!(County, id)

  @doc """
  Creates a county.

  ## Examples

      iex> create_county(%{field: value})
      {:ok, %County{}}

      iex> create_county(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_county(attrs \\ %{}) do
    %County{}
    |> County.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a county.

  ## Examples

      iex> update_county(county, %{field: new_value})
      {:ok, %County{}}

      iex> update_county(county, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_county(%County{} = county, attrs) do
    county
    |> County.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a county.

  ## Examples

      iex> delete_county(county)
      {:ok, %County{}}

      iex> delete_county(county)
      {:error, %Ecto.Changeset{}}

  """
  def delete_county(%County{} = county) do
    Repo.delete(county)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking county changes.

  ## Examples

      iex> change_county(county)
      %Ecto.Changeset{data: %County{}}

  """
  def change_county(%County{} = county, attrs \\ %{}) do
    County.changeset(county, attrs)
  end
end
