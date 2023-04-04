defmodule PlantAid.Repo.Migrations.CreateCounties do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create table(:countries) do
      add :name, :string
      add :iso3166_1_alpha2, :string, size: 2
      add :iso3166_1_alpha3, :string, size: 3
      add :iso3166_1_numeric, :string, size: 3
      add :metadata, :map, default: %{}, null: false
    end

    create table(:primary_subdivisions) do
      add :name, :string
      add :category, :string
      add :iso3166_2, :string, size: 6
      add :metadata, :map, default: %{}, null: false
      add :country_id, references(:countries)
    end

    create table(:secondary_subdivisions) do
      add :name, :string
      add :category, :string
      add :geog, :"geography(MultiPolygon, 4326)", null: false
      add :metadata, :map, default: %{}, null: false
      add :primary_subdivision_id, references(:primary_subdivisions)
    end

    create index(:secondary_subdivisions, [:geog], using: :gist)
  end
end
