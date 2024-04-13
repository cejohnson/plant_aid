defmodule PlantAid.LocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Locations` context.
  """

  @doc """
  Generate a location.
  """
  def location_fixture(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{
        name: "some name",
        position: "some position"
      })
      |> PlantAid.Locations.create_location()

    location
  end
end
