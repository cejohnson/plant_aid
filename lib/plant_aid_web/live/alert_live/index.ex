defmodule PlantAidWeb.AlertLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :list_alerts, user) do
      {:ok, stream(socket, :alerts, Alerts.list_alerts(user))}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Alerts")
    |> assign(:alert, nil)
  end

  @impl true
  def handle_info({PlantAidWeb.AlertLive.FormComponent, {:saved, alert}}, socket) do
    {:noreply, stream_insert(socket, :alerts, alert)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    alert = Alerts.get_alert!(id)

    with :ok <- Bodyguard.permit(Alerts, :delete_alert, user) do
      {:ok, _} = Alerts.delete_alert(alert)
      {:noreply, stream_delete(socket, :alerts, alert)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end
end
