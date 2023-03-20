defmodule PlantAid.Geography do
  @moduledoc """
  The Geography context.
  """

  import Ecto.Query, warn: false

  alias PlantAid.Geography.{
    Country,
    PrimarySubdivision,
    SecondarySubdivision
  }

  def list_countries do
    list_countries(%Flop{})
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
    list_primary_subdivisions(%Flop{})
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
    list_secondary_subdivisions(%Flop{})
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
end
