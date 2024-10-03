defmodule PlantAid.Alerts.Alert do
  @behaviour Bodyguard.Schema

  use Ecto.Schema
  import Ecto.Query, only: [from: 2]

  alias PlantAid.Accounts.User

  @timestamps_opts [type: :utc_datetime]

  @derive {
    Flop.Schema,
    filterable: [
      :inserted_at,
      :viewed_at,
      :alert_type
    ],
    sortable: [
      :inserted_at
    ],
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc_nulls_last]
    }
  }

  schema "alerts" do
    field :viewed_at, :utc_datetime
    field :alert_type, Ecto.Enum, values: [:disease_reported, :disease_confirmed]

    belongs_to :user, User
    belongs_to :pathology, PlantAid.Pathologies.Pathology
    belongs_to :observation, PlantAid.Observations.Observation
    belongs_to :test_result, PlantAid.DiagnosticTests.TestResult

    many_to_many :alert_subscriptions, PlantAid.Alerts.AlertSubscription,
      join_through: "alerts_alert_subscriptions",
      on_replace: :delete

    timestamps()
  end

  def scope(query, %User{id: user_id}, _) do
    from(row in query, where: row.user_id == ^user_id)
  end
end
