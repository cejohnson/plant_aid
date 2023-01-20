defmodule PlantAid.Geography.County2 do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cb_2021_us_county_500k" do
    field :gid, :id, primary_key: true
    field :statefp, :string
    field :countyfp, :string
    field :countyns, :string
    field :affgeoid, :string
    field :geoid, :string
    field :name, :string
    field :namelsad, :string
    field :stusps, :string
    field :state_name, :string
    field :lsad, :string
    # field :classfp, :string
    # field :mtfcc, :string
    # field :csafp, :string
    # field :cbsafp, :string
    # field :metdivfp, :string
    # field :funcstat, :string
    field :aland, :float
    field :awater, :float
    # field :intptlat, :string
    # field :intptlon, :string
    field :geom, Geo.PostGIS.Geometry
  end

  # @doc false
  # def changeset(county, attrs) do
  #   county
  #   |> cast(attrs, [:name, :state, :geometry])
  #   |> validate_required([:name, :state, :geometry])
  # end
end
