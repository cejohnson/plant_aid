defmodule PlantAid.GeographyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Geography` context.
  """

  @doc """
  Generate a county.
  """
  def county_fixture(attrs \\ %{}) do
    {:ok, county} =
      attrs
      |> Enum.into(%{
        geometry: "some geometry",
        name: "some name",
        state: "some state"
      })
      |> PlantAid.Geography.create_county()

    county
  end
end
