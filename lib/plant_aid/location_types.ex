defmodule PlantAid.LocationTypes do
  @moduledoc """
  The LocationTypes context.
  """

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.LocationTypes.LocationType

  @doc """
  Returns the list of location_types.

  ## Examples

      iex> list_location_types()
      [%LocationType{}, ...]

  """
  def list_location_types do
    Repo.all(LocationType)
  end

  @doc """
  Gets a single location_type.

  Raises `Ecto.NoResultsError` if the Location type does not exist.

  ## Examples

      iex> get_location_type!(123)
      %LocationType{}

      iex> get_location_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location_type!(id), do: Repo.get!(LocationType, id)

  @doc """
  Creates a location_type.

  ## Examples

      iex> create_location_type(%{field: value})
      {:ok, %LocationType{}}

      iex> create_location_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location_type(attrs \\ %{}) do
    %LocationType{}
    |> LocationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location_type.

  ## Examples

      iex> update_location_type(location_type, %{field: new_value})
      {:ok, %LocationType{}}

      iex> update_location_type(location_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location_type(%LocationType{} = location_type, attrs) do
    location_type
    |> LocationType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location_type.

  ## Examples

      iex> delete_location_type(location_type)
      {:ok, %LocationType{}}

      iex> delete_location_type(location_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location_type(%LocationType{} = location_type) do
    Repo.delete(location_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location_type changes.

  ## Examples

      iex> change_location_type(location_type)
      %Ecto.Changeset{data: %LocationType{}}

  """
  def change_location_type(%LocationType{} = location_type, attrs \\ %{}) do
    LocationType.changeset(location_type, attrs)
  end
end
