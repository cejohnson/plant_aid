defmodule PlantAid.Alerts do
  @moduledoc """
  The Alerts context.
  """

  import Ecto.Query, warn: false
  require Geo.PostGIS
  require Phoenix.VerifiedRoutes

  require Logger
  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Alerts.Alert
  alias PlantAid.Alerts.AlertSubscription
  alias PlantAid.DiagnosticTests.TestResult
  alias PlantAid.Geography.SecondarySubdivision
  alias PlantAid.Locations.Location
  alias PlantAid.Observations.Observation
  alias PlantAid.Utilities

  def authorize(:list_alert_subscriptions, %User{}, _), do: :ok

  def authorize(:get_alert_subscription, %User{id: user_id}, %AlertSubscription{user_id: user_id}),
    do: :ok

  def authorize(:get_alert_subscription, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_alert_subscription, %User{}, _), do: :ok

  def authorize(:update_alert_subscription, %User{id: user_id}, %AlertSubscription{
        user_id: user_id
      }),
      do: :ok

  def authorize(:update_alert_subscription, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_alert_subscription, %User{id: user_id}, %AlertSubscription{
        user_id: user_id
      }) do
    :ok
  end

  def authorize(:delete_alert_subscription, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:list_alerts, %User{}, _), do: :ok

  def authorize(:get_alert, %User{id: user_id}, %Alert{user_id: user_id}), do: :ok

  def authorize(:get_alert, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:delete_alert, %User{id: user_id}, %Alert{user_id: user_id}) do
    :ok
  end

  def authorize(:delete_alert, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(_, _, _), do: false

  def list_alert_subscriptions(user) do
    AlertSubscription
    |> Bodyguard.scope(user)
    # |> order_by([as], as.id)
    |> Repo.all()
    |> preload_alert_subscription_fields()
    |> Enum.map(&populate_virtual_fields/1)
  end

  def get_alert_subscription!(id) do
    Repo.get!(AlertSubscription, id)
    |> preload_alert_subscription_fields()
    |> populate_virtual_fields()
  end

  def create_alert_subscription(user, attrs \\ %{}) do
    %AlertSubscription{user: user}
    |> AlertSubscription.changeset(attrs)
    |> AlertSubscription.populate_nonvirtual_fields()
    |> Repo.insert()
    |> preload_alert_subscription_fields()
    |> populate_virtual_fields()
  end

  def update_alert_subscription(%AlertSubscription{} = alert_subscription, attrs \\ %{}) do
    alert_subscription
    |> preload_alert_subscription_fields()
    |> AlertSubscription.changeset(attrs)
    |> AlertSubscription.populate_nonvirtual_fields()
    |> Repo.update()
    |> preload_alert_subscription_fields()
    |> populate_virtual_fields()
  end

  def delete_alert_subscription(%AlertSubscription{} = alert_subscription) do
    Repo.delete(alert_subscription)
  end

  def change_alert_subscription(%AlertSubscription{} = alert_subscription, attrs \\ %{}) do
    AlertSubscription.changeset(alert_subscription, attrs)
  end

  def find_alert_subscriptions(%Observation{} = observation) do
    pathology_ids = [observation.suspected_pathology_id]
    find_alert_subscriptions(observation, pathology_ids, observation.user_id, :disease_reported)
  end

  def find_alert_subscriptions(%TestResult{} = test_result) do
    case test_result.pathology_results
         |> Enum.filter(&(&1.result == :positive))
         |> Enum.map(& &1.pathology_id) do
      [] ->
        []

      pathology_ids ->
        find_alert_subscriptions(
          test_result.observation,
          pathology_ids,
          test_result.inserted_by_id,
          :disease_confirmed
        )
    end
  end

  defp find_alert_subscriptions(
         %Observation{} = observation,
         pathology_ids,
         exclude_user_id,
         events_selector
       ) do
    country_id = observation.country_id
    primary_subdivision_id = observation.primary_subdivision_id
    secondary_subdivision_id = observation.secondary_subdivision_id
    position = observation.position

    from(
      a in AlertSubscription,
      left_join: l in Location,
      on: a.user_id == l.user_id,
      left_join: asp in "alert_subscriptions_pathologies",
      on: asp.alert_subscription_id == a.id,
      left_join: asl in "alert_subscriptions_locations",
      on: asl.alert_subscription_id == a.id,
      left_join: asc in "alert_subscriptions_countries",
      on: asc.alert_subscription_id == a.id,
      left_join: aspsd in "alert_subscriptions_primary_subdivisions",
      on: aspsd.alert_subscription_id == a.id,
      left_join: asssd in "alert_subscriptions_secondary_subdivisions",
      on: asssd.alert_subscription_id == a.id,
      where: a.enabled,
      where: a.user_id != ^exclude_user_id,
      where: a.events_selector == :any or a.events_selector == ^events_selector,
      where:
        a.pathologies_selector == :any or
          (a.pathologies_selector == :include and asp.pathology_id in ^pathology_ids) or
          (a.pathologies_selector == :exclude and asp.pathology_id not in ^pathology_ids),
      where:
        a.geographical_selector == :any or
          (a.geographical_selector == :regions and
             (asssd.secondary_subdivision_id == ^secondary_subdivision_id or
                (aspsd.primary_subdivision_id == ^primary_subdivision_id and is_nil(asssd)) or
                (asc.country_id == ^country_id and is_nil(aspsd) and is_nil(asssd)))) or
          (a.geographical_selector == :locations and
             ((a.locations_selector == :any and
                 Geo.PostGIS.st_distance(^position, l.position) <= a.distance_meters) or
                (a.locations_selector == :include and l.id == asl.location_id and
                   Geo.PostGIS.st_distance(^position, l.position) <= a.distance_meters) or
                (a.locations_selector == :exclude and l.id != asl.location_id and
                   Geo.PostGIS.st_distance(^position, l.position) <= a.distance_meters))),
      distinct: true
    )
    |> Repo.all()
    |> preload_alert_subscription_fields()
    |> Enum.map(&populate_virtual_fields/1)
  end

  @doc """
  Returns the list of alerts.

  ## Examples

      iex> list_alerts()
      [%Alert{}, ...]

  """
  def list_alerts do
    Repo.all(Alert)
  end

  def list_alerts(%User{} = user, %Flop{} = flop) do
    opts = [for: Alert]

    Alert
    |> Bodyguard.scope(user)
    |> Flop.run(flop, opts)
    |> then(fn {alerts, meta} ->
      {Repo.preload(alerts, [
         :pathology,
         :test_result,
         observation: [
           secondary_subdivision:
             {from(s in SecondarySubdivision, select: %{s | geog: nil}),
              [primary_subdivision: :country]}
         ]
       ]), meta}
    end)
  end

  def list_alerts(user) do
    Alert
    |> Bodyguard.scope(user)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload([
      [
        :pathology,
        :test_result,
        observation: [
          secondary_subdivision:
            {from(s in SecondarySubdivision, select: %{s | geog: nil}),
             [primary_subdivision: :country]}
        ]
      ]
    ])
  end

  @doc """
  Gets a single alert.

  Raises `Ecto.NoResultsError` if the Alert does not exist.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

      iex> get_alert!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert!(id) do
    Alert
    |> Repo.get!(id)
    |> Repo.preload([
      [
        :pathology,
        :test_result,
        :observation,
        alert_subscriptions: [
          :pathologies,
          :locations,
          :countries,
          primary_subdivisions: [:country],
          secondary_subdivisions:
            {from(s in SecondarySubdivision, select: %{s | geog: nil}),
             [primary_subdivision: :country]}
        ],
        observation: [
          secondary_subdivision:
            {from(s in SecondarySubdivision, select: %{s | geog: nil}),
             [primary_subdivision: :country]}
        ]
      ]
    ])
    |> populate_virtual_fields()
  end

  def create_alerts(%Observation{} = observation, alert_subscriptions) do
    create_alerts(
      :disease_reported,
      observation.suspected_pathology_id,
      observation.id,
      nil,
      alert_subscriptions
    )
  end

  def create_alerts(%TestResult{} = test_result, alert_subscriptions) do
    positive_pathologies =
      test_result.pathology_results
      |> Enum.filter(&(&1.result == :positive))
      |> Enum.map(& &1.pathology)

    pathology_subscriptions =
      Enum.map(positive_pathologies, fn pathology ->
        {pathology,
         Enum.filter(alert_subscriptions, fn alert_subscription ->
           alert_subscription.pathologies_selector == :any ||
             (alert_subscription.pathologies_selector == :include &&
                pathology.id in alert_subscription.pathology_ids) ||
             (alert_subscription.pathologies_selector == :exclude &&
                pathology.id not in alert_subscription.pathology_ids)
         end)}
      end)

    Enum.each(pathology_subscriptions, fn {pathology, subscriptions} ->
      create_alerts(
        :disease_confirmed,
        pathology.id,
        test_result.observation_id,
        test_result.id,
        subscriptions
      )
    end)
  end

  defp create_alerts(
         alert_type,
         pathology_id,
         observation_id,
         test_result_id,
         alert_subscriptions
       ) do
    # TODO: consider Repo.insert_all(), but note that the many_to_many alert_subscriptions complicates matters
    alert_subscriptions
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, subscriptions} ->
      create_alert(
        alert_type,
        user_id,
        pathology_id,
        observation_id,
        test_result_id,
        subscriptions
      )
    end)
  end

  @doc """
  Creates a alert.

  ## Examples

      iex> create_alert(%{field: value})
      {:ok, %Alert{}}

      iex> create_alert(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert(
        alert_type,
        user_id,
        pathology_id,
        observation_id,
        test_result_id,
        alert_subscriptions
      ) do
    %Alert{
      alert_type: alert_type,
      user_id: user_id,
      pathology_id: pathology_id,
      observation_id: observation_id,
      test_result_id: test_result_id,
      alert_subscriptions: alert_subscriptions
    }
    |> Repo.insert()
  end

  @doc """
  Updates a alert.

  ## Examples

      iex> update_alert(alert, %{field: new_value})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def view_alert(%Alert{} = alert) do
    alert
    |> Ecto.Changeset.change(viewed_at: DateTime.utc_now(:second))
    |> Repo.update()
  end

  @doc """
  Deletes a alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}

      iex> delete_alert(alert)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert(%Alert{} = alert) do
    Repo.delete(alert)
  end

  def preload_alert_subscription_fields({:ok, value}) do
    {:ok, preload_alert_subscription_fields(value)}
  end

  def preload_alert_subscription_fields({:error, _} = resp) do
    resp
  end

  def preload_alert_subscription_fields(alert_subscription_or_subscriptions) do
    Repo.preload(alert_subscription_or_subscriptions, [
      :pathologies,
      :locations,
      :countries,
      primary_subdivisions: [:country],
      secondary_subdivisions:
        {from(s in SecondarySubdivision, select: %{s | geog: nil}),
         [primary_subdivision: :country]}
    ])
  end

  def populate_virtual_fields({:ok, value}) do
    {:ok, populate_virtual_fields(value)}
  end

  def populate_virtual_fields({:error, _} = resp) do
    resp
  end

  def populate_virtual_fields(%AlertSubscription{} = alert_subscription) do
    alert_subscription
    |> maybe_put_alert_subscription_distance()
    |> maybe_put_pathology_ids()
    |> maybe_put_location_ids()
    |> maybe_put_country_ids()
    |> maybe_put_primary_subdivision_ids()
    |> maybe_put_secondary_subdivision_ids()
    |> maybe_put_alert_subscription_auto_description()
  end

  def populate_virtual_fields(%Alert{} = alert) do
    alert_subscriptions =
      alert.alert_subscriptions
      |> Enum.map(&populate_virtual_fields/1)

    Map.put(alert, :alert_subscriptions, alert_subscriptions)
  end

  defp maybe_put_alert_subscription_distance(
         %AlertSubscription{distance_meters: nil} = alert_subscription
       ) do
    alert_subscription
  end

  defp maybe_put_alert_subscription_distance(%AlertSubscription{} = alert_subscription) do
    %{alert_subscription | distance: AlertSubscription.get_distance(alert_subscription)}
  end

  defp maybe_put_pathology_ids(%AlertSubscription{pathologies: pathologies} = alert_subscription)
       when is_list(pathologies) do
    %{alert_subscription | pathology_ids: Enum.map(pathologies, fn p -> p.id end)}
  end

  defp maybe_put_pathology_ids(%AlertSubscription{} = alert_subscription) do
    alert_subscription
  end

  defp maybe_put_location_ids(%AlertSubscription{locations: locations} = alert_subscription)
       when is_list(locations) do
    %{alert_subscription | location_ids: Enum.map(locations, fn l -> l.id end)}
  end

  defp maybe_put_location_ids(%AlertSubscription{} = alert_subscription) do
    alert_subscription
  end

  defp maybe_put_country_ids(%AlertSubscription{countries: countries} = alert_subscription)
       when is_list(countries) do
    %{alert_subscription | country_ids: Enum.map(countries, fn c -> c.id end)}
  end

  defp maybe_put_country_ids(%AlertSubscription{} = alert_subscription) do
    alert_subscription
  end

  defp maybe_put_primary_subdivision_ids(
         %AlertSubscription{primary_subdivisions: primary_subdivisions} = alert_subscription
       )
       when is_list(primary_subdivisions) do
    %{
      alert_subscription
      | primary_subdivision_ids: Enum.map(primary_subdivisions, fn p -> p.id end)
    }
  end

  defp maybe_put_primary_subdivision_ids(%AlertSubscription{} = alert_subscription) do
    alert_subscription
  end

  defp maybe_put_secondary_subdivision_ids(
         %AlertSubscription{secondary_subdivisions: secondary_subdivisions} = alert_subscription
       )
       when is_list(secondary_subdivisions) do
    %{
      alert_subscription
      | secondary_subdivision_ids: Enum.map(secondary_subdivisions, fn p -> p.id end)
    }
  end

  defp maybe_put_secondary_subdivision_ids(%AlertSubscription{} = alert_subscription) do
    alert_subscription
  end

  defp maybe_put_alert_subscription_auto_description(
         %AlertSubscription{description: nil} = alert_subscription
       ) do
    event_blurb =
      case alert_subscription.events_selector do
        :any ->
          "Reported or confirmed"

        :disease_reported ->
          "Reported"

        :disease_confirmed ->
          "Confirmed"
      end

    pathology_blurb =
      case alert_subscription.pathologies_selector do
        :any ->
          "any pathology"

        :include ->
          alert_subscription.pathologies
          |> Enum.map(fn p -> p.common_name end)
          |> Utilities.english_join("or")

        :exclude ->
          pathologies =
            alert_subscription.pathologies
            |> Enum.map(fn p -> p.common_name end)
            |> Utilities.english_join("or")

          "any pathology EXCEPT #{pathologies}"
      end

    geography_blurb =
      case alert_subscription.geographical_selector do
        :any ->
          "anywhere"

        :regions ->
          regions =
            cond do
              length(alert_subscription.secondary_subdivisions) > 0 ->
                alert_subscription.secondary_subdivisions
                |> Enum.map(
                  &"#{&1.name} #{&1.category}, #{String.slice(&1.primary_subdivision.iso3166_2, 3..5)}, #{&1.primary_subdivision.country.iso3166_1_alpha2}"
                )
                |> Utilities.english_join("or")

              length(alert_subscription.primary_subdivisions) > 0 ->
                alert_subscription.primary_subdivisions
                |> Enum.map(&"#{&1.name}, #{&1.country.iso3166_1_alpha3}")
                |> Utilities.english_join("or")

              length(alert_subscription.countries) > 0 ->
                alert_subscription.countries
                |> Enum.map(& &1.name)
                |> Utilities.english_join("or")

              true ->
                Logger.warning("Alert subscription set to regions with no regions!")
                "nowhere"
            end

          "in #{regions}"

        :locations ->
          case alert_subscription.locations_selector do
            :any ->
              "within #{alert_subscription.distance} #{alert_subscription.distance_unit} of any of my locations"

            :include ->
              locations =
                alert_subscription.locations
                |> Enum.map(fn l -> l.name end)
                |> Utilities.english_join("or")

              "within #{alert_subscription.distance} #{alert_subscription.distance_unit} of #{locations}"

            :exclude ->
              locations =
                alert_subscription.locations
                |> Enum.map(fn l -> l.name end)
                |> Utilities.english_join("or")

              "within #{alert_subscription.distance} #{alert_subscription.distance_unit} of any location EXCEPT #{locations}"
          end
      end

    description = "#{event_blurb} instances of #{pathology_blurb} #{geography_blurb}."

    %{alert_subscription | auto_description: description}
  end
end
