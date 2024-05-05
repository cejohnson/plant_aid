defmodule PlantAid.Alerts do
  @moduledoc """
  The Alerts context.
  """

  import Ecto.Query, warn: false
  require Geo.PostGIS
  require Phoenix.VerifiedRoutes

  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Accounts.UserNotifier
  alias PlantAid.Alerts.Alert
  alias PlantAid.Alerts.Alert
  alias PlantAid.Alerts.AlertSetting
  alias PlantAid.Locations.Location
  alias PlantAid.Observations
  alias PlantAid.Observations.Sample

  def authorize(:list_alert_settings, %User{}, _), do: :ok

  def authorize(:get_alert_setting, %User{id: user_id}, %AlertSetting{user_id: user_id}), do: :ok

  def authorize(:get_alert_setting, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_alert_setting, %User{}, _), do: :ok

  def authorize(:update_alert_setting, %User{id: user_id}, %AlertSetting{user_id: user_id}),
    do: :ok

  def authorize(:update_alert_setting, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_alert_setting, %User{id: user_id}, %AlertSetting{user_id: user_id}) do
    :ok
  end

  def authorize(:delete_alert_setting, %User{} = user, _) do
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

  def handle_positive_sample(%Sample{} = sample) do
    sample =
      sample
      |> Repo.preload([
        :pathology,
        observation: [:country, :primary_subdivision, :secondary_subdivision]
      ])

    pathology_id = sample.pathology_id
    position = sample.observation.position

    alert_settings =
      from(
        a in AlertSetting,
        left_join: l in Location,
        on: a.user_id == l.user_id,
        left_join: acp in "alert_settings_pathologies",
        on: acp.alert_setting_id == a.id,
        left_join: acl in "alert_settings_locations",
        on: acl.alert_setting_id == a.id,
        where: a.enabled,
        where:
          a.pathologies_selector == :any or
            (a.pathologies_selector == :include and ^pathology_id == acp.pathology_id) or
            (a.pathologies_selector == :exclude and ^pathology_id != acp.pathology_id),
        where:
          a.locations_selector == :global or
            (a.locations_selector == :any and
               Geo.PostGIS.st_distance(^position, l.position) <= a.distance_meters) or
            (a.locations_selector == :include and l.id == acl.location_id and
               Geo.PostGIS.st_distance(^position, l.position) <= a.distance_meters) or
            (a.locations_selector == :exclude and l.id != acl.location_id and
               Geo.PostGIS.st_distance(^position, l.position) <= a.distance_meters),
        distinct: true
      )
      |> Repo.all()

    alert_settings
    |> Enum.group_by(fn alert_setting ->
      alert_setting.user_id
    end)
    |> Enum.map(fn {user_id, alert_settings} ->
      {:ok, alert} = create_alert(user_id, alert_settings, sample)
      alert
    end)
    |> Repo.preload([
      :user,
      sample: [
        :pathology,
        observation: [:country, :primary_subdivision, :secondary_subdivision]
      ]
    ])
    |> Enum.map(fn alert ->
      observation = Observations.populate_virtual_fields(alert.sample.observation)
      put_in(alert.sample.observation, observation)
    end)
    |> Enum.each(fn alert ->
      alert_url =
        Phoenix.VerifiedRoutes.url(
          PlantAidWeb.Endpoint,
          PlantAidWeb.Router,
          ~p"/alerts/#{alert}"
        )

      alert_settings_url =
        Phoenix.VerifiedRoutes.url(
          PlantAidWeb.Endpoint,
          PlantAidWeb.Router,
          ~p"/alerts/settings"
        )

      UserNotifier.deliver_alert(
        alert.user,
        alert.sample.pathology,
        alert.sample.observation,
        alert_url,
        alert_settings_url
      )
    end)
  end

  @doc """
  Returns the list of alert_settings.

  ## Examples

      iex> list_alert_settings()
      [%AlertSetting{}, ...]

  """
  def list_alert_settings(user) do
    AlertSetting
    |> Bodyguard.scope(user)
    |> order_by([as], as.id)
    |> Repo.all()
    |> Repo.preload([:pathologies, :locations])
    |> Enum.map(&populate_virtual_fields/1)
  end

  @doc """
  Gets a single alert_setting.

  Raises `Ecto.NoResultsError` if the Alert setting does not exist.

  ## Examples

      iex> get_alert_setting!(123)
      %AlertSetting{}

      iex> get_alert_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert_setting!(id) do
    Repo.get!(AlertSetting, id)
    |> Repo.preload([:pathologies, :locations])
    |> populate_virtual_fields()
  end

  @doc """
  Creates a alert_setting.

  ## Examples

      iex> create_alert_setting(%{field: value})
      {:ok, %AlertSetting{}}

      iex> create_alert_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert_setting(user, attrs \\ %{}) do
    %AlertSetting{user: user}
    |> AlertSetting.changeset(attrs)
    |> AlertSetting.populate_nonvirtual_fields()
    |> Repo.insert()
    |> populate_virtual_fields()
  end

  @doc """
  Updates a alert_setting.

  ## Examples

      iex> update_alert_setting(alert_setting, %{field: new_value})
      {:ok, %AlertSetting{}}

      iex> update_alert_setting(alert_setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alert_setting(%AlertSetting{} = alert_setting, attrs) do
    alert_setting
    |> Repo.preload([:locations, :pathologies])
    |> AlertSetting.changeset(attrs)
    |> AlertSetting.populate_nonvirtual_fields()
    |> Repo.update()
    |> populate_virtual_fields()
  end

  @doc """
  Deletes a alert_setting.

  ## Examples

      iex> delete_alert_setting(alert_setting)
      {:ok, %AlertSetting{}}

      iex> delete_alert_setting(alert_setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert_setting(%AlertSetting{} = alert_setting) do
    Repo.delete(alert_setting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert_setting changes.

  ## Examples

      iex> change_alert_setting(alert_setting)
      %Ecto.Changeset{data: %AlertSetting{}}

  """
  def change_alert_setting(%AlertSetting{} = alert_setting, attrs \\ %{}) do
    AlertSetting.changeset(alert_setting, attrs)
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

  def list_alerts(user) do
    Alert
    |> Bodyguard.scope(user)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload([
      [
        alert_settings: [:pathologies, :locations],
        sample: [
          :pathology,
          observation: [:country, :primary_subdivision, :secondary_subdivision]
        ]
      ]
    ])
    |> Enum.map(&populate_virtual_fields/1)
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
    Repo.get!(Alert, id)
    |> Repo.preload([
      [
        alert_settings: [:pathologies, :locations],
        sample: [
          :pathology,
          observation: [:country, :primary_subdivision, :secondary_subdivision]
        ]
      ]
    ])
    |> populate_virtual_fields()
  end

  @doc """
  Creates a alert.

  ## Examples

      iex> create_alert(%{field: value})
      {:ok, %Alert{}}

      iex> create_alert(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert(user_id, alert_settings, sample) do
    %Alert{
      user_id: user_id,
      sample: sample,
      alert_settings: alert_settings
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

  def populate_virtual_fields({:ok, alert_or_alert_setting}) do
    {:ok, populate_virtual_fields(alert_or_alert_setting)}
  end

  def populate_virtual_fields({:error, _} = resp) do
    resp
  end

  def populate_virtual_fields(%AlertSetting{} = alert_setting) do
    alert_setting
    |> maybe_put_alert_setting_distance()
    |> maybe_put_pathology_ids()
    |> maybe_put_location_ids()
    |> put_alert_setting_description()
  end

  def populate_virtual_fields(%Alert{} = alert) do
    alert_settings =
      alert.alert_settings
      |> Enum.map(&populate_virtual_fields/1)

    observation = Observations.populate_virtual_fields(alert.sample.observation)

    alert =
      alert
      |> Map.put(:alert_settings, alert_settings)

    put_in(alert.sample.observation, observation)
  end

  defp maybe_put_alert_setting_distance(%AlertSetting{distance_meters: nil} = alert_setting) do
    alert_setting
  end

  defp maybe_put_alert_setting_distance(%AlertSetting{} = alert_setting) do
    %{alert_setting | distance: AlertSetting.get_distance(alert_setting)}
  end

  defp maybe_put_pathology_ids(%AlertSetting{pathologies: pathologies} = alert_setting)
       when is_list(pathologies) do
    %{alert_setting | pathology_ids: Enum.map(pathologies, fn p -> p.id end)}
  end

  defp maybe_put_pathology_ids(%AlertSetting{} = alert_setting) do
    alert_setting
  end

  defp maybe_put_location_ids(%AlertSetting{locations: locations} = alert_setting)
       when is_list(locations) do
    %{alert_setting | location_ids: Enum.map(locations, fn l -> l.id end)}
  end

  defp maybe_put_location_ids(%AlertSetting{} = alert_setting) do
    alert_setting
  end

  defp put_alert_setting_description(alert_setting) do
    pathology_blurb =
      case alert_setting.pathologies_selector do
        :any ->
          "any pathology"

        :include ->
          alert_setting.pathologies
          |> Enum.map(fn p -> p.common_name end)
          |> join_with_or()

        :exclude ->
          pathologies =
            alert_setting.pathologies
            |> Enum.map(fn p -> p.common_name end)
            |> join_with_or()

          "any pathology EXCEPT #{pathologies}"
      end

    location_blurb =
      case alert_setting.locations_selector do
        :global ->
          "anywhere"

        :any ->
          "within #{alert_setting.distance} #{alert_setting.distance_unit} of any location"

        :include ->
          locations =
            alert_setting.locations
            |> Enum.map(fn l -> l.name end)
            |> join_with_or()

          "within #{alert_setting.distance} #{alert_setting.distance_unit} of #{locations}"

        :exclude ->
          locations =
            alert_setting.locations
            |> Enum.map(fn l -> l.name end)
            |> join_with_or()

          "within #{alert_setting.distance} #{alert_setting.distance_unit} of any location except #{locations}"
      end

    description = "Confirmed instances of #{pathology_blurb}, #{location_blurb}."

    %{alert_setting | description: description}
  end

  defp join_with_or([]) do
    ""
  end

  defp join_with_or([first | []]) do
    first
  end

  defp join_with_or([first | [last]]) do
    first <> " or " <> last
  end

  defp join_with_or(list) do
    [last | rest] = Enum.reverse(list)

    (rest
     |> Enum.reverse()
     |> Enum.join(", ")) <> ", or #{last}"
  end
end
