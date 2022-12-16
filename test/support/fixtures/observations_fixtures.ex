defmodule PlantAid.ObservationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Observations` context.
  """

  @doc """
  Generate a observation.
  """
  def observation_fixture(attrs \\ %{}) do
    {:ok, observation} =
      attrs
      |> Enum.into(%{
        control_method: "some control_method",
        host_other: "some host_other",
        metadata: %{},
        notes: "some notes",
        observation_date: ~U[2022-12-05 23:29:00Z],
        organic: true,
        position: "some position"
      })
      |> PlantAid.Observations.create_observation()

    observation
  end
end
