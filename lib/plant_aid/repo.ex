defmodule PlantAid.Repo do
  use Ecto.Repo,
    otp_app: :plant_aid,
    adapter: Ecto.Adapters.Postgres
end
