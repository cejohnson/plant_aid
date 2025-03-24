defmodule PlantAid.DiagnosticMethods do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias PlantAid.Repo
  alias PlantAid.Accounts.User
  alias PlantAid.DiagnosticMethods.DiagnosticMethod

  def authorize(:list_diagnostic_methods, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_diagnostic_method, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:get_diagnostic_method, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:update_diagnostic_method, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:delete_diagnostic_method, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  @doc """
  Returns the list of diagnostic_methods.

  ## Examples

      iex> list_diagnostic_methods()
      [%DiagnosticMethod{}, ...]

  """
  def list_diagnostic_methods do
    Repo.all(DiagnosticMethod)
    |> preload()
    |> Enum.map(&populate_virtual_fields/1)
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
  def get_diagnostic_method!(id) do
    Repo.get!(DiagnosticMethod, id)
    |> preload()
    |> populate_virtual_fields()
  end

  @doc """
  Creates a diagnostic_method.

  ## Examples

      iex> create_diagnostic_method(%{field: value})
      {:ok, %DiagnosticMethod{}}

      iex> create_diagnostic_method(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_diagnostic_method(user, attrs \\ %{}) do
    %DiagnosticMethod{inserted_by_id: user.id, updated_by_id: user.id}
    |> DiagnosticMethod.changeset(attrs)
    |> put_pathologies(attrs)
    |> Repo.insert()
    |> preload()
    |> populate_virtual_fields()
  end

  @doc """
  Updates a diagnostic_method.

  ## Examples

      iex> update_diagnostic_method(diagnostic_method, %{field: new_value})
      {:ok, %DiagnosticMethod{}}

      iex> update_diagnostic_method(diagnostic_method, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_diagnostic_method(user, %DiagnosticMethod{} = diagnostic_method, attrs) do
    diagnostic_method
    |> Repo.preload([:pathologies])
    |> DiagnosticMethod.changeset(attrs)
    |> IO.inspect(label: "why no delete?")
    |> Changeset.put_change(:updated_by_id, user.id)
    |> put_pathologies(attrs)
    |> Repo.update()
    |> preload()
    |> populate_virtual_fields()
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
    diagnostic_method
    |> change_diagnostic_method()
    |> Changeset.no_assoc_constraint(:diagnostic_test_results)
    |> Repo.delete()
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

  def preload({:ok, struct}) do
    {:ok, preload(struct)}
  end

  def preload({:error, _} = resp) do
    resp
  end

  def preload(diagnostic_method_or_methods) do
    Repo.preload(diagnostic_method_or_methods, [
      :inserted_by,
      :updated_by,
      pathologies: [:genotypes]
    ])
  end

  def populate_virtual_fields({:ok, struct}) do
    {:ok, populate_virtual_fields(struct)}
  end

  def populate_virtual_fields({:error, _} = resp) do
    resp
  end

  def populate_virtual_fields(%DiagnosticMethod{} = diagnostic_method) do
    diagnostic_method
    |> maybe_put_pathology_ids()
  end

  defp maybe_put_pathology_ids(%DiagnosticMethod{pathologies: pathologies} = diagnostic_method)
       when is_list(pathologies) do
    %{diagnostic_method | pathology_ids: Enum.map(pathologies, fn p -> p.id end)}
  end

  defp maybe_put_pathology_ids(%DiagnosticMethod{} = diagnostic_method) do
    diagnostic_method
  end

  defp put_pathologies(changeset, attrs) do
    # pathology_ids = Ecto.Changeset.get_field(changeset, :pathology_ids, [])
    pathology_ids = Map.get(attrs, "pathology_ids", [])

    pathologies =
      Repo.all(from p in PlantAid.Pathologies.Pathology, where: p.id in ^pathology_ids)

    Changeset.put_assoc(changeset, :pathologies, pathologies)
  end
end
