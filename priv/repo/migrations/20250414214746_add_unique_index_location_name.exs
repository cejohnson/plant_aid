defmodule PlantAid.Repo.Migrations.AddUniqueIndexLocationName do
  use Ecto.Migration

  def change do
    create unique_index(:locations, [:name, :user_id])
  end
end
