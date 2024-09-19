defmodule PlantAid.Geography do
  @moduledoc """
  The Geography context.
  """

  import Ecto.Query, warn: false
  alias PlantAid.Repo

  alias PlantAid.Geography.{
    Country,
    PrimarySubdivision,
    SecondarySubdivision
  }

  def list_countries do
    Repo.all(Country)
  end

  def list_countries(%Flop{} = flop) do
    Flop.run(Country, flop)
  end

  def list_countries(%{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: Country) do
      {:ok, list_countries(flop)}
    end
  end

  def list_primary_subdivisions do
    Repo.all(PrimarySubdivision)
  end

  def list_primary_subdivisions(%Flop{} = flop) do
    Flop.run(PrimarySubdivision, flop)
  end

  def list_primary_subdivisions(%{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: PrimarySubdivision) do
      {:ok, list_primary_subdivisions(flop)}
    end
  end

  def list_secondary_subdivisions do
    Repo.all(SecondarySubdivision)
  end

  def list_secondary_subdivisions(%Flop{} = flop) do
    from(
      s in SecondarySubdivision,
      select: %{s | geog: nil}
    )
    |> Flop.run(flop)
  end

  def list_secondary_subdivisions(%{} = params) do
    with {:ok, flop} <- Flop.validate(params, for: SecondarySubdivision) do
      {:ok, list_secondary_subdivisions(flop)}
    end
  end

  def find_secondary_subdivision_containing_point(%Geo.Point{} = point) do
    from(
      s in SecondarySubdivision,
      where: fragment("ST_Covers(?, ?)", s.geog, ^point),
      select: %{s | geog: nil}
    )
    |> Repo.one()
    |> Repo.preload(primary_subdivision: :country)
  end

  def pretty_print(%Country{name: name}) do
    name
  end

  def pretty_print(%PrimarySubdivision{name: name, country: %Country{iso3166_1_alpha3: country}}) do
    "#{name}, #{country}"
  end

  def pretty_print(%SecondarySubdivision{
        name: name,
        category: category,
        primary_subdivision: %PrimarySubdivision{
          iso3166_2: primary_subdivision,
          country: %Country{iso3166_1_alpha2: country}
        }
      }) do
    "#{name} #{category}, #{String.slice(primary_subdivision, 3..5)}, #{country}"
  end
end
