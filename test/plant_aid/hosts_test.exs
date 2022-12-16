defmodule PlantAid.HostsTest do
  use PlantAid.DataCase

  alias PlantAid.Hosts

  describe "hosts" do
    alias PlantAid.Hosts.Host

    import PlantAid.HostsFixtures

    @invalid_attrs %{common_name: nil, scientific_name: nil}

    test "list_hosts/0 returns all hosts" do
      host = host_fixture()
      assert Hosts.list_hosts() == [host]
    end

    test "get_host!/1 returns the host with given id" do
      host = host_fixture()
      assert Hosts.get_host!(host.id) == host
    end

    test "create_host/1 with valid data creates a host" do
      valid_attrs = %{common_name: "some common_name", scientific_name: "some scientific_name"}

      assert {:ok, %Host{} = host} = Hosts.create_host(valid_attrs)
      assert host.common_name == "some common_name"
      assert host.scientific_name == "some scientific_name"
    end

    test "create_host/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Hosts.create_host(@invalid_attrs)
    end

    test "update_host/2 with valid data updates the host" do
      host = host_fixture()

      update_attrs = %{
        common_name: "some updated common_name",
        scientific_name: "some updated scientific_name"
      }

      assert {:ok, %Host{} = host} = Hosts.update_host(host, update_attrs)
      assert host.common_name == "some updated common_name"
      assert host.scientific_name == "some updated scientific_name"
    end

    test "update_host/2 with invalid data returns error changeset" do
      host = host_fixture()
      assert {:error, %Ecto.Changeset{}} = Hosts.update_host(host, @invalid_attrs)
      assert host == Hosts.get_host!(host.id)
    end

    test "delete_host/1 deletes the host" do
      host = host_fixture()
      assert {:ok, %Host{}} = Hosts.delete_host(host)
      assert_raise Ecto.NoResultsError, fn -> Hosts.get_host!(host.id) end
    end

    test "change_host/1 returns a host changeset" do
      host = host_fixture()
      assert %Ecto.Changeset{} = Hosts.change_host(host)
    end
  end

  # describe "host_varieties" do
  #   alias PlantAid.Hosts.HostVariety

  #   import PlantAid.HostsFixtures

  #   @invalid_attrs %{name: nil}

  #   test "list_host_varieties/0 returns all host_varieties" do
  #     host_variety = host_variety_fixture()
  #     assert Hosts.list_host_varieties() == [host_variety]
  #   end

  #   test "get_host_variety!/1 returns the host_variety with given id" do
  #     host_variety = host_variety_fixture()
  #     assert Hosts.get_host_variety!(host_variety.id) == host_variety
  #   end

  #   test "create_host_variety/1 with valid data creates a host_variety" do
  #     valid_attrs = %{name: "some name"}

  #     assert {:ok, %HostVariety{} = host_variety} = Hosts.create_host_variety(valid_attrs)
  #     assert host_variety.name == "some name"
  #   end

  #   test "create_host_variety/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Hosts.create_host_variety(@invalid_attrs)
  #   end

  #   test "update_host_variety/2 with valid data updates the host_variety" do
  #     host_variety = host_variety_fixture()
  #     update_attrs = %{name: "some updated name"}

  #     assert {:ok, %HostVariety{} = host_variety} = Hosts.update_host_variety(host_variety, update_attrs)
  #     assert host_variety.name == "some updated name"
  #   end

  #   test "update_host_variety/2 with invalid data returns error changeset" do
  #     host_variety = host_variety_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Hosts.update_host_variety(host_variety, @invalid_attrs)
  #     assert host_variety == Hosts.get_host_variety!(host_variety.id)
  #   end

  #   test "delete_host_variety/1 deletes the host_variety" do
  #     host_variety = host_variety_fixture()
  #     assert {:ok, %HostVariety{}} = Hosts.delete_host_variety(host_variety)
  #     assert_raise Ecto.NoResultsError, fn -> Hosts.get_host_variety!(host_variety.id) end
  #   end

  #   test "change_host_variety/1 returns a host_variety changeset" do
  #     host_variety = host_variety_fixture()
  #     assert %Ecto.Changeset{} = Hosts.change_host_variety(host_variety)
  #   end
  # end
end
