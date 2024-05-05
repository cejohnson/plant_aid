defmodule PlantAid.Alerts.Alert do
  @behaviour Bodyguard.Schema

  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  alias PlantAid.Accounts.User

  schema "alerts" do
    field :viewed_at, :utc_datetime

    belongs_to :user, PlantAid.Accounts.User
    belongs_to :sample, PlantAid.Observations.Sample

    many_to_many :alert_settings, PlantAid.Alerts.AlertSetting,
      join_through: "alerts_alert_settings",
      on_replace: :delete

    timestamps()
  end

  def scope(query, %User{id: user_id}, _) do
    from(row in query, where: row.user_id == ^user_id)
  end
end
