defmodule PlantAid.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :viewed_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)
      add :sample_id, references(:samples, on_delete: :delete_all)

      timestamps()
    end

    create table(:alerts_alert_settings, primary_key: false) do
      add :alert_id, references(:alerts, on_delete: :delete_all)
      add :alert_setting_id, references(:alert_settings, on_delete: :delete_all)
    end

    create index(:alerts, [:user_id])
  end
end
