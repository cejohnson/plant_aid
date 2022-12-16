defmodule PlantAid.GenotypesTest do
  use PlantAid.DataCase

  alias PlantAid.Genomics

  describe "genotypes" do
    alias PlantAid.Genomics.Genotype

    import PlantAid.GenomicsFixtures

    @invalid_attrs %{
      d13: nil,
      genotype: nil,
      gpi: nil,
      mating_type: nil,
      mef: nil,
      mtdna: nil,
      pep: nil,
      pi02: nil,
      pi04: nil,
      pi16: nil,
      pi33: nil,
      pi4b: nil,
      pi56: nil,
      pi63: nil,
      pi70: nil,
      pi89: nil,
      pig11: nil,
      rg57: nil,
      rg57_band_num: nil
    }

    test "list_genotypes/0 returns all genotypes" do
      genotype = genotype_fixture()
      assert Genomics.list_genotypes() == [genotype]
    end

    test "get_genotype!/1 returns the genotype with given id" do
      genotype = genotype_fixture()
      assert Genomics.get_genotype!(genotype.id) == genotype
    end

    test "create_genotype/1 with valid data creates a genotype" do
      valid_attrs = %{
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
      }

      assert {:ok, %Genotype{} = genotype} = Genomics.create_genotype(valid_attrs)
      assert genotype.d13 == "some d13"
      assert genotype.genotype == "some genotype"
      assert genotype.gpi == "some gpi"
      assert genotype.mating_type == "some mating_type"
      assert genotype.mef == "some mef"
      assert genotype.mtdna == "some mtdna"
      assert genotype.pep == "some pep"
      assert genotype.pi02 == "some pi02"
      assert genotype.pi04 == "some pi04"
      assert genotype.pi16 == "some pi16"
      assert genotype.pi33 == "some pi33"
      assert genotype.pi4b == "some pi4b"
      assert genotype.pi56 == "some pi56"
      assert genotype.pi63 == "some pi63"
      assert genotype.pi70 == "some pi70"
      assert genotype.pi89 == "some pi89"
      assert genotype.pig11 == "some pig11"
      assert genotype.rg57 == "some rg57"
      assert genotype.rg57_band_num == "some rg57_band_num"
    end

    test "create_genotype/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Genomics.create_genotype(@invalid_attrs)
    end

    test "update_genotype/2 with valid data updates the genotype" do
      genotype = genotype_fixture()

      update_attrs = %{
        d13: "some updated d13",
        genotype: "some updated genotype",
        gpi: "some updated gpi",
        mating_type: "some updated mating_type",
        mef: "some updated mef",
        mtdna: "some updated mtdna",
        pep: "some updated pep",
        pi02: "some updated pi02",
        pi04: "some updated pi04",
        pi16: "some updated pi16",
        pi33: "some updated pi33",
        pi4b: "some updated pi4b",
        pi56: "some updated pi56",
        pi63: "some updated pi63",
        pi70: "some updated pi70",
        pi89: "some updated pi89",
        pig11: "some updated pig11",
        rg57: "some updated rg57",
        rg57_band_num: "some updated rg57_band_num"
      }

      assert {:ok, %Genotype{} = genotype} = Genomics.update_genotype(genotype, update_attrs)
      assert genotype.d13 == "some updated d13"
      assert genotype.genotype == "some updated genotype"
      assert genotype.gpi == "some updated gpi"
      assert genotype.mating_type == "some updated mating_type"
      assert genotype.mef == "some updated mef"
      assert genotype.mtdna == "some updated mtdna"
      assert genotype.pep == "some updated pep"
      assert genotype.pi02 == "some updated pi02"
      assert genotype.pi04 == "some updated pi04"
      assert genotype.pi16 == "some updated pi16"
      assert genotype.pi33 == "some updated pi33"
      assert genotype.pi4b == "some updated pi4b"
      assert genotype.pi56 == "some updated pi56"
      assert genotype.pi63 == "some updated pi63"
      assert genotype.pi70 == "some updated pi70"
      assert genotype.pi89 == "some updated pi89"
      assert genotype.pig11 == "some updated pig11"
      assert genotype.rg57 == "some updated rg57"
      assert genotype.rg57_band_num == "some updated rg57_band_num"
    end

    test "update_genotype/2 with invalid data returns error changeset" do
      genotype = genotype_fixture()
      assert {:error, %Ecto.Changeset{}} = Genomics.update_genotype(genotype, @invalid_attrs)
      assert genotype == Genomics.get_genotype!(genotype.id)
    end

    test "delete_genotype/1 deletes the genotype" do
      genotype = genotype_fixture()
      assert {:ok, %Genotype{}} = Genomics.delete_genotype(genotype)
      assert_raise Ecto.NoResultsError, fn -> Genomics.get_genotype!(genotype.id) end
    end

    test "change_genotype/1 returns a genotype changeset" do
      genotype = genotype_fixture()
      assert %Ecto.Changeset{} = Genomics.change_genotype(genotype)
    end
  end
end
