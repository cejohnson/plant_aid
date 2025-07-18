defmodule PlantAid.Repo.Migrations.AddObservationLocationDescription do
  use Ecto.Migration

  def change do
    alter table(:observations) do
      add :location_details, :string
    end
  end
end
