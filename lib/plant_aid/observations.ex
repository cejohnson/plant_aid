defmodule PlantAid.Observations do
  @moduledoc """
  The Observations context.
  """

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Geography.SecondarySubdivision
  alias PlantAid.Observations.Observation

  @doc """
  Returns the list of observations.

  ## Examples

      iex> list_observations()
      [%Observation{}, ...]

  """
  def list_observations do
    list_observations(%Flop{})
  end

  def list_observations(%Flop{} = flop) do
    observations =
      Observation
      |> Flop.all(flop)
      |> Repo.preload([
        :user,
        :host,
        :host_variety,
        :location_type,
        :suspected_pathology,
        :country,
        :primary_subdivision,
        secondary_subdivision: from(s in SecondarySubdivision, select: %{s | geog: nil})
      ])
      |> Enum.map(&maybe_populate_lat_long/1)
      |> Enum.map(&maybe_populate_location/1)

    meta = Flop.meta(Observation, flop)

    {observations, meta}
  end

  def list_observations(%{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, list_observations(flop)}
    end
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

  defp maybe_populate_lat_long(%Observation{position: %{coordinates: {long, lat}}} = observation) do
    %{observation | latitude: lat, longitude: long}
  end

  defp maybe_populate_lat_long(%Observation{} = observation) do
    observation
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
