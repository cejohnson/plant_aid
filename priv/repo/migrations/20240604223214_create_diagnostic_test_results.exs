defmodule PlantAid.Repo.Migrations.CreateDiagnosticTestResults do
  use Ecto.Migration

  def change do
    create table(:diagnostic_test_results) do
      add :fields, :map
      add :metadata, :map
      add :comments, :string
      add :observation_id, references(:observations, on_delete: :nilify_all)
      add :diagnostic_method_id, references(:diagnostic_methods, on_delete: :restrict)

      add :inserted_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:diagnostic_test_results, [:observation_id])
    create index(:diagnostic_test_results, [:diagnostic_method_id])

    create table(:diagnostic_test_pathology_results) do
      add :result, :string
      add :fields, :map

      add :diagnostic_test_result_id,
          references(:diagnostic_test_results, on_delete: :delete_all)

      add :pathology_id, references(:pathologies, on_delete: :restrict)
      add :genotype_id, references(:genotypes, on_delete: :restrict)

      timestamps()
    end

    create unique_index(:diagnostic_test_pathology_results, [
             :diagnostic_test_result_id,
             :pathology_id
           ])
  end
end
