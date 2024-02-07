defmodule PlantAidWeb.SampleLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.ObservationsFixtures

  @create_attrs %{data: %{}}
  @update_attrs %{data: %{}}
  @invalid_attrs %{data: nil}

  defp create_sample(_) do
    sample = sample_fixture()
    %{sample: sample}
  end

  describe "Index" do
    setup [:create_sample]

    test "lists all samples", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/samples")

      assert html =~ "Listing Samples"
    end

    test "saves new sample", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/samples")

      assert index_live |> element("a", "New Sample") |> render_click() =~
               "New Sample"

      assert_patch(index_live, ~p"/samples/new")

      assert index_live
             |> form("#sample-form", sample: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#sample-form", sample: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/samples")

      html = render(index_live)
      assert html =~ "Sample created successfully"
    end

    test "updates sample in listing", %{conn: conn, sample: sample} do
      {:ok, index_live, _html} = live(conn, ~p"/samples")

      assert index_live |> element("#samples-#{sample.id} a", "Edit") |> render_click() =~
               "Edit Sample"

      assert_patch(index_live, ~p"/samples/#{sample}/edit")

      assert index_live
             |> form("#sample-form", sample: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#sample-form", sample: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/samples")

      html = render(index_live)
      assert html =~ "Sample updated successfully"
    end

    test "deletes sample in listing", %{conn: conn, sample: sample} do
      {:ok, index_live, _html} = live(conn, ~p"/samples")

      assert index_live |> element("#samples-#{sample.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#samples-#{sample.id}")
    end
  end

  describe "Show" do
    setup [:create_sample]

    test "displays sample", %{conn: conn, sample: sample} do
      {:ok, _show_live, html} = live(conn, ~p"/samples/#{sample}")

      assert html =~ "Show Sample"
    end

    test "updates sample within modal", %{conn: conn, sample: sample} do
      {:ok, show_live, _html} = live(conn, ~p"/samples/#{sample}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Sample"

      assert_patch(show_live, ~p"/samples/#{sample}/show/edit")

      assert show_live
             |> form("#sample-form", sample: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#sample-form", sample: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/samples/#{sample}")

      html = render(show_live)
      assert html =~ "Sample updated successfully"
    end
  end
end
