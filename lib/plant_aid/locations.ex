defmodule PlantAid.Locations do
  @moduledoc """
  The Locations context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Locations.Location

  def authorize(:list_locations, %User{}, _), do: :ok

  def authorize(:list_all_locations, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:get_location, %User{id: user_id}, %Location{user_id: user_id}), do: :ok

  def authorize(:get_location, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_location, %User{}, _), do: :ok

  def authorize(:update_location, %User{id: user_id}, %Location{user_id: user_id}), do: :ok

  def authorize(:update_location, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_location, %User{id: user_id}, %Location{user_id: user_id}) do
    :ok
  end

  def authorize(:delete_location, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(_, _, _), do: false

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations()
      [%Location{}, ...]

  """
  def list_locations(%User{} = user) do
    Location
    |> Bodyguard.scope(user)
    |> Repo.all()
    |> Enum.map(&maybe_populate_lat_long/1)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(123)
      %Location{}

      iex> get_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(id), do: Repo.get!(Location, id) |> maybe_populate_lat_long()

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(%{field: value})
      {:ok, %Location{}}

      iex> create_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(user, attrs \\ %{}) do
    %Location{user: user}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location(location)
      {:ok, %Location{}}

      iex> delete_location(location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs)
  end

  defp maybe_populate_lat_long(%Location{position: %{coordinates: {long, lat}}} = location) do
    %{location | latitude: lat, longitude: long}
  end

  defp maybe_populate_lat_long(%Location{} = location) do
    location
  end
end
