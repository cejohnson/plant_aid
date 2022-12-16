defmodule PlantAidWeb.LocationTypeLiveTest do
  use PlantAidWeb.ConnCase

  import PlantAid.AccountsFixtures
  import Phoenix.LiveViewTest
  import PlantAid.LocationTypesFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_location_type(_) do
    location_type = location_type_fixture()
    %{location_type: location_type}
  end

  describe "Index" do
    setup [:create_location_type]

    test "lists all location_types", %{conn: conn, location_type: location_type} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/location_types")

      assert html =~ "Listing Location types"
      assert html =~ location_type.name
    end

    test "saves new location_type", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/location_types")

      assert index_live |> element("a", "New Location type") |> render_click() =~
               "New Location type"

      assert_patch(index_live, ~p"/location_types/new")

      assert index_live
             |> form("#location_type-form", location_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#location_type-form", location_type: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/location_types")

      assert html =~ "Location type created successfully"
      assert html =~ "some name"
    end

    test "updates location_type in listing", %{conn: conn, location_type: location_type} do
      {:ok, index_live, _html} = live(conn, ~p"/location_types")

      assert index_live
             |> element("#location_types-#{location_type.id} a", "Edit")
             |> render_click() =~
               "Edit Location type"

      assert_patch(index_live, ~p"/location_types/#{location_type}/edit")

      assert index_live
             |> form("#location_type-form", location_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#location_type-form", location_type: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/location_types")

      assert html =~ "Location type updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes location_type in listing", %{conn: conn, location_type: location_type} do
      {:ok, index_live, _html} = live(conn, ~p"/location_types")

      assert index_live
             |> element("#location_types-#{location_type.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#location_type-#{location_type.id}")
    end
  end

  describe "Show" do
    setup [:create_location_type]

    test "displays location_type", %{conn: conn, location_type: location_type} do
      {:ok, _show_live, html} = live(conn, ~p"/location_types/#{location_type}")

      assert html =~ "Show Location type"
      assert html =~ location_type.name
    end

    test "updates location_type within modal", %{conn: conn, location_type: location_type} do
      {:ok, show_live, _html} = live(conn, ~p"/location_types/#{location_type}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Location type"

      assert_patch(show_live, ~p"/location_types/#{location_type}/show/edit")

      assert show_live
             |> form("#location_type-form", location_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#location_type-form", location_type: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/location_types/#{location_type}")

      assert html =~ "Location type updated successfully"
      assert html =~ "some updated name"
    end
  end
end
