defmodule PlantAid.Observations do
  @moduledoc """
  The Observations context.
  """

  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Geography.SecondarySubdivision
  alias PlantAid.Observations.Observation

  def authorize(:list_user_observations, %User{}, _), do: :ok

  def authorize(:list_observations, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:get_observation, %User{id: user_id}, %Observation{user_id: user_id}), do: :ok

  def authorize(:get_observation, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_observation, %User{}, _), do: :ok

  def authorize(:update_observation, %User{id: user_id}, %Observation{user_id: user_id}), do: :ok

  def authorize(:update_observation, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_observation, %User{id: user_id}, %Observation{user_id: user_id}), do: :ok

  def authorize(:delete_observation, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(_, _, _), do: false

  def list_user_observations(%User{} = user) do
    list_user_observations(user, %Flop{})
  end

  def list_user_observations(%User{} = user, %Flop{} = flop) do
    Observation
    |> Bodyguard.scope(user)
    |> list_observations(flop)
  end

  def list_user_observations(%User{} = user, %{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, list_user_observations(user, flop)}
    end
  end

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
    list_observations(from(o in Observation), flop)
  end

  def list_observations(%{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, list_observations(flop)}
    end
  end

  def list_observations(%Ecto.Query{} = query, %Flop{} = flop) do
    observations =
      query
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

    meta = Flop.meta(query, flop)

    {observations, meta}
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
  def create_observation(%User{} = user, attrs \\ %{}, after_save \\ &{:ok, &1}) do
    %Observation{}
    |> Observation.changeset(attrs)
    |> Observation.put_user(user)
    |> Repo.insert()
    |> after_save(after_save)
  end

  @doc """
  Updates a observation.

  ## Examples

      iex> update_observation(observation, %{field: new_value})
      {:ok, %Observation{}}

      iex> update_observation(observation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_observation(%Observation{} = observation, attrs, after_save \\ &{:ok, &1}) do
    observation
    |> Observation.changeset(attrs)
    |> Repo.update()
    |> after_save(after_save)
  end

  defp after_save({:ok, observation}, func) do
    {:ok, _observation} = func.(observation)
  end

  defp after_save(error, _func), do: error

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
