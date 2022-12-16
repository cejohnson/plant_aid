defmodule PlantAid.Repo.Migrations.CreateGenotypes do
  use Ecto.Migration

  def change do
    create table(:genotypes) do
      add :genotype, :string
      add :mating_type, :string
      add :gpi, :string
      add :pep, :string
      add :mef, :string
      add :mtdna, :string
      add :rg57_band_num, :string
      add :rg57, :string
      add :pi02, :string
      add :pi89, :string
      add :pi4b, :string
      add :pig11, :string
      add :pi04, :string
      add :pi70, :string
      add :pi56, :string
      add :pi63, :string
      add :d13, :string
      add :pi16, :string
      add :pi33, :string

      timestamps()
    end
  end
end
