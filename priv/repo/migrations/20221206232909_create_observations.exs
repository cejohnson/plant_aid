defmodule PlantAid.Repo.Migrations.CreateObservations do
  use Ecto.Migration

  def change do
    create table(:observations) do
      add :status, :string
      add :observation_date, :date
      add :position, :"geography(Point, 4326)"
      add :organic, :boolean, default: false, null: false
      add :control_method, :text
      add :host_other, :string
      add :notes, :text
      add :image_urls, {:array, :string}, default: [], null: false
      add :metadata, :map, default: %{}, null: false

      add :user_id, references(:users, on_delete: :nothing)
      add :location_type_id, references(:location_types, on_delete: :nothing)
      add :suspected_pathology_id, references(:pathologies, on_delete: :nothing)
      add :host_id, references(:hosts, on_delete: :nothing)
      add :host_variety_id, references(:host_varieties, on_delete: :nothing)

      timestamps()
    end

    create index(:observations, [:user_id])
    create index(:observations, [:location_type_id])
    create index(:observations, [:suspected_pathology_id])
    create index(:observations, [:host_id])
    create index(:observations, [:host_variety_id])
    create index(:observations, [:position], using: :gist)
  end
end
