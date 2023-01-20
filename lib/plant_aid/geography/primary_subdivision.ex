defmodule PlantAid.Geography.PrimarySubdivision do
  use Ecto.Schema

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
