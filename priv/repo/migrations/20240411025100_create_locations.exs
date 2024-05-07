defmodule PlantAid.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string, null: false
      add :position, :"geography(Point, 4326)"
      add :user_id, references(:users, on_delete: :delete_all)
      add :location_type_id, references(:location_types)

      timestamps()
    end

    create index(:locations, [:user_id])
    create index(:locations, [:position], using: :gist)
  end
end
