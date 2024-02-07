defmodule PlantAid.FormHelpers do
  import Ecto.Query

  alias PlantAid.Hosts.HostVariety
  alias PlantAid.Repo

  alias PlantAid.Geography.{Country, PrimarySubdivision, SecondarySubdivision}
  alias PlantAid.Hosts.Host
  alias PlantAid.LocationTypes.LocationType
  alias PlantAid.Pathologies.{Pathology, Genotype}
  alias PlantAid.Observations.Observation

  def list_organic_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :organic)}

    from(
      o in Observation,
      distinct: true,
      select: o.organic,
      order_by: [desc: o.organic]
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
    |> Enum.map(fn o ->
      case o do
        true ->
          {"Organic", true}

        false ->
          {"Not Organic", false}
      end
    end)
  end

  def list_country_options do
    from(
      c in Country,
      select: {c.name, c.id},
      order_by: c.name
    )
    |> Repo.all()
  end

  def list_country_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :country_id)}

    from(
      o in Observation,
      inner_join: c in assoc(o, :country),
      distinct: true,
      select: {c.name, c.id},
      order_by: c.name
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
  end

  def list_primary_subdivision_options do
    from(
      p in PrimarySubdivision,
      select: {p.name, p.id},
      order_by: p.name
    )
    |> Repo.all()
  end

  def list_primary_subdivision_options(nil) do
    []
  end

  def list_primary_subdivision_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :primary_subdivision_id)}

    from(
      o in Observation,
      inner_join: p in assoc(o, :primary_subdivision),
      distinct: true,
      select: {p.name, p.id},
      order_by: p.name
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
  end

  def list_primary_subdivision_options(country_id) do
    from(
      p in PrimarySubdivision,
      where: p.country_id == ^country_id,
      select: {p.name, p.id},
      order_by: p.name
    )
    |> Repo.all()
  end

  def list_primary_subdivision_categories(country_id) do
    from(
      p in PrimarySubdivision,
      where: p.country_id == ^country_id,
      group_by: p.category,
      order_by: [desc: count(p.category)],
      select: p.category
    )
    |> Repo.all()
  end

  def list_secondary_subdivision_options do
    from(
      s in SecondarySubdivision,
      select: {s.name, s.id},
      order_by: s.name
    )
    |> Repo.all()
  end

  def list_secondary_subdivision_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :secondary_subdivision_id)}

    from(
      o in Observation,
      inner_join: s in assoc(o, :secondary_subdivision),
      distinct: true,
      select: {s.name, s.id},
      order_by: s.name
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
  end

  def list_secondary_subdivision_options(nil) do
    []
  end

  def list_secondary_subdivision_options(primary_subdivision_id) do
    from(
      s in SecondarySubdivision,
      where: s.primary_subdivision_id == ^primary_subdivision_id,
      select: {s.name, s.id},
      order_by: s.name
    )
    |> Repo.all()
  end

  def list_secondary_subdivision_categories(primary_subdivision_id) do
    from(
      s in SecondarySubdivision,
      where: s.primary_subdivision_id == ^primary_subdivision_id,
      group_by: s.category,
      order_by: [desc: count(s.category)],
      select: s.category
    )
    |> Repo.all()
  end

  def list_host_options do
    from(
      h in Host,
      select: {h.common_name, h.id},
      order_by: h.common_name
    )
    |> Repo.all()
  end

  def list_host_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :host_id)}

    from(
      o in Observation,
      inner_join: h in assoc(o, :host),
      distinct: true,
      select: {h.common_name, h.id},
      order_by: h.common_name
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
  end

  def list_host_variety_options(nil) do
    []
  end

  def list_host_variety_options(host_id) do
    from(
      h in HostVariety,
      where: h.host_id == ^host_id,
      select: {h.name, h.id},
      order_by: h.name
    )
    |> Repo.all()
  end

  def list_location_type_options do
    from(
      l in LocationType,
      select: {l.name, l.id},
      order_by: l.name
    )
    |> Repo.all()
  end

  def list_location_type_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :location_type_id)}

    from(
      o in Observation,
      inner_join: l in assoc(o, :location_type),
      distinct: true,
      select: {l.name, l.id},
      order_by: l.name
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
  end

  def list_pathology_options do
    from(
      p in Pathology,
      select: {p.common_name, p.id},
      order_by: p.common_name
    )
    |> Repo.all()
  end

  def list_pathology_options(%Flop{} = flop) do
    opts = [for: Observation]

    flop = %{flop | filters: Flop.Filter.delete(flop.filters, :suspected_pathology_id)}

    from(
      o in Observation,
      inner_join: p in assoc(o, :suspected_pathology),
      distinct: true,
      select: {p.common_name, p.id},
      order_by: p.common_name
    )
    |> Flop.with_named_bindings(flop, &join_observation_assocs/2, opts)
    |> Flop.filter(flop, opts)
    |> Repo.all()
  end

  def list_genotype_options(pathology_id) do
    from(
      g in Genotype,
      where: g.pathology_id == ^pathology_id,
      select: {g.name, g.id},
      order_by: g.name
    )
    |> Repo.all()
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
end
