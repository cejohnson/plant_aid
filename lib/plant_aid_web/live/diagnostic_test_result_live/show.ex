defmodule PlantAidWeb.DiagnosticTestResultLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticTests

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    test_result = DiagnosticTests.get_test_result!(id)

    with :ok <- Bodyguard.permit(DiagnosticTests, :get_test_result, user, test_result) do
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:test_result, test_result)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    user = socket.assigns.current_user

    with :ok <-
           Bodyguard.permit(
             DiagnosticTests,
             :delete_test_result,
             user,
             socket.assigns.test_result
           ) do
      {:ok, _} = DiagnosticTests.delete_test_result(socket.assigns.test_result)

      {:noreply, push_navigate(socket, to: ~p"/test_results")}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Unauthorized")}
    end
  end

  defp page_title(:show), do: "Show Diagnostic test result"
  defp page_title(:edit), do: "Edit Diagnostic test result"
end
