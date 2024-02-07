defmodule PlantAid.Repo.Migrations.AlterGenotypes do
  use Ecto.Migration

  def change do
    alter table(:genotypes) do
      remove :genotype, :string
      remove :mating_type, :string
      remove :gpi, :string
      remove :pep, :string
      remove :mef, :string
      remove :mtdna, :string
      remove :rg57_band_num, :string
      remove :rg57, :string
      remove :pi02, :string
      remove :pi89, :string
      remove :pi4b, :string
      remove :pig11, :string
      remove :pi04, :string
      remove :pi70, :string
      remove :pi56, :string
      remove :pi63, :string
      remove :d13, :string
      remove :pi16, :string
      remove :pi33, :string

      add :pathology_id, references(:pathologies, on_delete: :nothing), null: false
      add :name, :string
    end
  end
end
