defmodule PlantAid.PathologiesTest do
  use PlantAid.DataCase

  alias PlantAid.Pathologies

  describe "pathologies" do
    alias PlantAid.Pathologies.Pathology

    import PlantAid.PathologiesFixtures

    @invalid_attrs %{common_name: nil, scientific_name: nil}

    test "list_pathologies/0 returns all pathologies" do
      pathology = pathology_fixture()
      assert Pathologies.list_pathologies() == [pathology]
    end

    test "get_pathology!/1 returns the pathology with given id" do
      pathology = pathology_fixture()
      assert Pathologies.get_pathology!(pathology.id) == pathology
    end

    test "create_pathology/1 with valid data creates a pathology" do
      valid_attrs = %{common_name: "some common_name", scientific_name: "some scientific_name"}

      assert {:ok, %Pathology{} = pathology} = Pathologies.create_pathology(valid_attrs)
      assert pathology.common_name == "some common_name"
      assert pathology.scientific_name == "some scientific_name"
    end

    test "create_pathology/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pathologies.create_pathology(@invalid_attrs)
    end

    test "update_pathology/2 with valid data updates the pathology" do
      pathology = pathology_fixture()
      update_attrs = %{common_name: "some updated common_name", scientific_name: "some updated scientific_name"}

      assert {:ok, %Pathology{} = pathology} = Pathologies.update_pathology(pathology, update_attrs)
      assert pathology.common_name == "some updated common_name"
      assert pathology.scientific_name == "some updated scientific_name"
    end

    test "update_pathology/2 with invalid data returns error changeset" do
      pathology = pathology_fixture()
      assert {:error, %Ecto.Changeset{}} = Pathologies.update_pathology(pathology, @invalid_attrs)
      assert pathology == Pathologies.get_pathology!(pathology.id)
    end

    test "delete_pathology/1 deletes the pathology" do
      pathology = pathology_fixture()
      assert {:ok, %Pathology{}} = Pathologies.delete_pathology(pathology)
      assert_raise Ecto.NoResultsError, fn -> Pathologies.get_pathology!(pathology.id) end
    end

    test "change_pathology/1 returns a pathology changeset" do
      pathology = pathology_fixture()
      assert %Ecto.Changeset{} = Pathologies.change_pathology(pathology)
    end
  end
end
