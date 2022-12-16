defmodule PlantAidWeb.PathologyLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.PathologiesFixtures

  @create_attrs %{common_name: "some common_name", scientific_name: "some scientific_name"}
  @update_attrs %{common_name: "some updated common_name", scientific_name: "some updated scientific_name"}
  @invalid_attrs %{common_name: nil, scientific_name: nil}

  defp create_pathology(_) do
    pathology = pathology_fixture()
    %{pathology: pathology}
  end

  describe "Index" do
    setup [:create_pathology]

    test "lists all pathologies", %{conn: conn, pathology: pathology} do
      {:ok, _index_live, html} = live(conn, ~p"/pathologies")

      assert html =~ "Listing Pathologies"
      assert html =~ pathology.common_name
    end

    test "saves new pathology", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/pathologies")

      assert index_live |> element("a", "New Pathology") |> render_click() =~
               "New Pathology"

      assert_patch(index_live, ~p"/pathologies/new")

      assert index_live
             |> form("#pathology-form", pathology: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pathology-form", pathology: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/pathologies")

      assert html =~ "Pathology created successfully"
      assert html =~ "some common_name"
    end

    test "updates pathology in listing", %{conn: conn, pathology: pathology} do
      {:ok, index_live, _html} = live(conn, ~p"/pathologies")

      assert index_live |> element("#pathologies-#{pathology.id} a", "Edit") |> render_click() =~
               "Edit Pathology"

      assert_patch(index_live, ~p"/pathologies/#{pathology}/edit")

      assert index_live
             |> form("#pathology-form", pathology: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pathology-form", pathology: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/pathologies")

      assert html =~ "Pathology updated successfully"
      assert html =~ "some updated common_name"
    end

    test "deletes pathology in listing", %{conn: conn, pathology: pathology} do
      {:ok, index_live, _html} = live(conn, ~p"/pathologies")

      assert index_live |> element("#pathologies-#{pathology.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#pathology-#{pathology.id}")
    end
  end

  describe "Show" do
    setup [:create_pathology]

    test "displays pathology", %{conn: conn, pathology: pathology} do
      {:ok, _show_live, html} = live(conn, ~p"/pathologies/#{pathology}")

      assert html =~ "Show Pathology"
      assert html =~ pathology.common_name
    end

    test "updates pathology within modal", %{conn: conn, pathology: pathology} do
      {:ok, show_live, _html} = live(conn, ~p"/pathologies/#{pathology}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Pathology"

      assert_patch(show_live, ~p"/pathologies/#{pathology}/show/edit")

      assert show_live
             |> form("#pathology-form", pathology: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#pathology-form", pathology: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/pathologies/#{pathology}")

      assert html =~ "Pathology updated successfully"
      assert html =~ "some updated common_name"
    end
  end
end
