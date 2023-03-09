defmodule PlantAid.Geography do
  @moduledoc """
  The Geography context.
  """

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Geography.{
    County,
    Country,
    PrimarySubdivision,
    SecondarySubdivision
  }

  # def list_countries do
  #   Repo.all(Country)
  # end

  # def list_countries(flop \\ %Flop{}, [paginate: false] = opts) do
  #   Country
  #   |> Flop.filter(flop, opts)
  #   |> Flop.order_by(flop, opts)
  #   |> Flop.p
  #   |> Repo.all()
  # end

  # def list_countries(flop \\ %Flop{}, opts \\ []) do
  #   Country
  #     |> Flop.filter(flop, opts)
  #     |> Flop.order_by(flop, opts)
  #     |> Repo.all()
  # end

  def list_countries(flop \\ %Flop{}, opts \\ []) do
    Repo.list_all(Country, flop, opts)
    # {query, opts} = generate_select(Country, opts)
    # countries = Flop.all(query, flop, opts)
  end

  def list_primary_subdivisions(flop \\ %Flop{}, opts \\ []) do
    Repo.list_all(PrimarySubdivision, flop, opts)
    # {query, opts} = generate_select(PrimarySubdivision, opts)
    # Flop.run(query, flop, opts)
  end

  def list_secondary_subdivisions(flop \\ %Flop{}, opts \\ []) do
    Repo.list_all(SecondarySubdivision, flop, opts)
    # {query, opts} = generate_select(SecondarySubdivision, opts)
    # Flop.run(query, flop, opts)
  end

  # def paginate_countries(flop \\ %Flop{}, opts \\ []) do
  #   Flop.run(query, flop, opts)
  # end

  # def paginate(query, flop \\ %Flop{}, opts \\ []) do
  # end

  def list(query, flop \\ %Flop{}, opts \\ []) do
    {pr, opts} = Keyword.pop(opts, :preload)
    {include_fields, opts} = Keyword.pop(opts, :include_fields)
    {include_meta?, opts} = Keyword.pop(opts, :include_meta, true)

    query =
      if pr do
        preload(query, ^pr)
      else
        query
      end

    query =
      if include_fields do
        select(query, ^include_fields)
      else
        query
      end

    results = Flop.all(query, flop, opts)

    if include_meta? do
      meta = Flop.meta(query, flop, opts)
      {results, meta}
    else
      results
    end
  end

  # def list_countries(flop \\ %Flop{}, opts \\ []) do
  #   {paginate?, opts} = Keyword.pop(opts, :paginate, false)
  #   {meta?, opts} = Keyword.pop(opts, :meta, paginate?)

  #   opts = Keyword.put(opts, :for, Country)

  #   query =
  #     Country
  #     |> Flop.filter(flop, opts)
  #     |> Flop.order_by(flop, opts)

  #   query =
  #     if paginate? do
  #       query
  #       |> Flop.paginate(flop, opts)
  #     else
  #       query
  #     end

  #   results = Repo.all(query)

  #   if meta? do
  #     meta = Flop.meta(query, flop, opts)
  #     {results, meta}
  #   else
  #     results
  #   end
  # end

  # def list_primary_subdivisions(flop \\ %Flop{}, opts \\ []) do
  #   {paginate?, opts} = Keyword.pop(opts, :paginate, false)
  #   {meta?, opts} = Keyword.pop(opts, :meta, paginate?)

  #   opts = Keyword.put(opts, :for, PrimarySubdivision)

  #   query =
  #     PrimarySubdivision
  #     |> Flop.filter(flop, opts)
  #     |> Flop.order_by(flop, opts)

  #   query =
  #     if paginate? do
  #       query
  #       |> Flop.paginate(flop, opts)
  #     else
  #       query
  #     end

  #   results =
  #     Repo.all(query)
  #     |> Repo.preload(:country)

  #   if meta? do
  #     meta = Flop.meta(query, flop, opts)
  #     {results, meta}
  #   else
  #     results
  #   end
  # end

  # def list_secondary_subdivisions(flop \\ %Flop{}, opts \\ []) do
  #   {paginate?, opts} = Keyword.pop(opts, :paginate, false)
  #   {meta?, opts} = Keyword.pop(opts, :meta, paginate?)
  #   {include_geometry?, opts} = Keyword.pop(opts, :include_geometry, false)

  #   opts = Keyword.put(opts, :for, SecondarySubdivision)

  #   query =
  #     if include_geometry? do
  #       SecondarySubdivision
  #     else
  #       from(
  #         s in SecondarySubdivision,
  #         select: %{s | geog: nil}
  #       )
  #     end

  #   query =
  #     query
  #     |> Flop.filter(flop, opts)
  #     |> Flop.order_by(flop, opts)

  #   query =
  #     if paginate? do
  #       query
  #       |> Flop.paginate(flop, opts)
  #     else
  #       query
  #     end

  #   results =
  #     Repo.all(query)
  #     |> Repo.preload(primary_subdivision: :country)

  #   if meta? do
  #     meta = Flop.meta(query, flop, opts)
  #     {results, meta}
  #   else
  #     results
  #   end
  # end

  def generate_select(query, opts) do
    {pr, opts} = Keyword.pop(opts, :preload)
    {include_fields, opts} = Keyword.pop(opts, :include_fields)
    # exclude = Keyword.pop(opts, :exclude)

    query =
      if pr do
        preload(query, ^pr)
      else
        query
      end

    query =
      if include_fields do
        select(query, ^include_fields)
      else
        query
      end

    # query =
    #   cond do
    #     include ->
    #       select(query, ^include)

    #     # exclude ->
    #     #   exclude_map = Enum.map(exclude, &{&1, nil}) |> Map.new()
    #     #   select(query, [item], %{item | })

    #     true ->
    #       select(query, [item], item)
    #   end

    {query, opts}
  end

  # def list_secondary_subdivisions do
  #   from(ssd in SecondarySubdivision,
  #     left_join: psd in PrimarySubdivision,
  #     on: ssd.primary_subdivision_id == psd.id,
  #     left_join: c in Country,
  #     on: psd.country_id == c.id,
  #     preload: [primary_subdivision: psd, country: c]
  #   )
  #   |> Repo.all()

  #   # |> Repo.preload([:primary_subdivision])
  # end

  # def list_secondary_subdivisions(params, opts \\ []) do
  #   observation_count_query =
  #     from(
  #       o in Observation,
  #       group_by: o.secondary_subdivision_id,
  #       select: %{secondary_subdivision_id: o.secondary_subdivision_id, count: count(o.id)}
  #     )

  #   from(
  #     asdf in subquery(observation_count_query),
  #     inner_join: ssd in SecondarySubdivision,
  #     on: asdf.secondary_subdivision_id == ssd.id,
  #     preload: [secondary_subdivision: [primary_subdivision: :country]]
  #   )

  #   # from(
  #   #   ssd in SecondarySubdivision,
  #   #   as: :ssd,
  #   #   # left_lateral_join: oc in subquery(observation_count_query),
  #   #   # as: :observation_count,
  #   #   join: psd in assoc(ssd, :primary_subdivision),
  #   #   as: :primary_subdivision,
  #   #   join: c in assoc(psd, :country),
  #   #   as: :country,
  #   #   left_join: o in assoc(ssd, :observations),
  #   #   as: :observations,
  #   #   group_by: ssd.id,
  #   #   select: %{
  #   #     ssd
  #   #     | geog: nil,
  #   #       observation_count: count(o.id) |> selected_as(:observation_count)
  #   #   },
  #   #   preload: [primary_subdivision: :country]
  #   # )
  #   # |> Flop.validate_and_run(params, for: SecondarySubdivision)

  #   # observation_count_query =
  #   #   from(
  #   #     o in Observation,
  #   #     where: parent_as(:ssd).id == o.secondary_subdivision_id,
  #   #     select: %{count: count(o.id)}
  #   #   )

  #   # from(
  #   #   ssd in SecondarySubdivision,
  #   #   as: :ssd,
  #   #   left_lateral_join: oc in subquery(observation_count_query),
  #   #   as: :observation_count,
  #   #   join: psd in assoc(ssd, :primary_subdivision),
  #   #   as: :primary_subdivision,
  #   #   join: c in assoc(psd, :country),
  #   #   as: :country,
  #   #   # left_join: o in assoc(ssd, :observations),
  #   #   # as: :observations,
  #   #   select: %{ssd | geog: nil, observation_count: oc.count},
  #   #   preload: [primary_subdivision: :country]
  #   # )
  #   # |> Flop.validate_and_run(params, for: SecondarySubdivision)

  #   # observation_count_query =
  #   #   from(
  #   #     o in Observation,
  #   #     where: parent_as(:secondary_subdivision).id == o.secondary_subdivision_id,
  #   #     select: %{count: count(o.id)}
  #   #   )

  #   # query =
  #   #   from(
  #   #     ssd in SecondarySubdivision,
  #   #     as: :secondary_subdivision,
  #   #     join: psd in assoc(ssd, :primary_subdivision),
  #   #     as: :primary_subdivision,
  #   #     join: c in assoc(psd, :country),
  #   #     as: :country,
  #   #     # join: o in assoc(ssd, :observations),
  #   #     # as: :observations,
  #   #     inner_lateral_join: oc in subquery(observation_count_query),
  #   #     as: :observation_count,
  #   #     select: %{ssd | observation_count: oc.count},
  #   #     preload: [primary_subdivision: {psd, country: c}]
  #   #   )

  #   # paginate? = Keyword.get(opts, :paginate, true)

  #   # if paginate? do
  #   #   Flop.validate_and_run(query, params, for: SecondarySubdivision)
  #   # else
  #   #   # flop = %Flop{filters: flop.filters}
  #   #   # Flop.validate_and_run(query, params, for: SecondarySubdivision)
  #   #   with {:ok, flop} <- Flop.validate(params, for: SecondarySubdivision) do
  #   #     IO.inspect(flop, label: "flop")
  #   #     # flop = %Flop{filters: flop.filters}
  #   #     flop = %{
  #   #       flop
  #   #       | limit: nil,
  #   #         page: nil,
  #   #         page_size: nil,
  #   #         order_by: nil,
  #   #         order_directions: nil
  #   #     }

  #   #     IO.inspect(flop, label: "flop2")
  #   #     Flop.run(query, flop, for: SecondarySubdivision)
  #   #     # Flop.all(query, flop)
  #   #   end
  #   # end
  # end

  @doc """
  Returns the list of counties.

  ## Examples

      iex> list_counties()
      [%County{}, ...]

  """
  def list_counties do
    Repo.all(County)
  end

  @doc """
  Gets a single county.

  Raises `Ecto.NoResultsError` if the County does not exist.

  ## Examples

      iex> get_county!(123)
      %County{}

      iex> get_county!(456)
      ** (Ecto.NoResultsError)

  """
  def get_county!(id), do: Repo.get!(County, id)

  @doc """
  Creates a county.

  ## Examples

      iex> create_county(%{field: value})
      {:ok, %County{}}

      iex> create_county(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_county(attrs \\ %{}) do
    %County{}
    |> County.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a county.

  ## Examples

      iex> update_county(county, %{field: new_value})
      {:ok, %County{}}

      iex> update_county(county, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_county(%County{} = county, attrs) do
    county
    |> County.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a county.

  ## Examples

      iex> delete_county(county)
      {:ok, %County{}}

      iex> delete_county(county)
      {:error, %Ecto.Changeset{}}

  """
  def delete_county(%County{} = county) do
    Repo.delete(county)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking county changes.

  ## Examples

      iex> change_county(county)
      %Ecto.Changeset{data: %County{}}

  """
  def change_county(%County{} = county, attrs \\ %{}) do
    County.changeset(county, attrs)
  end
end
