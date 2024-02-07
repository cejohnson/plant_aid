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
end
