defmodule PlantAid.Alerts.AlertSubscription do
  @behaviour Bodyguard.Schema

  @meters_per_kilometer 1000
  @meters_per_mile 1609.344

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias PlantAid.Alerts.AlertSubscription
  alias PlantAid.Repo
  alias PlantAid.Accounts.User

  @timestamps_opts [type: :utc_datetime]

  schema "alert_subscriptions" do
    field :enabled, :boolean, default: true
    field :description, :string

    field :events_selector, Ecto.Enum, values: [:any, :disease_reported, :disease_confirmed]

    field :pathologies_selector, Ecto.Enum, values: [:any, :include, :exclude]
    field :geographical_selector, Ecto.Enum, values: [:any, :regions, :locations]

    field :locations_selector, Ecto.Enum, values: [:any, :include, :exclude]
    field :distance_meters, :float
    field :distance_unit, Ecto.Enum, values: [:miles, :kilometers]

    field :auto_description, :string, virtual: true
    field :distance, :float, virtual: true, default: 100.0
    field :location_ids, {:array, :integer}, virtual: true
    field :pathology_ids, {:array, :integer}, virtual: true
    field :country_ids, {:array, :integer}, virtual: true, default: []
    field :primary_subdivision_ids, {:array, :integer}, virtual: true, default: []
    field :secondary_subdivision_ids, {:array, :integer}, virtual: true, default: []

    belongs_to :user, PlantAid.Accounts.User

    many_to_many :locations, PlantAid.Locations.Location,
      join_through: "alert_subscriptions_locations",
      on_replace: :delete

    many_to_many :pathologies, PlantAid.Pathologies.Pathology,
      join_through: "alert_subscriptions_pathologies",
      on_replace: :delete

    many_to_many :countries, PlantAid.Geography.Country,
      join_through: "alert_subscriptions_countries",
      on_replace: :delete

    many_to_many :primary_subdivisions, PlantAid.Geography.PrimarySubdivision,
      join_through: "alert_subscriptions_primary_subdivisions",
      on_replace: :delete

    many_to_many :secondary_subdivisions, PlantAid.Geography.SecondarySubdivision,
      join_through: "alert_subscriptions_secondary_subdivisions",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(alert_subscription, attrs) do
    if User.has_role?(alert_subscription.user, [:researcher, :admin, :superuser]) do
      alert_subscription
      |> cast(attrs, [:events_selector])
      |> validate_required([:events_selector])
    else
      alert_subscription
      |> change(events_selector: :disease_confirmed)
    end
    |> cast(attrs, [
      :enabled,
      :pathologies_selector,
      :geographical_selector,
      :locations_selector,
      :distance,
      :distance_unit,
      :country_ids,
      :primary_subdivision_ids,
      :secondary_subdivision_ids,
      :location_ids,
      :pathology_ids
    ])
    |> validate_required([
      :enabled,
      :pathologies_selector,
      :geographical_selector
    ])
    |> validate_pathology_ids(attrs)
    |> validate_location_ids(attrs)
    |> validate_country_ids(attrs)
    |> validate_distance()
  end

  def get_distance(%AlertSubscription{
        distance_meters: distance_meters,
        distance_unit: :kilometers
      }) do
    distance_meters / @meters_per_kilometer
  end

  def get_distance(%AlertSubscription{distance_meters: distance_meters, distance_unit: :miles}) do
    distance_meters / @meters_per_mile
  end

  def scope(query, %User{id: user_id}, _) do
    from(row in query, where: row.user_id == ^user_id)
  end

  def populate_nonvirtual_fields(%Ecto.Changeset{errors: errors} = changeset)
      when length(errors) > 0 do
    changeset
  end

  def populate_nonvirtual_fields(changeset) do
    changeset
    |> put_pathologies()
    |> put_locations()
    |> put_countries()
    |> put_primary_subdivisions()
    |> put_secondary_subdivisions()
    |> put_distance_meters()
  end

  defp validate_pathology_ids(changeset, attrs) do
    case get_field(changeset, :pathologies_selector) do
      selector when selector in [:include, :exclude] ->
        case Map.get(attrs, "pathology_ids", []) do
          [] ->
            changeset
            |> add_error(:pathology_ids, "Select at least 1 pathology")

          _ ->
            changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_location_ids(changeset, attrs) do
    case get_field(changeset, :locations_selector) do
      selector when selector in [:include, :exclude] ->
        case Map.get(attrs, "location_ids", []) do
          [] ->
            changeset
            |> add_error(
              :location_ids,
              "Select at least 1 location, or a different geographical selection"
            )

          _ ->
            changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_country_ids(changeset, attrs) do
    case get_field(changeset, :geographical_selector) do
      :regions ->
        case Map.get(attrs, "country_ids", []) do
          [] ->
            changeset
            |> add_error(
              :country_ids,
              "Select at least 1 country, or a different geographical selection"
            )

          _ ->
            changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_distance(changeset) do
    case get_field(changeset, :locations_selector) do
      selector when selector in [:any, :include, :exclude] ->
        changeset
        |> validate_required([:distance, :distance_unit])
        |> validate_number(:distance, greater_than_or_equal_to: 0)

      _ ->
        changeset
    end
  end

  defp put_pathologies(changeset) do
    pathologies =
      case get_field(changeset, :pathologies_selector) do
        selector when selector in [:include, :exclude] ->
          pathology_ids = get_field(changeset, :pathology_ids)

          Repo.all(from p in PlantAid.Pathologies.Pathology, where: p.id in ^pathology_ids)

        _ ->
          []
      end

    put_assoc(changeset, :pathologies, pathologies)
  end

  defp put_locations(changeset) do
    locations =
      case get_field(changeset, :locations_selector) do
        selector when selector in [:include, :exclude] ->
          location_ids = get_field(changeset, :location_ids)

          Repo.all(from l in PlantAid.Locations.Location, where: l.id in ^location_ids)

        _ ->
          []
      end

    put_assoc(changeset, :locations, locations)
  end

  defp put_countries(changeset) do
    country_ids = get_field(changeset, :country_ids)

    countries =
      Repo.all(from c in PlantAid.Geography.Country, where: c.id in ^country_ids)

    put_assoc(changeset, :countries, countries)
  end

  defp put_primary_subdivisions(changeset) do
    primary_subdivision_ids = get_field(changeset, :primary_subdivision_ids)

    primary_subdivisions =
      Repo.all(
        from p in PlantAid.Geography.PrimarySubdivision,
          where: p.id in ^primary_subdivision_ids
      )

    put_assoc(changeset, :primary_subdivisions, primary_subdivisions)
  end

  defp put_secondary_subdivisions(changeset) do
    secondary_subdivision_ids = get_field(changeset, :secondary_subdivision_ids)

    secondary_subdivisions =
      Repo.all(
        from s in PlantAid.Geography.SecondarySubdivision,
          where: s.id in ^secondary_subdivision_ids,
          select: %{s | geog: nil}
      )

    put_assoc(changeset, :secondary_subdivisions, secondary_subdivisions)
  end

  defp put_distance_meters(changeset) do
    case get_field(changeset, :locations_selector) do
      nil ->
        changeset

      :global ->
        changeset
        |> put_change(:distance_meters, nil)
        |> put_change(:distance_unit, nil)

      _ ->
        distance = get_field(changeset, :distance)

        meters =
          case get_field(changeset, :distance_unit) do
            :kilometers ->
              distance * @meters_per_kilometer

            :miles ->
              distance * @meters_per_mile
          end

        put_change(changeset, :distance_meters, meters)
    end
  end
end
