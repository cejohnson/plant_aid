defmodule PlantAid.Genomics do
  @moduledoc """
  The Genotypes context.
  """

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Genomics.Genotype

  @doc """
  Returns the list of genotypes.

  ## Examples

      iex> list_genotypes()
      [%Genotype{}, ...]

  """
  def list_genotypes do
    Repo.all(Genotype)
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
  def create_genotype(attrs \\ %{}) do
    %Genotype{}
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
