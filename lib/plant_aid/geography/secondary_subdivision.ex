defmodule PlantAid.Geography.SecondarySubdivision do
  use Ecto.Schema

  @derive {
    Flop.Schema,
    # alias_fields: [:observation_count],
    # custom_fields: [
    #   observation_host_id: [
    #     filter: {PlantAid.CustomFilters, :observation_host_id_filter, []},
    #     ecto_type: :id
    #   ]
    # ],
    default_order: %{
      order_by: [:country_name, :primary_subdivision_name, :name],
      order_directions: [:asc, :asc, :asc]
    },
    filterable: [
      :id,
      :name,
      :category,
      :primary_subdivision_id,
      :country_id
      # :observation_count,
      # :observation_host_id
      # :observation_location_type_id
    ],
    max_limit: 100,
    default_limit: 20,
    sortable: [
      :name,
      :primary_subdivision_name,
      :country_name
      # :observation_count
    ],
    join_fields: [
      # observation_count: [
      #   binding: :observation_count,
      #   field: :count
      # ],
      primary_subdivision_name: [
        binding: :primary_subdivision,
        field: :name,
        ecto_type: :string
      ],
      country_name: [
        binding: :country,
        field: :name,
        ecto_type: :string
      ],
      # observation_host_id: [
      #   binding: :observation_count,
      #   field: :host_id,
      #   ecto_type: :id
      # ]
      # primary_subdivision_id: [
      #   binding: :primary_subdivision,
      #   field: :id,
      #   ecto_type: :id
      # ],
      country_id: [
        binding: :country_id,
        field: :country_id,
        ecto_type: :id,
        path: [:primary_subdivision, :country]
      ]
      # primary_subdivision_id: [
      #   binding: :primary_subdivision,
      #   field: :id,
      #   ecto_type: :id
      # ],
      # country_name: [
      #   binding: :country,
      #   field: :name,
      #   ecto_type: :string,
      #   path: [:primary_subdivision, :country]
      # ],
      # observation_count: {:observation_count, :count}
      # observation_host: [
      #   binding: :observation_count,
      #   field: :host_id,
      #   ecto_type: :id
      # ]
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
