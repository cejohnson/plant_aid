defmodule PlantAid.Repo.Migrations.AddDiagnosticMethodsPathologies do
  use Ecto.Migration

  def change do
    create unique_index(:diagnostic_methods, [:name])

    create table(:diagnostic_methods_pathologies, primary_key: false) do
      add :diagnostic_method_id, references(:diagnostic_methods, on_delete: :delete_all)
      add :pathology_id, references(:pathologies, on_delete: :restrict)
    end
  end
end
