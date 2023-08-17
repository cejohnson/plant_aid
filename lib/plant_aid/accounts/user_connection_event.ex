defmodule PlantAid.Accounts.UserConnectionEvent do
  use Ecto.Schema

  schema "users_connection_events" do
    field :type, Ecto.Enum, values: [http: 0, ws_connection: 1, ws_disconnection: 2]
    field :timestamp, :utc_datetime
    belongs_to :user, PlantAid.Accounts.User
  end
end
