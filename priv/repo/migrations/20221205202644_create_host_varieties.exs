defmodule PlantAid.Repo.Migrations.CreateHostVarieties do
  use Ecto.Migration

  def change do
    create table(:host_varieties) do
      add :name, :string, null: false
      add :host_id, references(:hosts, on_delete: :delete_all)

      timestamps()
    end

    create index(:host_varieties, [:host_id])
    create unique_index(:host_varieties, [:host_id, :name])
  end
end
