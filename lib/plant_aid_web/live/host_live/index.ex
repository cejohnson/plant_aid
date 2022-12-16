defmodule PlantAidWeb.HostLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Hosts
  alias PlantAid.Hosts.Host

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :hosts, list_hosts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Host")
    |> assign(:host, Hosts.get_host!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Host")
    |> assign(:host, %Host{varieties: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Hosts")
    |> assign(:host, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    host = Hosts.get_host!(id)
    {:ok, _} = Hosts.delete_host(host)

    {:noreply, assign(socket, :hosts, list_hosts())}
  end

  defp list_hosts do
    Hosts.list_hosts()
  end
end
