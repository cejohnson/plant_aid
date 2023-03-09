defmodule PlantAid.Filters do
  import Ecto.Query

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

  def list_host_options do
    from(
      h in Host,
      select: {h.common_name, h.id},
      order_by: h.common_name
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
