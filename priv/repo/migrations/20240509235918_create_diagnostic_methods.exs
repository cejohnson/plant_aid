defmodule PlantAid.Repo.Migrations.CreateDiagnosticMethods do
  use Ecto.Migration

  def change do
    create table(:diagnostic_methods) do
      add :name, :string
      add :description, :text
      add :fields, :map, default: %{}, null: false

      add :inserted_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end
  end
end
