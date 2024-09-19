defmodule PlantAid.Repo.Migrations.AlterAlerts do
  use Ecto.Migration

  def change do
    drop table(:alerts_alert_settings)

    alter table(:alerts) do
      remove :sample_id
      add :alert_type, :string
      add :observation_id, references(:observations, on_delete: :delete_all)
      add :test_result_id, references(:diagnostic_test_results, on_delete: :delete_all)
      add :pathology_id, references(:pathologies, on_delete: :delete_all)
    end

    create table(:alerts_alert_subscriptions, primary_key: false) do
      add :alert_id, references(:alerts, on_delete: :delete_all)
      add :alert_subscription_id, references(:alert_subscriptions, on_delete: :delete_all)
    end
  end
end
