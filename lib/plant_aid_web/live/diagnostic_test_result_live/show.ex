defmodule PlantAidWeb.DiagnosticTestResultLive.Show do
  use PlantAidWeb, :live_view

  alias PlantAid.DiagnosticTests

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:test_result, DiagnosticTests.get_test_result!(id))}
  end

  defp page_title(:show), do: "Show Diagnostic test result"
  defp page_title(:edit), do: "Edit Diagnostic test result"
end
