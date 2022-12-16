defmodule PlantAid.Repo.Migrations.CreatePathologies do
  use Ecto.Migration

  def change do
    create table(:pathologies) do
      add :common_name, :string, null: false
      add :scientific_name, :string

      timestamps()
    end
  end
end
