defmodule PlantAid.Diagnostics do
  import Ecto.Query, warn: false
  alias PlantAid.Repo
  alias PlantAid.Diagnostics.Diagnostic

  def list_diagnostics(observation_id) do
    from(
      d in Diagnostic,
      where: d.observation_id == ^observation_id
    )
    |> Repo.all()
  end

  def create_diagnostic(observation_id, attrs \\ %{}) do
    %Diagnostic{observation_id: observation_id}
    |> Diagnostic.changeset(attrs)
    |> Repo.insert()
  end

  def update_diagnostic(%Diagnostic{} = diagnostic, attrs) do
    diagnostic
    |> Diagnostic.changeset(attrs)
    |> Repo.update()
  end

  def delete_diagnostic(%Diagnostic{} = diagnostic) do
    Repo.delete(diagnostic)
  end

  def change_diagnostic(%Diagnostic{} = diagnostic, attrs \\ %{}) do
    Diagnostic.changeset(diagnostic, attrs)
  end

  alias PlantAid.Diagnostics.DiagnosticMethod

  @doc """
  Returns the list of diagnostic_methods.

  ## Examples

      iex> list_diagnostic_methods()
      [%DiagnosticMethod{}, ...]

  """
  def list_diagnostic_methods do
    Repo.all(DiagnosticMethod)
  end

  @doc """
  Gets a single diagnostic_method.

  Raises `Ecto.NoResultsError` if the Diagnostic method does not exist.

  ## Examples

      iex> get_diagnostic_method!(123)
      %DiagnosticMethod{}

      iex> get_diagnostic_method!(456)
      ** (Ecto.NoResultsError)

  """
  def get_diagnostic_method!(id), do: Repo.get!(DiagnosticMethod, id)

  @doc """
  Creates a diagnostic_method.

  ## Examples

      iex> create_diagnostic_method(%{field: value})
      {:ok, %DiagnosticMethod{}}

      iex> create_diagnostic_method(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_diagnostic_method(attrs \\ %{}) do
    %DiagnosticMethod{}
    |> DiagnosticMethod.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a diagnostic_method.

  ## Examples

      iex> update_diagnostic_method(diagnostic_method, %{field: new_value})
      {:ok, %DiagnosticMethod{}}

      iex> update_diagnostic_method(diagnostic_method, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_diagnostic_method(%DiagnosticMethod{} = diagnostic_method, attrs) do
    diagnostic_method
    |> DiagnosticMethod.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a diagnostic_method.

  ## Examples

      iex> delete_diagnostic_method(diagnostic_method)
      {:ok, %DiagnosticMethod{}}

      iex> delete_diagnostic_method(diagnostic_method)
      {:error, %Ecto.Changeset{}}

  """
  def delete_diagnostic_method(%DiagnosticMethod{} = diagnostic_method) do
    Repo.delete(diagnostic_method)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking diagnostic_method changes.

  ## Examples

      iex> change_diagnostic_method(diagnostic_method)
      %Ecto.Changeset{data: %DiagnosticMethod{}}

  """
  def change_diagnostic_method(%DiagnosticMethod{} = diagnostic_method, attrs \\ %{}) do
    DiagnosticMethod.changeset(diagnostic_method, attrs)
  end
end
