defmodule PlantAid.Repo.Migrations.AddObservationImages do
  use Ecto.Migration

  def change do
    alter table(:observations) do
      add :images, :map
    end
  end
end
