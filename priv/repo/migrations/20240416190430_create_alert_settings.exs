defmodule PlantAid.Repo.Migrations.CreateAlertSettings do
  use Ecto.Migration

  def change do
    create table(:alert_settings) do
      add :enabled, :boolean, default: true, null: false
      add :pathologies_selector, :string, null: false
      add :locations_selector, :string, null: false
      add :distance_meters, :float
      add :distance_unit, :string

      add :user_id, references(:users)

      timestamps()
    end

    create table(:alert_settings_pathologies, primary_key: false) do
      add :alert_setting_id, references(:alert_settings, on_delete: :delete_all)
      add :pathology_id, references(:pathologies, on_delete: :delete_all)
    end

    create table(:alert_settings_locations, primary_key: false) do
      add :alert_setting_id, references(:alert_settings, on_delete: :delete_all)
      add :location_id, references(:locations, on_delete: :delete_all)
    end
  end
end
