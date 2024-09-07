defmodule PlantAid.Observations.Observation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias PlantAid.Accounts.User
  @behaviour Bodyguard.Schema

  @timestamps_opts [type: :utc_datetime]

  @derive {
    Flop.Schema,
    filterable: [
      :status,
      :source,
      :observation_date,
      :organic,
      :user_id,
      :host_id,
      :host_variety_id,
      :location_type_id,
      :suspected_pathology_id,
      :country_id,
      :primary_subdivision_id,
      :secondary_subdivision_id,
      :user_email,
      :confirmed_pathology_id,
      :genotype_id
    ],
    sortable: [
      :status,
      :observation_date
    ],
    adapter_opts: [
      join_fields: [
        user_email: [
          binding: :user,
          field: :email,
          ecto_type: :string
        ],
        confirmed_pathology_id: [
          binding: :sample,
          field: :pathology_id
        ],
        genotype_id: [
          binding: :sample,
          field: :genotype_id
        ]
      ]
    ],
    default_order: %{
      order_by: [:observation_date],
      order_directions: [:desc_nulls_last]
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

    field :source, Ecto.Enum,
      values: [:plant_aid, :usa_blight, :npdn, :cucurbit_sentinel_network],
      default: :plant_aid

    field :status, Ecto.Enum, values: [:unsubmitted, :submitted], default: :unsubmitted
    field :latitude, :float, virtual: true
    field :longitude, :float, virtual: true
    field :location, :string, virtual: true
    field :data_source, :string, virtual: true

    belongs_to :user, User
    belongs_to :host, PlantAid.Hosts.Host
    belongs_to :host_variety, PlantAid.Hosts.HostVariety
    belongs_to :location_type, PlantAid.LocationTypes.LocationType
    belongs_to :suspected_pathology, PlantAid.Pathologies.Pathology
    belongs_to :country, PlantAid.Geography.Country
    belongs_to :primary_subdivision, PlantAid.Geography.PrimarySubdivision
    belongs_to :secondary_subdivision, PlantAid.Geography.SecondarySubdivision

    has_one :sample, PlantAid.Observations.Sample
    has_many :test_results, PlantAid.DiagnosticTests.TestResult

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
      :image_urls,
      :notes,
      :latitude,
      :longitude,
      :host_id,
      :location_type_id,
      :suspected_pathology_id,
      :country_id,
      :primary_subdivision_id,
      :secondary_subdivision_id
    ])
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> maybe_put_position()
    |> validate_geography()
    |> clear_host_variety_id_or_host_other()

    # |> validate_required([
    #   :observation_date,
    #   :position,
    #   :organic,
    #   :control_method,
    #   :host_other,
    #   :notes,
    #   :metadata
    # ])
  end

  def scope(query, %User{id: user_id}, _) do
    from row in query, where: row.user_id == ^user_id
  end

  def put_user(%Ecto.Changeset{} = changeset, %PlantAid.Accounts.User{} = user) do
    changeset
    |> put_assoc(:user, user)
  end

  def put_coordinates(%Ecto.Changeset{} = changeset, latitude, longitude) do
    changeset
    |> put_change(:latitude, latitude)
    |> put_change(:longitude, longitude)
    |> maybe_put_position()
  end

  def maybe_put_position(%Ecto.Changeset{} = changeset) do
    latitude = get_field(changeset, :latitude)
    longitude = get_field(changeset, :longitude)

    if latitude && longitude do
      changeset
      |> put_change(:position, %Geo.Point{coordinates: {longitude, latitude}, srid: 4326})
    else
      changeset
    end
  end

  def maybe_put_geography_from_position(%Ecto.Changeset{} = changeset) do
    with %Geo.Point{} = position <- get_field(changeset, :position),
         %PlantAid.Geography.SecondarySubdivision{} = s <-
           PlantAid.Geography.find_secondary_subdivision_containing_point(position) do
      changeset
      |> put_change(:country_id, s.primary_subdivision.country.id)
      |> put_change(:primary_subdivision_id, s.primary_subdivision.id)
      |> put_change(:secondary_subdivision_id, s.id)
    else
      _ ->
        changeset
    end
  end

  def clear_host_variety_id_or_host_other(changeset) do
    if get_field(changeset, :host) && get_field(changeset, :host).common_name == "Other" do
      changeset
      |> put_change(:host_variety_id, nil)
    else
      changeset
      |> put_change(:host_other, nil)
    end
  end

  def validate_geography(changeset) do
    changeset
  end
end
