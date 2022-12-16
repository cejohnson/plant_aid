defmodule PlantAid.GenomicsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlantAid.Genotypes` context.
  """

  @doc """
  Generate a genotype.
  """
  def genotype_fixture(attrs \\ %{}) do
    {:ok, genotype} =
      attrs
      |> Enum.into(%{
        d13: "some d13",
        genotype: "some genotype",
        gpi: "some gpi",
        mating_type: "some mating_type",
        mef: "some mef",
        mtdna: "some mtdna",
        pep: "some pep",
        pi02: "some pi02",
        pi04: "some pi04",
        pi16: "some pi16",
        pi33: "some pi33",
        pi4b: "some pi4b",
        pi56: "some pi56",
        pi63: "some pi63",
        pi70: "some pi70",
        pi89: "some pi89",
        pig11: "some pig11",
        rg57: "some rg57",
        rg57_band_num: "some rg57_band_num"
      })
      |> PlantAid.Genomics.create_genotype()

    genotype
  end
end
