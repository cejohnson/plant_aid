defmodule PlantAid.GeographyTest do
  use PlantAid.DataCase

  alias PlantAid.Geography

  # describe "counties" do
  #   alias PlantAid.Geography.County

  #   import PlantAid.GeographyFixtures

  #   @invalid_attrs %{geometry: nil, name: nil, state: nil}

  #   test "list_counties/0 returns all counties" do
  #     county = county_fixture()
  #     assert Geography.list_counties() == [county]
  #   end

  #   test "get_county!/1 returns the county with given id" do
  #     county = county_fixture()
  #     assert Geography.get_county!(county.id) == county
  #   end

  #   test "create_county/1 with valid data creates a county" do
  #     valid_attrs = %{geometry: "some geometry", name: "some name", state: "some state"}

  #     assert {:ok, %County{} = county} = Geography.create_county(valid_attrs)
  #     assert county.geometry == "some geometry"
  #     assert county.name == "some name"
  #     assert county.state == "some state"
  #   end

  #   test "create_county/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Geography.create_county(@invalid_attrs)
  #   end

  #   test "update_county/2 with valid data updates the county" do
  #     county = county_fixture()
  #     update_attrs = %{geometry: "some updated geometry", name: "some updated name", state: "some updated state"}

  #     assert {:ok, %County{} = county} = Geography.update_county(county, update_attrs)
  #     assert county.geometry == "some updated geometry"
  #     assert county.name == "some updated name"
  #     assert county.state == "some updated state"
  #   end

  #   test "update_county/2 with invalid data returns error changeset" do
  #     county = county_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Geography.update_county(county, @invalid_attrs)
  #     assert county == Geography.get_county!(county.id)
  #   end

  #   test "delete_county/1 deletes the county" do
  #     county = county_fixture()
  #     assert {:ok, %County{}} = Geography.delete_county(county)
  #     assert_raise Ecto.NoResultsError, fn -> Geography.get_county!(county.id) end
  #   end

  #   test "change_county/1 returns a county changeset" do
  #     county = county_fixture()
  #     assert %Ecto.Changeset{} = Geography.change_county(county)
  #   end
  # end
end
