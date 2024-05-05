defmodule PlantAid.AlertsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Alerts` context.
  """

  @doc """
  Generate an alert_criterion.
  """
  def alert_criterion_fixture(attrs \\ %{}) do
    {:ok, alert_criterion} =
      attrs
      |> Enum.into(%{
        active: true,
        distance: 120.5
      })
      |> PlantAid.Alerts.create_alert_criterion()

    alert_criterion
  end

  @doc """
  Generate a alert.
  """
  def alert_fixture(attrs \\ %{}) do
    {:ok, alert} =
      attrs
      |> Enum.into(%{
        viewed_at: ~N[2024-04-20 04:33:00]
      })
      |> PlantAid.Alerts.create_alert()

    alert
  end
end
