defmodule PlantAidWeb.DiagnosticMethodLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.DiagnosticsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_diagnostic_method(_) do
    diagnostic_method = diagnostic_method_fixture()
    %{diagnostic_method: diagnostic_method}
  end

  describe "Index" do
    setup [:create_diagnostic_method]

    test "lists all diagnostic_methods", %{conn: conn, diagnostic_method: diagnostic_method} do
      {:ok, _index_live, html} = live(conn, ~p"/diagnostic_methods")

      assert html =~ "Listing Diagnostic methods"
      assert html =~ diagnostic_method.name
    end

    test "saves new diagnostic_method", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/diagnostic_methods")

      assert index_live |> element("a", "New Diagnostic method") |> render_click() =~
               "New Diagnostic method"

      assert_patch(index_live, ~p"/diagnostic_methods/new")

      assert index_live
             |> form("#diagnostic_method-form", diagnostic_method: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#diagnostic_method-form", diagnostic_method: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/diagnostic_methods")

      html = render(index_live)
      assert html =~ "Diagnostic method created successfully"
      assert html =~ "some name"
    end

    test "updates diagnostic_method in listing", %{conn: conn, diagnostic_method: diagnostic_method} do
      {:ok, index_live, _html} = live(conn, ~p"/diagnostic_methods")

      assert index_live |> element("#diagnostic_methods-#{diagnostic_method.id} a", "Edit") |> render_click() =~
               "Edit Diagnostic method"

      assert_patch(index_live, ~p"/diagnostic_methods/#{diagnostic_method}/edit")

      assert index_live
             |> form("#diagnostic_method-form", diagnostic_method: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#diagnostic_method-form", diagnostic_method: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/diagnostic_methods")

      html = render(index_live)
      assert html =~ "Diagnostic method updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes diagnostic_method in listing", %{conn: conn, diagnostic_method: diagnostic_method} do
      {:ok, index_live, _html} = live(conn, ~p"/diagnostic_methods")

      assert index_live |> element("#diagnostic_methods-#{diagnostic_method.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#diagnostic_methods-#{diagnostic_method.id}")
    end
  end

  describe "Show" do
    setup [:create_diagnostic_method]

    test "displays diagnostic_method", %{conn: conn, diagnostic_method: diagnostic_method} do
      {:ok, _show_live, html} = live(conn, ~p"/diagnostic_methods/#{diagnostic_method}")

      assert html =~ "Show Diagnostic method"
      assert html =~ diagnostic_method.name
    end

    test "updates diagnostic_method within modal", %{conn: conn, diagnostic_method: diagnostic_method} do
      {:ok, show_live, _html} = live(conn, ~p"/diagnostic_methods/#{diagnostic_method}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Diagnostic method"

      assert_patch(show_live, ~p"/diagnostic_methods/#{diagnostic_method}/show/edit")

      assert show_live
             |> form("#diagnostic_method-form", diagnostic_method: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#diagnostic_method-form", diagnostic_method: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/diagnostic_methods/#{diagnostic_method}")

      html = render(show_live)
      assert html =~ "Diagnostic method updated successfully"
      assert html =~ "some updated name"
    end
  end
end
