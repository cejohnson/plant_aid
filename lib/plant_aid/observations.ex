defmodule PlantAid.Observations do
  @moduledoc """
  The Observations context.
  """

  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias NimbleCSV.RFC4180, as: CSV
  alias PlantAid.Repo

  alias PlantAid.Accounts.User
  alias PlantAid.Geography.SecondarySubdivision
  alias PlantAid.Observations.Observation

  def authorize(:list_observations, %User{}, _), do: :ok

  def authorize(:list_all_observations, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:export_observations, %User{}, _), do: :ok

  def authorize(:get_observation, %User{id: user_id}, %Observation{user_id: user_id}), do: :ok

  def authorize(:get_observation, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_observation, %User{}, _), do: :ok

  def authorize(:update_observation, %User{id: user_id}, %Observation{user_id: user_id}), do: :ok

  def authorize(:update_observation, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(:delete_observation, %User{id: user_id}, %Observation{user_id: user_id}) do
    :ok
  end

  def authorize(:delete_observation, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin])
  end

  def authorize(_, _, _), do: false

  @doc """
  Returns the list of observations.

  ## Examples

      iex> list_observations()
      [%Observation{}, ...]

  """
  def list_observations(%User{} = user) do
    list_observations(user, %Flop{})
  end

  def list_observations(%User{} = user, %Flop{} = flop) do
    opts = [for: Observation]

    from(
      o in Observation,
      preload: [
        :user,
        :host,
        :host_variety,
        :location_type,
        :suspected_pathology,
        :country,
        :primary_subdivision,
        secondary_subdivision: ^from(s in SecondarySubdivision, select: %{s | geog: nil}),
        sample: [:pathology, :genotype],
        test_results: [
          :diagnostic_method,
          pathology_results: [:pathology, :genotype, test_result: [:diagnostic_method]]
        ]
      ]
    )
    |> scope(user)
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.run(flop, opts)
    |> populate_virtual_fields()
  end

  def list_observations(%User{} = user, %{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, list_observations(user, flop)}
    end
  end

  def export_observations(%User{} = user) do
    export_observations(user, %Flop{})
  end

  def export_observations(%User{} = user, %Flop{} = flop) do
    opts = [for: Observation]

    observations =
      from(
        o in Observation,
        preload: [
          :user,
          :host,
          :host_variety,
          :location_type,
          :suspected_pathology,
          :country,
          :primary_subdivision,
          secondary_subdivision: ^from(s in SecondarySubdivision, select: %{s | geog: nil}),
          sample: [:pathology, :genotype],
          test_results: [
            :diagnostic_method,
            pathology_results: [:pathology, :genotype, test_result: [:diagnostic_method]]
          ]
        ]
      )
      |> scope(user)
      |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
      |> Flop.filter(flop, opts)
      |> Repo.all()
      |> populate_virtual_fields()
      |> Enum.map(fn o ->
        [
          o.id,
          o.status,
          o.user && o.user.email,
          o.observation_date,
          o.suspected_pathology && o.suspected_pathology.common_name,
          o.host && o.host.common_name,
          o.host_variety && o.host_variety.name,
          o.location_type && o.location_type.name,
          o.organic,
          o.latitude,
          o.longitude,
          o.country && o.country.name,
          o.primary_subdivision && o.primary_subdivision.name,
          o.secondary_subdivision && o.secondary_subdivision.name,
          o.control_method,
          o.notes,
          o.data_source,
          o.sample && o.sample.result,
          o.sample && o.sample.comments,
          o.sample && o.sample.pathology && o.sample.pathology.common_name,
          o.sample && o.sample.genotype && o.sample.genotype.name
        ]
      end)

    [
      [
        "id",
        "status",
        "user",
        "observation_date",
        "suspected_pathology",
        "host",
        "host_variety",
        "location_type",
        "organic",
        "latitude",
        "longitude",
        "country",
        "primary_subdivision",
        "secondary_subdivision",
        "control_method",
        "notes",
        "data_source",
        "sample_result",
        "sample_comments",
        "sample_pathology",
        "sample_genotype"
      ]
      | observations
    ]
    |> CSV.dump_to_iodata()
  end

  def export_observations(%User{} = user, %{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Observation) do
      {:ok, export_observations(user, flop)}
    end
  end

  defp scope(query, %User{} = user) do
    case User.has_role?(user, [:superuser, :admin, :researcher]) do
      true ->
        query

      _ ->
        where(query, user_id: ^user.id)
    end
  end

  defp join_observation_assocs(query, :user) do
    from(
      o in query,
      left_join: u in assoc(o, :user),
      as: :user
    )
  end

  defp join_observation_assocs(query, :sample) do
    from(
      o in query,
      left_join: s in assoc(o, :sample),
      as: :sample
    )
  end

  @doc """
  Gets a single observation.

  Raises `Ecto.NoResultsError` if the Observation does not exist.

  ## Examples

      iex> get_observation!(123)
      %Observation{}

      iex> get_observation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_observation!(id) do
    Repo.get!(Observation, id)
    |> preload()
    |> populate_virtual_fields()
  end

  @doc """
  Creates a observation.

  ## Examples

      iex> create_observation(%{field: value})
      {:ok, %Observation{}}

      iex> create_observation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_observation(%User{} = user, attrs \\ %{}, after_save \\ &{:ok, &1}) do
    %Observation{}
    |> Observation.changeset(attrs)
    |> Observation.put_user(user)
    |> Repo.insert()
    |> preload()
    |> populate_virtual_fields()
    |> after_save(after_save)
  end

  @doc """
  Updates a observation.

  ## Examples

      iex> update_observation(observation, %{field: new_value})
      {:ok, %Observation{}}

      iex> update_observation(observation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_observation(%Observation{} = observation, attrs, after_save \\ &{:ok, &1}) do
    observation
    |> Observation.changeset(attrs)
    |> Repo.update()
    |> preload()
    |> populate_virtual_fields()
    |> after_save(after_save)
  end

  defp after_save({:ok, observation}, func) do
    {:ok, _observation} = func.(observation)
  end

  defp after_save(error, _func), do: error

  @doc """
  Deletes a observation.

  ## Examples

      iex> delete_observation(observation)
      {:ok, %Observation{}}

      iex> delete_observation(observation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_observation(%Observation{} = observation) do
    Repo.delete(observation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking observation changes.

  ## Examples

      iex> change_observation(observation)
      %Ecto.Changeset{data: %Observation{}}

  """
  def change_observation(%Observation{} = observation, attrs \\ %{}) do
    Observation.changeset(observation, attrs)
  end

  def preload({:ok, struct}) do
    {:ok, preload(struct)}
  end

  def preload({:error, _} = resp) do
    resp
  end

  def preload({observations, meta}) do
    {
      preload(observations),
      meta
    }
  end

  def preload(observation_or_observations) do
    Repo.preload(observation_or_observations, [
      :user,
      :host,
      :host_variety,
      :location_type,
      :suspected_pathology,
      :country,
      :primary_subdivision,
      :secondary_subdivision,
      sample: [:pathology, :genotype],
      test_results: [
        :diagnostic_method,
        pathology_results: [:pathology, :genotype, test_result: [:diagnostic_method]]
      ]
    ])
  end

  def populate_virtual_fields({:ok, observation}) do
    {:ok, populate_virtual_fields(observation)}
  end

  def populate_virtual_fields({:error, _} = resp) do
    resp
  end

  def populate_virtual_fields({observations, meta}) do
    {
      Enum.map(observations, &populate_virtual_fields/1),
      meta
    }
  end

  def populate_virtual_fields(%Observation{} = observation) do
    observation
    # |> Repo.preload([:country, :primary_subdivision, :secondary_subdivision])
    |> maybe_populate_lat_long()
    |> maybe_populate_location()
    |> add_data_source()
  end

  def populate_virtual_fields(observations) do
    Enum.map(observations, &populate_virtual_fields/1)
  end

  defp maybe_populate_lat_long(%Observation{position: %{coordinates: {long, lat}}} = observation) do
    %{observation | latitude: lat, longitude: long}
  end

  defp maybe_populate_lat_long(%Observation{} = observation) do
    observation
  end

  defp maybe_populate_location(
         %Observation{country: nil, primary_subdivision: nil, secondary_subdivision: nil} =
           observation
       ) do
    observation
  end

  defp maybe_populate_location(
         %Observation{country: country, primary_subdivision: nil, secondary_subdivision: nil} =
           observation
       ) do
    %{observation | location: country.name}
  end

  defp maybe_populate_location(
         %Observation{
           country: country,
           primary_subdivision: primary_subdivision,
           secondary_subdivision: nil
         } = observation
       ) do
    %{observation | location: "#{primary_subdivision.name}, #{country.iso3166_1_alpha2}"}
  end

  defp maybe_populate_location(
         %Observation{
           country: country,
           primary_subdivision: primary_subdivision,
           secondary_subdivision: secondary_subdivision
         } = observation
       ) do
    [_, psd_abbreviation] = String.split(primary_subdivision.iso3166_2, "-")

    %{
      observation
      | location:
          "#{secondary_subdivision.name} #{secondary_subdivision.category}, #{psd_abbreviation}, #{country.iso3166_1_alpha2}"
    }
  end

  defp add_data_source(%Observation{source: :plant_aid} = observation) do
    %{observation | data_source: "PlantAid"}
  end

  defp add_data_source(%Observation{source: :usa_blight} = observation) do
    %{observation | data_source: "USA Blight"}
  end

  defp add_data_source(%Observation{source: :npdn} = observation) do
    %{observation | data_source: "National Plant Diagnostic Network"}
  end

  defp add_data_source(%Observation{source: :cucurbit_sentinel_network} = observation) do
    %{observation | data_source: "Cucurbit Sentinel Network"}
  end

  alias PlantAid.Observations.Sample

  @doc """
  Returns the list of samples.

  ## Examples

      iex> list_samples()
      [%Sample{}, ...]

  """
  def list_samples do
    Repo.all(Sample)
  end

  @doc """
  Gets a single sample.

  Raises `Ecto.NoResultsError` if the Sample does not exist.

  ## Examples

      iex> get_sample!(123)
      %Sample{}

      iex> get_sample!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sample!(id), do: Repo.get!(Sample, id)

  def get_sample_by_observation_id!(observation_id) do
    Repo.get_by!(Sample, observation_id: observation_id)
  end

  @doc """
  Creates a sample.

  ## Examples

      iex> create_sample(%{field: value})
      {:ok, %Sample{}}

      iex> create_sample(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sample(observation_id, attrs \\ %{}) do
    %Sample{observation_id: observation_id}
    |> Sample.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sample.

  ## Examples

      iex> update_sample(sample, %{field: new_value})
      {:ok, %Sample{}}

      iex> update_sample(sample, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sample(%Sample{} = sample, attrs) do
    sample
    |> Sample.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sample.

  ## Examples

      iex> delete_sample(sample)
      {:ok, %Sample{}}

      iex> delete_sample(sample)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sample(%Sample{} = sample) do
    Repo.delete(sample)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sample changes.

  ## Examples

      iex> change_sample(sample)
      %Ecto.Changeset{data: %Sample{}}

  """
  def change_sample(%Sample{} = sample, attrs \\ %{}) do
    Sample.changeset(sample, attrs)
  end
end
