defmodule PlantAid.Observations.Observation do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  schema "observations" do
    field :control_method, :string
    field :host_other, :string
    field :image_urls, {:array, :string}, default: []
    field :metadata, :map
    field :notes, :string
    field :observation_date, :date
    field :organic, :boolean, default: false
    field :position, Geo.PostGIS.Geometry
    field :status, Ecto.Enum, values: [:unsubmitted, :submitted], default: :unsubmitted

    belongs_to :user, PlantAid.Accounts.User
    belongs_to :host, PlantAid.Hosts.Host
    belongs_to :host_variety, PlantAid.Hosts.HostVariety
    belongs_to :location_type, PlantAid.LocationTypes.LocationType
    belongs_to :suspected_pathology, PlantAid.Pathologies.Pathology

    timestamps()
  end

  @doc false
  def changeset(observation, attrs) do
    observation
    |> cast(attrs, [
      :observation_date,
      :position,
      :organic,
      :control_method,
      :host_other,
      :notes,
      :metadata
    ])
    |> validate_required([
      :observation_date,
      :position,
      :organic,
      :control_method,
      :host_other,
      :notes,
      :metadata
    ])
  end
end
