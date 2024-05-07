defmodule PlantAid.Repo.Migrations.CreateSamples do
  use Ecto.Migration

  def change do
    create table(:samples) do
      add :result, :string
      add :confidence, :float
      add :comments, :string
      add :data, :map
      add :metadata, :map

      add :observation_id, references(:observations, on_delete: :nothing), null: false
      add :pathology_id, references(:pathologies, on_delete: :nothing)
      add :genotype_id, references(:genotypes, on_delete: :nothing)

      timestamps()
    end

    create index(:samples, [:observation_id])
    create index(:samples, [:pathology_id])
    create index(:samples, [:genotype_id])
  end
end
