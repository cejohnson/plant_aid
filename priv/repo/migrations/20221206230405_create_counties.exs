defmodule PlantAid.Repo.Migrations.CreateCounties do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create table(:counties) do
      add :name, :string, null: false
      add :state, :string, null: false
      add :sqmi, :float, null: false
      add :geometry, :"geography(MultiPolygon, 4326)", null: false
    end

    create index(:counties, [:geometry], using: :gist)
    create unique_index(:counties, [:name, :state])
  end
end
