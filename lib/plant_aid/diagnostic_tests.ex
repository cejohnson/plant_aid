defmodule PlantAid.DiagnosticTests do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias PlantAid.Observations.Observation
  alias PlantAid.ObjectStorage
  alias Ecto.Changeset
  alias PlantAid.Repo
  alias PlantAid.Accounts.User
  alias PlantAid.DiagnosticMethods
  alias PlantAid.DiagnosticTests.Field
  alias PlantAid.DiagnosticTests.PathologyResult
  alias PlantAid.DiagnosticTests.TestResult

  def authorize(:list_test_results, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:create_test_result, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:get_test_result, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:update_test_result, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  def authorize(:delete_test_result, %User{} = user, _) do
    User.has_role?(user, [:superuser, :admin, :researcher])
  end

  @doc """
  Returns the list of test_results.

  ## Examples

      iex> list_test_results()
      [%TestResult{}, ...]

  """
  def list_test_results(%User{} = user) do
    list_test_results(user, %Flop{})
  end

  def list_test_results(%User{} = user, %Flop{} = flop) do
    opts = [for: TestResult]

    from(
      tr in TestResult,
      preload: [
        :inserted_by,
        :updated_by,
        :diagnostic_method,
        pathology_results: [:genotype, pathology: [:genotypes]],
        observation: [:host, :user]
      ]
    )
    |> scope(user)
    |> Flop.with_named_bindings(flop, &join_assocs/2, opts)
    |> Flop.run(flop, opts)
    |> populate_virtual_fields()
  end

  def list_test_results(%User{} = user, %{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: TestResult) do
      {:ok, list_test_results(user, flop)}
    end
  end

  defp scope(query, %User{} = user) do
    case User.has_role?(user, [:superuser, :admin, :researcher]) do
      true ->
        query

      _ ->
        from(
          tr in query,
          inner_join: o in assoc(tr, :observation),
          where: o.user_id == ^user.id
        )
    end
  end

  defp join_assocs(query, :observation) do
    from(
      tr in query,
      left_join: o in assoc(tr, :observation),
      as: :observation
    )
  end

  defp join_assocs(query, :pathology_results) do
    from(
      tr in query,
      left_join: pr in assoc(tr, :pathology_results),
      as: :pathology_results
    )
  end

  @doc """
  Gets a single test_result.

  Raises `Ecto.NoResultsError` if the Diagnostic method does not exist.

  ## Examples

      iex> get_test_result!(123)
      %TestResult{}

      iex> get_test_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_test_result!(id) do
    Repo.get!(TestResult, id)
    |> preload()
    |> populate_virtual_fields()
  end

  @doc """
  Creates a test_result.

  ## Examples

      iex> create_test_result(%{field: value})
      {:ok, %TestResult{}}

      iex> create_test_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_test_result(
        user,
        changeset,
        opts \\ []
      ) do
    after_save = Keyword.get(opts, :after_save, &{:ok, &1})
    notify_reporter = Keyword.get(opts, :notify_reporter)
    create_alerts = Keyword.get(opts, :create_alerts)

    changeset
    |> Changeset.put_change(:inserted_by_id, user.id)
    |> Changeset.put_change(:updated_by_id, user.id)
    |> Repo.insert()
    |> preload()
    |> populate_virtual_fields()
    |> after_save(after_save)
    |> notify_reporter(notify_reporter, "created")
    |> create_alerts(create_alerts)
  end

  @doc """
  Updates a test_result.

  ## Examples

      iex> update_test_result(test_result, %{field: new_value})
      {:ok, %TestResult{}}

      iex> update_test_result(test_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_test_result(
        user,
        changeset,
        opts \\ []
      ) do
    after_save = Keyword.get(opts, :after_save, &{:ok, &1})
    notify_reporter = Keyword.get(opts, :notify_reporter, "true")
    create_alerts = Keyword.get(opts, :create_alerts, "true")

    changeset
    |> drop_deleted_values()
    |> Changeset.put_change(:updated_by_id, user.id)
    |> Repo.update()
    |> preload()
    |> populate_virtual_fields()
    |> cleanup_deleted_images(changeset.data)
    |> after_save(after_save)
    |> notify_reporter(notify_reporter, "updated")
    |> create_alerts(create_alerts)
  end

  @doc """
  Deletes a test_result.

  ## Examples

      iex> delete_test_result(test_result)
      {:ok, %TestResult{}}

      iex> delete_test_result(test_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_test_result(%TestResult{} = test_result) do
    Repo.delete(test_result)
    delete_all_images(test_result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking test_result changes.

  ## Examples

      iex> change_test_result(test_result)
      %Ecto.Changeset{data: %TestResult{}}

  """

  def change_test_result(%TestResult{} = test_result, attrs \\ %{}) do
    TestResult.changeset(test_result, attrs)
  end

  def change_test_result(
        %TestResult{} = test_result,
        nil,
        attrs
      ) do
    TestResult.changeset(test_result, attrs)
  end

  def change_test_result(
        %TestResult{} = test_result,
        %TestResult.Overrides{} = overrides,
        attrs
      ) do
    TestResult.changeset(test_result, overrides, attrs)
  end

  defp notify_reporter({:ok, test_result}, "true", event) do
    %{diagnostic_test_result_id: test_result.id, event: event}
    |> PlantAid.Workers.NotifyReporter.new()
    |> Oban.insert()

    {:ok, test_result}
  end

  defp notify_reporter(result, _, _) do
    result
  end

  defp create_alerts({:ok, test_result}, "true") do
    if Enum.any?(test_result.pathology_results, &(&1.result == :positive)) do
      %{diagnostic_test_result_id: test_result.id}
      |> PlantAid.Workers.CreateAlerts.new()
      |> Oban.insert()
    end

    {:ok, test_result}
  end

  defp create_alerts(result, _) do
    result
  end

  defp drop_deleted_values(changeset) do
    changeset =
      changeset
      |> Changeset.get_embed(:fields)
      |> Enum.map(&drop_deleted_field_values(&1))
      |> then(&Changeset.put_embed(changeset, :fields, &1))

    changeset
    |> Changeset.get_assoc(:pathology_results)
    |> Enum.map(fn pathology_result_changeset ->
      pathology_result_changeset
      |> Changeset.get_embed(:fields)
      |> Enum.map(&drop_deleted_field_values(&1))
      |> then(&Changeset.put_embed(pathology_result_changeset, :fields, &1))
    end)
    |> then(&Changeset.put_assoc(changeset, :pathology_results, &1))
  end

  defp drop_deleted_field_values(field_changeset) do
    field_changeset
    |> maybe_delete_value()
    |> maybe_drop_list_entries()
  end

  defp maybe_delete_value(field_changeset) do
    if Changeset.get_change(field_changeset, :delete) do
      Changeset.put_change(field_changeset, :value, nil)
    else
      field_changeset
    end
  end

  defp maybe_drop_list_entries(field_changeset) do
    list_entries = Changeset.get_embed(field_changeset, :list_entries)
    to_drop = Enum.filter(list_entries, &Changeset.get_field(&1, :delete))

    if length(to_drop) > 0 do
      Changeset.put_change(field_changeset, :list_entries, list_entries -- to_drop)
    else
      field_changeset
    end
  end

  defp delete_all_images(test_result) do
    test_result
    |> get_image_fields()
    |> delete_image_fields()
  end

  defp cleanup_deleted_images({:ok, new_test_result}, old_test_result) do
    new_image_fields = get_image_fields(new_test_result)
    old_image_fields = get_image_fields(old_test_result)

    delete_image_fields(old_image_fields -- new_image_fields, new_image_fields)

    {:ok, new_test_result}
  end

  defp cleanup_deleted_images({:error, _} = resp, _) do
    resp
  end

  defp get_image_fields(test_result) do
    test_result.pathology_results
    |> Enum.map(& &1.fields)
    |> List.flatten()
    |> Enum.concat(test_result.fields)
    |> Enum.filter(&(&1.type == :image or &1.subtype == :image))
  end

  defp delete_image_fields(fields, updated_fields \\ []) do
    fields
    |> Enum.map(fn field ->
      case field.type do
        :image ->
          field.value

        :list ->
          case Enum.find(updated_fields, &(&1.id == field.id)) do
            nil ->
              field.list_entries

            updated_field ->
              field.list_entries -- updated_field.list_entries
          end
          |> Enum.map(& &1.value)
      end
    end)
    |> List.flatten()
    |> ObjectStorage.delete_objects()
  end

  defp after_save({:ok, test_result}, func) do
    {:ok, _test_result} = func.(test_result)
  end

  defp after_save({:error, _} = resp, _func) do
    resp
  end

  def get_diagnostic_method_overrides(diagnostic_method_id) do
    diagnostic_method = DiagnosticMethods.get_diagnostic_method!(diagnostic_method_id)

    fields =
      diagnostic_method.fields
      |> Enum.reject(& &1.per_pathology)
      |> convert_fields()

    pathology_results =
      diagnostic_method.pathologies
      |> Enum.map(fn pathology ->
        fields =
          diagnostic_method.fields
          |> Enum.filter(& &1.per_pathology)
          |> convert_fields()

        %PathologyResult{
          pathology: pathology,
          fields: fields
        }
      end)

    %TestResult.Overrides{
      fields: fields,
      pathology_results: pathology_results
    }
  end

  def convert_fields(fields) do
    fields
    |> Enum.map(fn field ->
      %Field{
        id: Ecto.UUID.autogenerate(),
        name: field.name,
        description: field.description,
        type: field.type,
        subtype: field.subtype,
        select_options: field.select_options
      }
    end)
  end

  def preload({:ok, struct}) do
    {:ok, preload(struct)}
  end

  def preload({:error, _} = resp) do
    resp
  end

  def preload({test_results, meta}) do
    {
      preload(test_results),
      meta
    }
  end

  def preload(test_result_or_results) do
    Repo.preload(test_result_or_results, [
      :inserted_by,
      :updated_by,
      :diagnostic_method,
      pathology_results: [:genotype, pathology: [:genotypes]],
      observation: [:user, :host, :suspected_pathology]
    ])
  end

  def populate_virtual_fields({:ok, struct}) do
    {:ok, populate_virtual_fields(struct)}
  end

  def populate_virtual_fields({:error, _} = resp) do
    resp
  end

  def populate_virtual_fields({test_results, meta}) do
    {
      Enum.map(test_results, &populate_virtual_fields/1),
      meta
    }
  end

  def populate_virtual_fields(%TestResult{} = test_result) do
    test_result
    |> maybe_populate_observation_id()
  end

  defp maybe_populate_observation_id(
         %TestResult{observation: %Observation{} = observation} = test_result
       ) do
    %{test_result | observation_id: observation.id}
  end

  defp maybe_populate_observation_id(%TestResult{} = test_result) do
    test_result
  end
end
