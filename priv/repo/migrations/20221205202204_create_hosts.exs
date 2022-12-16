defmodule PlantAid.Repo.Migrations.CreateHosts do
  use Ecto.Migration

  def change do
    create table(:hosts) do
      add :common_name, :string, null: false
      add :scientific_name, :string
      add :metadata, :map, default: %{}, null: false

      timestamps()
    end

    create unique_index(:hosts, [:common_name, :scientific_name])
  end
end
