defmodule PlantAid.Pathologies do
  @moduledoc """
  The Pathologies context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Pathologies.Pathology
  alias PlantAid.Pathologies.Genotype

  def authorize(:list_pathologies, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:create_pathology, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:get_pathology, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:update_pathology, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_pathology, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  @doc """
  Returns the list of pathologies.

  ## Examples

      iex> list_pathologies()
      [%Pathology{}, ...]

  """
  def list_pathologies do
    Repo.all(Pathology)
  end

  @doc """
  Gets a single pathology.

  Raises `Ecto.NoResultsError` if the Pathology does not exist.

  ## Examples

      iex> get_pathology!(123)
      %Pathology{}

      iex> get_pathology!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pathology!(id) do
    Repo.get!(Pathology, id)
    |> Repo.preload([:genotypes])
  end

  @doc """
  Creates a pathology.

  ## Examples

      iex> create_pathology(%{field: value})
      {:ok, %Pathology{}}

      iex> create_pathology(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pathology(attrs \\ %{}) do
    %Pathology{}
    |> Pathology.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pathology.

  ## Examples

      iex> update_pathology(pathology, %{field: new_value})
      {:ok, %Pathology{}}

      iex> update_pathology(pathology, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pathology(%Pathology{} = pathology, attrs) do
    pathology
    |> Pathology.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pathology.

  ## Examples

      iex> delete_pathology(pathology)
      {:ok, %Pathology{}}

      iex> delete_pathology(pathology)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pathology(%Pathology{} = pathology) do
    Repo.delete(pathology)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pathology changes.

  ## Examples

      iex> change_pathology(pathology)
      %Ecto.Changeset{data: %Pathology{}}

  """
  def change_pathology(%Pathology{} = pathology, attrs \\ %{}) do
    Pathology.changeset(pathology, attrs)
  end

  def list_genotypes(pathology_id) do
    from(g in Genotype, where: g.pathology_id == ^pathology_id)
    |> Repo.all()
  end

  @doc """
  Gets a single genotype.

  Raises `Ecto.NoResultsError` if the Genotype does not exist.

  ## Examples

      iex> get_genotype!(123)
      %Genotype{}

      iex> get_genotype!(456)
      ** (Ecto.NoResultsError)

  """
  def get_genotype!(id), do: Repo.get!(Genotype, id)

  @doc """
  Creates a genotype.

  ## Examples

      iex> create_genotype(%{field: value})
      {:ok, %Genotype{}}

      iex> create_genotype(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_genotype(pathology_id, attrs \\ %{}) do
    %Genotype{pathology_id: pathology_id}
    |> Genotype.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a genotype.

  ## Examples

      iex> update_genotype(genotype, %{field: new_value})
      {:ok, %Genotype{}}

      iex> update_genotype(genotype, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_genotype(%Genotype{} = genotype, attrs) do
    genotype
    |> Genotype.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a genotype.

  ## Examples

      iex> delete_genotype(genotype)
      {:ok, %Genotype{}}

      iex> delete_genotype(genotype)
      {:error, %Ecto.Changeset{}}

  """
  def delete_genotype(%Genotype{} = genotype) do
    Repo.delete(genotype)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking genotype changes.

  ## Examples

      iex> change_genotype(genotype)
      %Ecto.Changeset{data: %Genotype{}}

  """
  def change_genotype(%Genotype{} = genotype, attrs \\ %{}) do
    Genotype.changeset(genotype, attrs)
  end
end
