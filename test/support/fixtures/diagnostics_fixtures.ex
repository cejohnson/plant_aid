defmodule PlantAid.DiagnosticsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Diagnostics` context.
  """

  @doc """
  Generate a diagnostic_method.
  """
  def diagnostic_method_fixture(attrs \\ %{}) do
    {:ok, diagnostic_method} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> PlantAid.Diagnostics.create_diagnostic_method()

    diagnostic_method
  end
end
