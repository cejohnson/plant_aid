defmodule PlantAid.Hosts.Host do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "hosts" do
    field :common_name, :string
    field :scientific_name, :string
    field :metadata, :map

    has_many :varieties, PlantAid.Hosts.HostVariety

    timestamps()
  end

  @doc false
  def changeset(host, attrs) do
    host
    |> cast(attrs, [:common_name, :scientific_name])
    |> cast_assoc(:varieties)
    |> validate_required([:common_name, :scientific_name])
  end
end
