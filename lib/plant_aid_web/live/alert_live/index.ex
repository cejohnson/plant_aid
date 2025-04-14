defmodule PlantAidWeb.AlertLive.Index do
  use PlantAidWeb, :live_view

  alias PlantAid.Accounts.User
  alias PlantAid.Alerts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Alerts, :list_alerts, user) do
      filter_fields = [
        viewed_at: [
          label: "Viewed Status",
          op: :not_empty,
          type: "select",
          options: [
            {"Any", nil},
            {"Viewed", true},
            {"Unviewed", false}
          ]
        ],
        inserted_on: [
          label: "From",
          op: :>=,
          type: "date"
        ],
        inserted_on: [
          label: "To",
          op: :<=,
          type: "date"
        ]
      ]

      filter_fields =
        if User.has_role?(user, [:superuser, :admin, :researcher]) do
          [
            {:alert_type,
             [
               label: "Alert Type",
               type: "select",
               options: [
                 {"Any", nil},
                 {"Disease Reported", :disease_reported},
                 {"Disease Confirmed", :disease_confirmed}
               ]
             ]}
            | filter_fields
          ]
        else
          filter_fields
        end

      {:ok, assign(socket, :filter_fields, filter_fields)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      case Alerts.list_alerts(socket.assigns.current_user, params) do
        {:ok, {alerts, meta}} ->
          socket
          |> assign(:meta, meta)
          |> stream(:alerts, alerts, reset: true)
          |> apply_action(socket.assigns.live_action, params)

        {:error, _meta} ->
          socket
          |> put_flash(:error, "Something went wrong")
      end

    {:noreply, socket}
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
      unviewed_alert_count = Alerts.get_unviewed_alert_count(user)

      {:noreply,
       socket
       |> assign(:current_user, %{
         socket.assigns.current_user
         | unviewed_alert_count: unviewed_alert_count
       })
       |> assign(:meta, %{socket.assigns.meta | total_count: socket.assigns.meta.total_count - 1})
       |> stream_delete(:alerts, alert)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/alerts?#{params}")}
  end

  @impl true
  def handle_event("reset-filter", params, socket) do
    params = Map.drop(params, ["page", "filters"])
    {:noreply, push_patch(socket, to: ~p"/alerts?#{params}")}
  end
end
