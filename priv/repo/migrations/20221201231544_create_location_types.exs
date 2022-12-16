defmodule PlantAid.Repo.Migrations.CreateLocationTypes do
  use Ecto.Migration

  def change do
    create table(:location_types) do
      add :name, :string, null: false
      add :metadata, :map, default: %{}, null: false

      timestamps()
    end

    create unique_index(:location_types, [:name])
  end
end
