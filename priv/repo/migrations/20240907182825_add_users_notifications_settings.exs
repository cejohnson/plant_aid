defmodule PlantAid.Repo.Migrations.AddUsersNotificationsSettings do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notifications_settings, :map
    end
  end
end
