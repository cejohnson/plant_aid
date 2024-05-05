defmodule PlantAidWeb.AlertLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.AlertsFixtures

  @create_attrs %{viewed_at: "2024-04-20T04:33:00"}
  @update_attrs %{viewed_at: "2024-04-21T04:33:00"}
  @invalid_attrs %{viewed_at: nil}

  defp create_alert(_) do
    alert = alert_fixture()
    %{alert: alert}
  end

  describe "Index" do
    setup [:create_alert]

    test "lists all alerts", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/alerts")

      assert html =~ "Listing Alerts"
    end

    test "saves new alert", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts")

      assert index_live |> element("a", "New Alert") |> render_click() =~
               "New Alert"

      assert_patch(index_live, ~p"/alerts/new")

      assert index_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#alert-form", alert: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/alerts")

      html = render(index_live)
      assert html =~ "Alert created successfully"
    end

    test "updates alert in listing", %{conn: conn, alert: alert} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts")

      assert index_live |> element("#alerts-#{alert.id} a", "Edit") |> render_click() =~
               "Edit Alert"

      assert_patch(index_live, ~p"/alerts/#{alert}/edit")

      assert index_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#alert-form", alert: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/alerts")

      html = render(index_live)
      assert html =~ "Alert updated successfully"
    end

    test "deletes alert in listing", %{conn: conn, alert: alert} do
      {:ok, index_live, _html} = live(conn, ~p"/alerts")

      assert index_live |> element("#alerts-#{alert.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#alerts-#{alert.id}")
    end
  end

  describe "Show" do
    setup [:create_alert]

    test "displays alert", %{conn: conn, alert: alert} do
      {:ok, _show_live, html} = live(conn, ~p"/alerts/#{alert}")

      assert html =~ "Show Alert"
    end

    test "updates alert within modal", %{conn: conn, alert: alert} do
      {:ok, show_live, _html} = live(conn, ~p"/alerts/#{alert}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Alert"

      assert_patch(show_live, ~p"/alerts/#{alert}/show/edit")

      assert show_live
             |> form("#alert-form", alert: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#alert-form", alert: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/alerts/#{alert}")

      html = render(show_live)
      assert html =~ "Alert updated successfully"
    end
  end
end
