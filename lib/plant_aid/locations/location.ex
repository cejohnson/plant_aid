defmodule PlantAid.Locations.Location do
  @behaviour Bodyguard.Schema

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias PlantAid.Accounts.User

  schema "locations" do
    field :name, :string
    field :position, Geo.PostGIS.Geometry

    field :latitude, :float, virtual: true
    field :longitude, :float, virtual: true

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :position, :latitude, :longitude])
    |> validate_required([:name, :position])
    |> maybe_put_position()
  end

  def scope(query, %User{id: user_id}, _) do
    from(row in query, where: row.user_id == ^user_id)
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
end