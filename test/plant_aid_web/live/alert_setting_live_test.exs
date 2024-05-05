defmodule PlantAidWeb.LocationAlertCriterionLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.AlertsFixtures

  @create_attrs %{active: true, distance: 120.5}
  @update_attrs %{active: false, distance: 456.7}
  @invalid_attrs %{active: false, distance: nil}

  defp create_alert_setting(_) do
    alert_setting = alert_setting_fixture()
    %{alert_setting: alert_setting}
  end

  describe "Index" do
    setup [:create_alert_setting]

    test "lists all alert_settings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/alerts/settings")

      assert html =~ "Listing Location alert criteria"
    end

    test "saves new alert_setting", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts/settings")

      assert index_live |> element("a", "New Alert setting") |> render_click() =~
               "New Alert setting"

      assert_patch(index_live, ~p"/alerts/settings/new")

      assert index_live
             |> form("#alert_setting-form", alert_setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#alert_setting-form", alert_setting: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/alerts/settings")

      html = render(index_live)
      assert html =~ "Alert setting created successfully"
    end

    test "updates alert_setting in listing", %{conn: conn, alert_setting: alert_setting} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts/settings")

      assert index_live
             |> element("#alert_settings-#{alert_setting.id} a", "Edit")
             |> render_click() =~
               "Edit Alert setting"

      assert_patch(index_live, ~p"/alerts/settings/#{alert_setting}/edit")

      assert index_live
             |> form("#alert_setting-form", alert_setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#alert_setting-form", alert_setting: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/alerts/settings")

      html = render(index_live)
      assert html =~ "Alert setting updated successfully"
    end

    test "deletes alert_setting in listing", %{conn: conn, alert_setting: alert_setting} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts/settings")

      assert index_live
             |> element("#alert_settings-#{alert_setting.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#alert_settings-#{alert_setting.id}")
    end
  end

  describe "Show" do
    setup [:create_alert_setting]

    test "displays alert_setting", %{conn: conn, alert_setting: alert_setting} do
      {:ok, _show_live, html} = live(conn, ~p"/alerts/settings/#{alert_setting}")

      assert html =~ "Show Alert setting"
    end

    test "updates alert_setting within modal", %{conn: conn, alert_setting: alert_setting} do
      {:ok, show_live, _html} = live(conn, ~p"/alerts/settings/#{alert_setting}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Alert setting"

      assert_patch(show_live, ~p"/alerts/settings/#{alert_setting}/show/edit")

      assert show_live
             |> form("#alert_setting-form", alert_setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#alert_setting-form", alert_setting: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/alerts/settings/#{alert_setting}")

      html = render(show_live)
      assert html =~ "Alert setting updated successfully"
    end
  end
end
