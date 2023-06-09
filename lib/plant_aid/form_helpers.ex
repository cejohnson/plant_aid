defmodule PlantAid.FormHelpers do
  import Ecto.Query

  alias PlantAid.Hosts.HostVariety
  alias PlantAid.Repo

  alias PlantAid.Geography.{Country, PrimarySubdivision, SecondarySubdivision}
  alias PlantAid.Hosts.Host
  alias PlantAid.LocationTypes.LocationType
  alias PlantAid.Pathologies.Pathology

  def list_country_options do
    from(
      c in Country,
      select: {c.name, c.id},
      order_by: c.name
    )
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

  def list_pathology_options do
    from(
      p in Pathology,
      select: {p.common_name, p.id},
      order_by: p.common_name
    )
    |> Repo.all()
  end
end
