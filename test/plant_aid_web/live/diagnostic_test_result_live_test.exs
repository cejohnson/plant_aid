defmodule PlantAidWeb.DiagnosticTestResultLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.DiagnosticsFixtures

  @create_attrs %{data: %{}, metadata: %{}, comments: "some comments"}
  @update_attrs %{data: %{}, metadata: %{}, comments: "some updated comments"}
  @invalid_attrs %{data: nil, metadata: nil, comments: nil}

  defp create_diagnostic_test_result(_) do
    diagnostic_test_result = diagnostic_test_result_fixture()
    %{diagnostic_test_result: diagnostic_test_result}
  end

  describe "Index" do
    setup [:create_diagnostic_test_result]

    test "lists all diagnostic_test_results", %{conn: conn, diagnostic_test_result: diagnostic_test_result} do
      {:ok, _index_live, html} = live(conn, ~p"/diagnostic_test_results")

      assert html =~ "Listing Diagnostic test results"
      assert html =~ diagnostic_test_result.comments
    end

    test "saves new diagnostic_test_result", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/diagnostic_test_results")

      assert index_live |> element("a", "New Diagnostic test result") |> render_click() =~
               "New Diagnostic test result"

      assert_patch(index_live, ~p"/diagnostic_test_results/new")

      assert index_live
             |> form("#diagnostic_test_result-form", diagnostic_test_result: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#diagnostic_test_result-form", diagnostic_test_result: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/diagnostic_test_results")

      html = render(index_live)
      assert html =~ "Diagnostic test result created successfully"
      assert html =~ "some comments"
    end

    test "updates diagnostic_test_result in listing", %{conn: conn, diagnostic_test_result: diagnostic_test_result} do
      {:ok, index_live, _html} = live(conn, ~p"/diagnostic_test_results")

      assert index_live |> element("#diagnostic_test_results-#{diagnostic_test_result.id} a", "Edit") |> render_click() =~
               "Edit Diagnostic test result"

      assert_patch(index_live, ~p"/diagnostic_test_results/#{diagnostic_test_result}/edit")

      assert index_live
             |> form("#diagnostic_test_result-form", diagnostic_test_result: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#diagnostic_test_result-form", diagnostic_test_result: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/diagnostic_test_results")

      html = render(index_live)
      assert html =~ "Diagnostic test result updated successfully"
      assert html =~ "some updated comments"
    end

    test "deletes diagnostic_test_result in listing", %{conn: conn, diagnostic_test_result: diagnostic_test_result} do
      {:ok, index_live, _html} = live(conn, ~p"/diagnostic_test_results")

      assert index_live |> element("#diagnostic_test_results-#{diagnostic_test_result.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#diagnostic_test_results-#{diagnostic_test_result.id}")
    end
  end

  describe "Show" do
    setup [:create_diagnostic_test_result]

    test "displays diagnostic_test_result", %{conn: conn, diagnostic_test_result: diagnostic_test_result} do
      {:ok, _show_live, html} = live(conn, ~p"/diagnostic_test_results/#{diagnostic_test_result}")

      assert html =~ "Show Diagnostic test result"
      assert html =~ diagnostic_test_result.comments
    end

    test "updates diagnostic_test_result within modal", %{conn: conn, diagnostic_test_result: diagnostic_test_result} do
      {:ok, show_live, _html} = live(conn, ~p"/diagnostic_test_results/#{diagnostic_test_result}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Diagnostic test result"

      assert_patch(show_live, ~p"/diagnostic_test_results/#{diagnostic_test_result}/show/edit")

      assert show_live
             |> form("#diagnostic_test_result-form", diagnostic_test_result: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#diagnostic_test_result-form", diagnostic_test_result: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/diagnostic_test_results/#{diagnostic_test_result}")

      html = render(show_live)
      assert html =~ "Diagnostic test result updated successfully"
      assert html =~ "some updated comments"
    end
  end
end
