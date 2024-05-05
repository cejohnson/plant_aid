defmodule PlantAidWeb.AlertSettingLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    alert_setting = Alerts.get_alert_setting!(id)

    with :ok <- Bodyguard.permit(Alerts, :get_alert_setting, user, alert_setting) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:alert_setting, alert_setting)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts/settings")}
    end
  end

  defp page_title(:show), do: "Show Alert setting"
  defp page_title(:edit), do: "Edit Alert setting"
end
