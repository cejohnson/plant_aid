defmodule PlantAid.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string
      add :position, :"geography(Point, 4326)"
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:locations, [:user_id])
  end
end
