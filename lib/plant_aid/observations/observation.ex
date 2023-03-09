defmodule PlantAid.Observations.Observation do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime]

  @derive {
    Flop.Schema,
    # join_fields: [
    #   host_id: {:host}
    # ],
    # custom_fields: [
    #   group_by: [
    #     filter: {PlantAid.Observations.Filters, :group_by, []}
    #   ]
    # ]
    # default_limit: 20,
    filterable: [
      :status,
      :observation_date,
      :organic,
      :user_id,
      :host_id,
      :host_variety_id,
      :location_type_id,
      :suspected_pathology_id,
      :country_id,
      :primary_subdivision_id,
      :secondary_subdivision_id
    ],
    sortable: [
      :status,
      :observation_date,
      :organic,
      :user_id,
      :host_id,
      :host_variety_id,
      :location_type_id,
      :suspected_pathology_id,
      :country_id,
      :primary_subdivision_id,
      :secondary_subdivision_id
    ],
    default_order: %{
      order_by: [:observation_date],
      order_directions: [:desc]
    }
  }

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
    field :latitude, :float, virtual: true
    field :longitude, :float, virtual: true
    field :location, :string, virtual: true

    belongs_to :user, PlantAid.Accounts.User
    belongs_to :host, PlantAid.Hosts.Host
    belongs_to :host_variety, PlantAid.Hosts.HostVariety
    belongs_to :location_type, PlantAid.LocationTypes.LocationType
    belongs_to :suspected_pathology, PlantAid.Pathologies.Pathology
    belongs_to :country, PlantAid.Geography.Country
    belongs_to :primary_subdivision, PlantAid.Geography.PrimarySubdivision
    belongs_to :secondary_subdivision, PlantAid.Geography.SecondarySubdivision

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
