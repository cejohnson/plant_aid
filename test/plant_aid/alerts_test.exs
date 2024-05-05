defmodule PlantAid.AlertsTest do
  use PlantAid.DataCase

  alias PlantAid.Alerts

  describe "location_alert_criteria" do
    alias PlantAid.Alerts.LocationAlertCriterion

    import PlantAid.AlertsFixtures

    @invalid_attrs %{active: nil, distance: nil}

    test "list_location_alert_criteria/0 returns all location_alert_criteria" do
      location_alert_criterion = location_alert_criterion_fixture()
      assert Alerts.list_location_alert_criteria() == [location_alert_criterion]
    end

    test "get_location_alert_criterion!/1 returns the location_alert_criterion with given id" do
      location_alert_criterion = location_alert_criterion_fixture()
      assert Alerts.get_location_alert_criterion!(location_alert_criterion.id) == location_alert_criterion
    end

    test "create_location_alert_criterion/1 with valid data creates a location_alert_criterion" do
      valid_attrs = %{active: true, distance: 120.5}

      assert {:ok, %LocationAlertCriterion{} = location_alert_criterion} = Alerts.create_location_alert_criterion(valid_attrs)
      assert location_alert_criterion.active == true
      assert location_alert_criterion.distance == 120.5
    end

    test "create_location_alert_criterion/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Alerts.create_location_alert_criterion(@invalid_attrs)
    end

    test "update_location_alert_criterion/2 with valid data updates the location_alert_criterion" do
      location_alert_criterion = location_alert_criterion_fixture()
      update_attrs = %{active: false, distance: 456.7}

      assert {:ok, %LocationAlertCriterion{} = location_alert_criterion} = Alerts.update_location_alert_criterion(location_alert_criterion, update_attrs)
      assert location_alert_criterion.active == false
      assert location_alert_criterion.distance == 456.7
    end

    test "update_location_alert_criterion/2 with invalid data returns error changeset" do
      location_alert_criterion = location_alert_criterion_fixture()
      assert {:error, %Ecto.Changeset{}} = Alerts.update_location_alert_criterion(location_alert_criterion, @invalid_attrs)
      assert location_alert_criterion == Alerts.get_location_alert_criterion!(location_alert_criterion.id)
    end

    test "delete_location_alert_criterion/1 deletes the location_alert_criterion" do
      location_alert_criterion = location_alert_criterion_fixture()
      assert {:ok, %LocationAlertCriterion{}} = Alerts.delete_location_alert_criterion(location_alert_criterion)
      assert_raise Ecto.NoResultsError, fn -> Alerts.get_location_alert_criterion!(location_alert_criterion.id) end
    end

    test "change_location_alert_criterion/1 returns a location_alert_criterion changeset" do
      location_alert_criterion = location_alert_criterion_fixture()
      assert %Ecto.Changeset{} = Alerts.change_location_alert_criterion(location_alert_criterion)
    end
  end

  describe "alerts" do
    alias PlantAid.Alerts.Alert

    import PlantAid.AlertsFixtures

    @invalid_attrs %{viewed_at: nil}

    test "list_alerts/0 returns all alerts" do
      alert = alert_fixture()
      assert Alerts.list_alerts() == [alert]
    end

    test "get_alert!/1 returns the alert with given id" do
      alert = alert_fixture()
      assert Alerts.get_alert!(alert.id) == alert
    end

    test "create_alert/1 with valid data creates a alert" do
      valid_attrs = %{viewed_at: ~N[2024-04-20 04:33:00]}

      assert {:ok, %Alert{} = alert} = Alerts.create_alert(valid_attrs)
      assert alert.viewed_at == ~N[2024-04-20 04:33:00]
    end

    test "create_alert/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Alerts.create_alert(@invalid_attrs)
    end

    test "update_alert/2 with valid data updates the alert" do
      alert = alert_fixture()
      update_attrs = %{viewed_at: ~N[2024-04-21 04:33:00]}

      assert {:ok, %Alert{} = alert} = Alerts.update_alert(alert, update_attrs)
      assert alert.viewed_at == ~N[2024-04-21 04:33:00]
    end

    test "update_alert/2 with invalid data returns error changeset" do
      alert = alert_fixture()
      assert {:error, %Ecto.Changeset{}} = Alerts.update_alert(alert, @invalid_attrs)
      assert alert == Alerts.get_alert!(alert.id)
    end

    test "delete_alert/1 deletes the alert" do
      alert = alert_fixture()
      assert {:ok, %Alert{}} = Alerts.delete_alert(alert)
      assert_raise Ecto.NoResultsError, fn -> Alerts.get_alert!(alert.id) end
    end

    test "change_alert/1 returns a alert changeset" do
      alert = alert_fixture()
      assert %Ecto.Changeset{} = Alerts.change_alert(alert)
    end
  end
end
