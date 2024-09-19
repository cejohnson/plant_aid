defmodule PlantAidWeb.AlertSubscriptionLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Alerts
  alias PlantAid.Alerts.AlertSubscription

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :list_alert_subscriptions, user) do
      {:ok, stream(socket, :alert_subscriptions, Alerts.list_alert_subscriptions(user))}
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
    alert_subscription = Alerts.get_alert_subscription!(id)

    with :ok <- Bodyguard.permit(Alerts, :update_alert_subscription, user, alert_subscription) do
      socket
      |> assign(:page_title, "Edit Alert Subscription")
      |> assign(:alert_subscription, alert_subscription)
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts/subscriptions")}
    end
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :create_alert_subscription, user) do
      socket
      |> assign(:page_title, "New Alert Subscription")
      |> assign(
        :alert_subscription,
        %AlertSubscription{} |> Alerts.preload_alert_subscription_fields()
      )
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/alerts/subscriptions")}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Alert subscriptions")
    |> assign(:alert_subscription, nil)
  end

  @impl true
  def handle_info(
        {PlantAidWeb.AlertSubscriptionLive.FormComponent, {:saved, alert_subscription}},
        socket
      ) do
    IO.inspect(alert_subscription, label: "saved!")
    {:noreply, stream_insert(socket, :alert_subscriptions, alert_subscription)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    alert_subscription = Alerts.get_alert_subscription!(id)

    with :ok <- Bodyguard.permit(Alerts, :delete_alert_subscription, user, alert_subscription) do
      {:ok, _} = Alerts.delete_alert_subscription(alert_subscription)

      {:noreply, stream_delete(socket, :alert_subscriptions, alert_subscription)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end
end
