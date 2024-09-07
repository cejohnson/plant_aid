defmodule PlantAid.Repo.Migrations.CreateDiagnosticMethods do
  use Ecto.Migration

  def change do
    create table(:diagnostic_methods) do
      add :name, :string
      add :description, :text
      add :fields, :map

      add :inserted_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:diagnostic_methods, [:name])

    create table(:diagnostic_methods_pathologies, primary_key: false) do
      add :diagnostic_method_id, references(:diagnostic_methods, on_delete: :delete_all)
      add :pathology_id, references(:pathologies, on_delete: :restrict)
    end
  end
end
