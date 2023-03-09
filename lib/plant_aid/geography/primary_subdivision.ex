defmodule PlantAid.Geography.PrimarySubdivision do
  use Ecto.Schema

  @derive {
    Flop.Schema,
    # join_fields: [
    #   country_name: [
    #     binding: :country,
    #     field: :name,
    #     ecto_type: :string
    #   ]
    # ],
    filterable: [
      :id,
      :name,
      :category,
      :country_id
    ],
    sortable: [
      :name
      # :country_name
    ],
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    }
  }

  schema "primary_subdivisions" do
    field :name, :string
    field :category, :string
    field :iso3166_2, :string
    # field :geog, Geo.PostGIS.Geometry
    field :metadata, :map

    belongs_to :country, PlantAid.Geography.Country
    has_many :secondary_subdivisions, PlantAid.Geography.SecondarySubdivision
  end
end
