defmodule PlantAidWeb.AlertSubscriptionLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    alert_subscription = Alerts.get_alert_subscription!(id)

    with :ok <- Bodyguard.permit(Alerts, :get_alert_subscription, user, alert_subscription) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:alert_subscription, alert_subscription)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts/subscriptions")}
    end
  end

  defp page_title(:show), do: "Show Alert subscription"
  defp page_title(:edit), do: "Edit Alert subscription"
end
