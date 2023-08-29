defmodule PlantAidWeb.HostLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Hosts
  alias PlantAid.Hosts.Host

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Hosts, :list_hosts, current_user) do
      {:ok, stream(socket, :hosts, Hosts.list_hosts())}
    end
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
    |> assign(:host, %Host{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Hosts")
    |> assign(:host, nil)
  end

  @impl true
  def handle_info({PlantAidWeb.HostLive.FormComponent, {:saved, host}}, socket) do
    {:noreply, stream_insert(socket, :hosts, host)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    host = Hosts.get_host!(id)

    with :ok <- Bodyguard.permit(Hosts, :delete_host, current_user) do
      {:ok, _} = Hosts.delete_host(host)

      {:noreply, stream_delete(socket, :hosts, host)}
    end
  end
end
