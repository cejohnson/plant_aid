defmodule PlantAidWeb.AlertSettingLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts
  alias PlantAid.Alerts.AlertSetting

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :list_alert_settings, user) do
      {:ok, stream(socket, :alert_settings, Alerts.list_alert_settings(user))}
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

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = socket.assigns.current_user
    alert_setting = Alerts.get_alert_setting!(id)

    with :ok <- Bodyguard.permit(Alerts, :update_alert_setting, user, alert_setting) do
      socket
      |> assign(:page_title, "Edit Alert setting")
      |> assign(:alert_setting, alert_setting)
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts/settings")}
    end
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :create_alert_setting, user) do
      socket
      |> assign(:page_title, "New Alert setting")
      |> assign(:alert_setting, %AlertSetting{})
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts/settings")}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Alert settings")
    |> assign(:alert_setting, nil)
  end

  @impl true
  def handle_info(
        {PlantAidWeb.AlertSettingLive.FormComponent, {:saved, alert_setting}},
        socket
      ) do
    {:noreply, stream_insert(socket, :alert_settings, alert_setting)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    alert_setting = Alerts.get_alert_setting!(id)

    with :ok <- Bodyguard.permit(Alerts, :delete_alert_setting, user, alert_setting) do
      {:ok, _} = Alerts.delete_alert_setting(alert_setting)

      {:noreply, stream_delete(socket, :alert_settings, alert_setting)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end
end
