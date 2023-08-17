defmodule PlantAid.Repo.Migrations.CreateUsersConnectionEvents do
  use Ecto.Migration

  def change do
    create table(:users_connection_events) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type, :integer
      add :timestamp, :utc_datetime
    end

    create index(:users_connection_events, [:user_id])
  end
end
