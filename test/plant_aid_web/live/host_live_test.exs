defmodule PlantAidWeb.HostLiveTest do
  use PlantAidWeb.ConnCase

  import Phoenix.LiveViewTest
  import PlantAid.HostsFixtures

  @create_attrs %{common_name: "some common_name", scientific_name: "some scientific_name"}
  @update_attrs %{common_name: "some updated common_name", scientific_name: "some updated scientific_name"}
  @invalid_attrs %{common_name: nil, scientific_name: nil}

  defp create_host(_) do
    host = host_fixture()
    %{host: host}
  end

  describe "Index" do
    setup [:create_host]

    test "lists all hosts", %{conn: conn, host: host} do
      {:ok, _index_live, html} = live(conn, ~p"/hosts")

      assert html =~ "Listing Hosts"
      assert html =~ host.common_name
    end

    test "saves new host", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/hosts")

      assert index_live |> element("a", "New Host") |> render_click() =~
               "New Host"

      assert_patch(index_live, ~p"/hosts/new")

      assert index_live
             |> form("#host-form", host: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#host-form", host: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/hosts")

      assert html =~ "Host created successfully"
      assert html =~ "some common_name"
    end

    test "updates host in listing", %{conn: conn, host: host} do
      {:ok, index_live, _html} = live(conn, ~p"/hosts")

      assert index_live |> element("#hosts-#{host.id} a", "Edit") |> render_click() =~
               "Edit Host"

      assert_patch(index_live, ~p"/hosts/#{host}/edit")

      assert index_live
             |> form("#host-form", host: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#host-form", host: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/hosts")

      assert html =~ "Host updated successfully"
      assert html =~ "some updated common_name"
    end

    test "deletes host in listing", %{conn: conn, host: host} do
      {:ok, index_live, _html} = live(conn, ~p"/hosts")

      assert index_live |> element("#hosts-#{host.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#host-#{host.id}")
    end
  end

  describe "Show" do
    setup [:create_host]

    test "displays host", %{conn: conn, host: host} do
      {:ok, _show_live, html} = live(conn, ~p"/hosts/#{host}")

      assert html =~ "Show Host"
      assert html =~ host.common_name
    end

    test "updates host within modal", %{conn: conn, host: host} do
      {:ok, show_live, _html} = live(conn, ~p"/hosts/#{host}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Host"

      assert_patch(show_live, ~p"/hosts/#{host}/show/edit")

      assert show_live
             |> form("#host-form", host: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#host-form", host: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/hosts/#{host}")

      assert html =~ "Host updated successfully"
      assert html =~ "some updated common_name"
    end
  end
end
