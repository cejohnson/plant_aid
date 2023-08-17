defmodule PlantAidWeb.UserLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    current_user = socket.assigns.current_user

    with :ok <- Bodyguard.permit(Accounts, :get_user, current_user, id) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:user, Accounts.get_user!(id))}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> push_navigate(to: ~p"/")}
    end
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
