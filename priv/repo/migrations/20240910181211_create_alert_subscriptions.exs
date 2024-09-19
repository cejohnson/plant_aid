defmodule PlantAid.Repo.Migrations.CreateAlertSubscriptions do
  use Ecto.Migration

  def change do
    create table(:alert_subscriptions) do
      add :enabled, :boolean, default: true, null: false
      add :description, :string
      add :events_selector, :string, null: false
      add :pathologies_selector, :string, null: false
      add :geographical_selector, :string, null: false
      add :locations_selector, :string
      add :distance_meters, :float
      add :distance_unit, :string

      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create table(:alert_subscriptions_pathologies, primary_key: false) do
      add :alert_subscription_id, references(:alert_subscriptions, on_delete: :delete_all)
      add :pathology_id, references(:pathologies, on_delete: :delete_all)
    end

    create table(:alert_subscriptions_locations, primary_key: false) do
      add :alert_subscription_id, references(:alert_subscriptions, on_delete: :delete_all)
      add :location_id, references(:locations, on_delete: :delete_all)
    end

    create table(:alert_subscriptions_countries, primary_key: false) do
      add :alert_subscription_id, references(:alert_subscriptions, on_delete: :delete_all)
      add :country_id, references(:countries, on_delete: :delete_all)
    end

    create table(:alert_subscriptions_primary_subdivisions, primary_key: false) do
      add :alert_subscription_id, references(:alert_subscriptions, on_delete: :delete_all)
      add :primary_subdivision_id, references(:primary_subdivisions, on_delete: :delete_all)
    end

    create table(:alert_subscriptions_secondary_subdivisions, primary_key: false) do
      add :alert_subscription_id, references(:alert_subscriptions, on_delete: :delete_all)
      add :secondary_subdivision_id, references(:secondary_subdivisions, on_delete: :delete_all)
    end
  end
end
