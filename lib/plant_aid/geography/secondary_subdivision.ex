defmodule PlantAid.Geography.SecondarySubdivision do
  use Ecto.Schema

  @derive {
    Flop.Schema,
    default_order: %{
      order_by: [:observation_count, :country_name, :primary_subdivision_name, :name],
      order_directions: [:desc, :asc, :asc, :asc]
    },
    filterable: [
      :id,
      # :name,
      :primary_subdivision_id,
      :country_id,
      :observation_count,
      :observation_host
    ],
    max_limit: 100,
    default_limit: 20,
    sortable: [
      :name,
      :primary_subdivision_name,
      :country_name,
      :observation_count
    ],
    join_fields: [
      country_id: [
        binding: :primary_subdivision,
        field: :country_id,
        ecto_type: :id
      ],
      primary_subdivision_name: [
        binding: :primary_subdivision,
        field: :name,
        ecto_type: :string
      ],
      country_name: [
        binding: :country,
        field: :name,
        ecto_type: :string,
        path: [:primary_subdivision, :country]
      ],
      observation_count: {:observation_count, :count},
      observation_host: [
        binding: :observations,
        field: :host_id,
        ecto_type: :id
      ]
    ]
  }

  schema "secondary_subdivisions" do
    field :name, :string
    field :category, :string
    field :geog, Geo.PostGIS.Geometry
    field :metadata, :map
    field :observation_count, :integer, virtual: true

    belongs_to :primary_subdivision, PlantAid.Geography.PrimarySubdivision
    has_many :observations, PlantAid.Observations.Observation
  end
end
