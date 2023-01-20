defmodule PlantAid.Geography.Country do
  use Ecto.Schema

  schema "countries" do
    field :name, :string
    field :iso3166_1_alpha2, :string
    field :iso3166_1_alpha3, :string
    field :iso3166_1_numeric, :string
    # field :geog, Geo.PostGIS.Geometry
    field :metadata, :map

    has_many :primary_subdivisions, PlantAid.Geography.PrimarySubdivision
    has_many :observations, PlantAid.Observations.Observation
  end
end
