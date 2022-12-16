defmodule PlantAid.PathologiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Pathologies` context.
  """

  @doc """
  Generate a pathology.
  """
  def pathology_fixture(attrs \\ %{}) do
    {:ok, pathology} =
      attrs
      |> Enum.into(%{
        common_name: "some common_name",
        scientific_name: "some scientific_name"
      })
      |> PlantAid.Pathologies.create_pathology()

    pathology
  end
end
