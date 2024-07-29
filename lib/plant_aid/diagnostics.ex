defmodule PlantAid.Diagnostics do
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias PlantAid.Repo
  alias PlantAid.Accounts.User
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

  # alias PlantAid.Diagnostics.DiagnosticMethod

  # alias PlantAid.Diagnostics.DiagnosticTestResult

  @doc """
  Returns the list of diagnostic_test_results.

  ## Examples

      iex> list_diagnostic_test_results()
      [%DiagnosticTestResult{}, ...]

  """
  # def list_diagnostic_test_results do
  #   Repo.all(DiagnosticTestResult)
  # end

  # @doc """
  # Gets a single diagnostic_test_result.

  # Raises `Ecto.NoResultsError` if the Diagnostic test result does not exist.

  # ## Examples

  #     iex> get_diagnostic_test_result!(123)
  #     %DiagnosticTestResult{}

  #     iex> get_diagnostic_test_result!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # def get_diagnostic_test_result!(id), do: Repo.get!(DiagnosticTestResult, id)

  # @doc """
  # Creates a diagnostic_test_result.

  # ## Examples

  #     iex> create_diagnostic_test_result(%{field: value})
  #     {:ok, %DiagnosticTestResult{}}

  #     iex> create_diagnostic_test_result(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def create_diagnostic_test_result(attrs \\ %{}) do
  #   %DiagnosticTestResult{}
  #   |> DiagnosticTestResult.changeset(attrs)
  #   |> Repo.insert()
  # end

  # @doc """
  # Updates a diagnostic_test_result.

  # ## Examples

  #     iex> update_diagnostic_test_result(diagnostic_test_result, %{field: new_value})
  #     {:ok, %DiagnosticTestResult{}}

  #     iex> update_diagnostic_test_result(diagnostic_test_result, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_diagnostic_test_result(%DiagnosticTestResult{} = diagnostic_test_result, attrs) do
  #   diagnostic_test_result
  #   |> DiagnosticTestResult.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a diagnostic_test_result.

  # ## Examples

  #     iex> delete_diagnostic_test_result(diagnostic_test_result)
  #     {:ok, %DiagnosticTestResult{}}

  #     iex> delete_diagnostic_test_result(diagnostic_test_result)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_diagnostic_test_result(%DiagnosticTestResult{} = diagnostic_test_result) do
  #   Repo.delete(diagnostic_test_result)
  # end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for tracking diagnostic_test_result changes.

  # ## Examples

  #     iex> change_diagnostic_test_result(diagnostic_test_result)
  #     %Ecto.Changeset{data: %DiagnosticTestResult{}}

  # """
  # def change_diagnostic_test_result(
  #       %DiagnosticTestResult{} = diagnostic_test_result,
  #       attrs \\ %{}
  #     ) do
  #   DiagnosticTestResult.changeset(diagnostic_test_result, attrs)
  # end
end
