defmodule PlantAidWeb.ObservationLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.ObservationsFixtures

  @create_attrs %{control_method: "some control_method", host_other: "some host_other", metadata: %{}, notes: "some notes", observation_date: "2022-12-05T23:29:00Z", organic: true, position: "some position"}
  @update_attrs %{control_method: "some updated control_method", host_other: "some updated host_other", metadata: %{}, notes: "some updated notes", observation_date: "2022-12-06T23:29:00Z", organic: false, position: "some updated position"}
  @invalid_attrs %{control_method: nil, host_other: nil, metadata: nil, notes: nil, observation_date: nil, organic: false, position: nil}

  defp create_observation(_) do
    observation = observation_fixture()
    %{observation: observation}
  end

  describe "Index" do
    setup [:create_observation]

    test "lists all observations", %{conn: conn, observation: observation} do
      {:ok, _index_live, html} = live(conn, ~p"/observations")

      assert html =~ "Listing Observations"
      assert html =~ observation.control_method
    end

    test "saves new observation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/observations")

      assert index_live |> element("a", "New Observation") |> render_click() =~
               "New Observation"

      assert_patch(index_live, ~p"/observations/new")

      assert index_live
             |> form("#observation-form", observation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#observation-form", observation: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/observations")

      assert html =~ "Observation created successfully"
      assert html =~ "some control_method"
    end

    test "updates observation in listing", %{conn: conn, observation: observation} do
      {:ok, index_live, _html} = live(conn, ~p"/observations")

      assert index_live |> element("#observations-#{observation.id} a", "Edit") |> render_click() =~
               "Edit Observation"

      assert_patch(index_live, ~p"/observations/#{observation}/edit")

      assert index_live
             |> form("#observation-form", observation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#observation-form", observation: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/observations")

      assert html =~ "Observation updated successfully"
      assert html =~ "some updated control_method"
    end

    test "deletes observation in listing", %{conn: conn, observation: observation} do
      {:ok, index_live, _html} = live(conn, ~p"/observations")

      assert index_live |> element("#observations-#{observation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#observation-#{observation.id}")
    end
  end

  describe "Show" do
    setup [:create_observation]

    test "displays observation", %{conn: conn, observation: observation} do
      {:ok, _show_live, html} = live(conn, ~p"/observations/#{observation}")

      assert html =~ "Show Observation"
      assert html =~ observation.control_method
    end

    test "updates observation within modal", %{conn: conn, observation: observation} do
      {:ok, show_live, _html} = live(conn, ~p"/observations/#{observation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Observation"

      assert_patch(show_live, ~p"/observations/#{observation}/show/edit")

      assert show_live
             |> form("#observation-form", observation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#observation-form", observation: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/observations/#{observation}")

      assert html =~ "Observation updated successfully"
      assert html =~ "some updated control_method"
    end
  end
end
