defmodule PlantAid.Geography.County do
  use Ecto.Schema
  import Ecto.Changeset

  schema "counties" do
    field :geometry, Geo.PostGIS.Geometry
    field :name, :string
    field :state, :string
    field :sqmi, :float
  end

  @doc false
  def changeset(county, attrs) do
    county
    |> cast(attrs, [:name, :state, :geometry])
    |> validate_required([:name, :state, :geometry])
  end
end
