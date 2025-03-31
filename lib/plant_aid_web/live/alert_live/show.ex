defmodule PlantAidWeb.AlertLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user

    alert =
      Alerts.get_alert!(id)

    with :ok <- Bodyguard.permit(Alerts, :get_alert, user, alert) do
      Alerts.view_alert(user, alert)
      unviewed_alert_count = Alerts.get_unviewed_alert_count(user)

      {:noreply,
       socket
       |> assign(:current_user, %{
         socket.assigns.current_user
         | unviewed_alert_count: unviewed_alert_count
       })
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:alert, alert)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts")}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    user = socket.assigns.current_user

    with :ok <-
           Bodyguard.permit(
             Alerts,
             :delete_alert,
             user,
             socket.assigns.alert
           ) do
      {:ok, _} = Alerts.delete_alert(socket.assigns.alert)

      {:noreply, push_navigate(socket, to: ~p"/alerts")}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  defp page_title(:show), do: "Show Alert"
  defp page_title(:edit), do: "Edit Alert"
end
