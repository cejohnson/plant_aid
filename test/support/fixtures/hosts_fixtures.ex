defmodule PlantAid.HostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Hosts` context.
  """

  @doc """
  Generate a host.
  """
  def host_fixture(attrs \\ %{}) do
    {:ok, host} =
      attrs
      |> Enum.into(%{
        common_name: "some common_name",
        scientific_name: "some scientific_name"
      })
      |> PlantAid.Hosts.create_host()

    host
  end

  # @doc """
  # Generate a host_variety.
  # """
  # def host_variety_fixture(attrs \\ %{}) do
  #   {:ok, host_variety} =
  #     attrs
  #     |> Enum.into(%{
  #       name: "some name"
  #     })
  #     |> PlantAid.Hosts.create_host_variety()

  #   host_variety
  # end
end
