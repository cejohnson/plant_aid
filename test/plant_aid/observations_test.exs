defmodule PlantAid.ObservationsTest do
  use PlantAid.DataCase

  alias PlantAid.Observations

  describe "observations" do
    alias PlantAid.Observations.Observation

    import PlantAid.ObservationsFixtures

    @invalid_attrs %{control_method: nil, host_other: nil, metadata: nil, notes: nil, observation_date: nil, organic: nil, position: nil}

    test "list_observations/0 returns all observations" do
      observation = observation_fixture()
      assert Observations.list_observations() == [observation]
    end

    test "get_observation!/1 returns the observation with given id" do
      observation = observation_fixture()
      assert Observations.get_observation!(observation.id) == observation
    end

    test "create_observation/1 with valid data creates a observation" do
      valid_attrs = %{control_method: "some control_method", host_other: "some host_other", metadata: %{}, notes: "some notes", observation_date: ~U[2022-12-05 23:29:00Z], organic: true, position: "some position"}

      assert {:ok, %Observation{} = observation} = Observations.create_observation(valid_attrs)
      assert observation.control_method == "some control_method"
      assert observation.host_other == "some host_other"
      assert observation.metadata == %{}
      assert observation.notes == "some notes"
      assert observation.observation_date == ~U[2022-12-05 23:29:00Z]
      assert observation.organic == true
      assert observation.position == "some position"
    end

    test "create_observation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Observations.create_observation(@invalid_attrs)
    end

    test "update_observation/2 with valid data updates the observation" do
      observation = observation_fixture()
      update_attrs = %{control_method: "some updated control_method", host_other: "some updated host_other", metadata: %{}, notes: "some updated notes", observation_date: ~U[2022-12-06 23:29:00Z], organic: false, position: "some updated position"}

      assert {:ok, %Observation{} = observation} = Observations.update_observation(observation, update_attrs)
      assert observation.control_method == "some updated control_method"
      assert observation.host_other == "some updated host_other"
      assert observation.metadata == %{}
      assert observation.notes == "some updated notes"
      assert observation.observation_date == ~U[2022-12-06 23:29:00Z]
      assert observation.organic == false
      assert observation.position == "some updated position"
    end

    test "update_observation/2 with invalid data returns error changeset" do
      observation = observation_fixture()
      assert {:error, %Ecto.Changeset{}} = Observations.update_observation(observation, @invalid_attrs)
      assert observation == Observations.get_observation!(observation.id)
    end

    test "delete_observation/1 deletes the observation" do
      observation = observation_fixture()
      assert {:ok, %Observation{}} = Observations.delete_observation(observation)
      assert_raise Ecto.NoResultsError, fn -> Observations.get_observation!(observation.id) end
    end

    test "change_observation/1 returns a observation changeset" do
      observation = observation_fixture()
      assert %Ecto.Changeset{} = Observations.change_observation(observation)
    end
  end

  describe "samples" do
    alias PlantAid.Observations.Sample

    import PlantAid.ObservationsFixtures

    @invalid_attrs %{data: nil}

    test "list_samples/0 returns all samples" do
      sample = sample_fixture()
      assert Observations.list_samples() == [sample]
    end

    test "get_sample!/1 returns the sample with given id" do
      sample = sample_fixture()
      assert Observations.get_sample!(sample.id) == sample
    end

    test "create_sample/1 with valid data creates a sample" do
      valid_attrs = %{data: %{}}

      assert {:ok, %Sample{} = sample} = Observations.create_sample(valid_attrs)
      assert sample.data == %{}
    end

    test "create_sample/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Observations.create_sample(@invalid_attrs)
    end

    test "update_sample/2 with valid data updates the sample" do
      sample = sample_fixture()
      update_attrs = %{data: %{}}

      assert {:ok, %Sample{} = sample} = Observations.update_sample(sample, update_attrs)
      assert sample.data == %{}
    end

    test "update_sample/2 with invalid data returns error changeset" do
      sample = sample_fixture()
      assert {:error, %Ecto.Changeset{}} = Observations.update_sample(sample, @invalid_attrs)
      assert sample == Observations.get_sample!(sample.id)
    end

    test "delete_sample/1 deletes the sample" do
      sample = sample_fixture()
      assert {:ok, %Sample{}} = Observations.delete_sample(sample)
      assert_raise Ecto.NoResultsError, fn -> Observations.get_sample!(sample.id) end
    end

    test "change_sample/1 returns a sample changeset" do
      sample = sample_fixture()
      assert %Ecto.Changeset{} = Observations.change_sample(sample)
    end
  end
end
