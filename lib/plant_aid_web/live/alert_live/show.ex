defmodule PlantAidWeb.AlertLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    alert = Alerts.get_alert!(id)

    with :ok <- Bodyguard.permit(Alerts, :get_alert, socket.assigns.current_user, alert) do
      {:noreply,
       socket
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

  defp page_title(:show), do: "Show Alert"
  defp page_title(:edit), do: "Edit Alert"
end
